import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/daily_quotes.dart';
import '../models/daily_quote.dart';
import '../models/meditation_session.dart';
import '../models/user_stats.dart';
import '../services/meditation_repository.dart';

class MeditationController extends ChangeNotifier {
  MeditationController();

  final _uuid = const Uuid();
  MeditationRepository? _repository;

  List<MeditationSession> _sessions = [];
  UserStats _stats = UserStats.initial();
  DailyQuote _quote = dailyQuotes.first;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<MeditationSession> get sessions => List.unmodifiable(_sessions);
  UserStats get stats => _stats;
  DailyQuote get quote => _quote;

  Future<void> initialize() async {
    _repository ??= await MeditationRepository.create();
    _sessions = _repository!.loadSessions();
    _stats = _repository!.loadStats();
    _quote = _loadQuote();
    _recalculateStats(persist: false);
    _isLoading = false;
    notifyListeners();
  }

  DailyQuote _loadQuote() {
    final todayKey = _todayKey();
    final stored = _repository?.loadQuote(key: todayKey);
    if (stored != null) return stored;

    final index = DateTime.now().day % dailyQuotes.length;
    final quote = dailyQuotes[index];
    unawaited(_repository?.saveQuote(key: todayKey, quote: quote));
    return quote;
  }

  MeditationSession buildSession({
    required int duration,
    required int moodBefore,
    required int moodAfter,
    String? notes,
    SessionType type = SessionType.timer,
  }) {
    return MeditationSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      duration: duration,
      type: type,
      moodBefore: moodBefore,
      moodAfter: moodAfter,
      notes: notes,
    );
  }

  Future<void> saveSession(MeditationSession session) async {
    _sessions = [..._sessions, session];
    await _persistSessions();
    _recalculateStats();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    _sessions = _sessions.where((session) => session.id != id).toList();
    await _persistSessions();
    _recalculateStats();
    notifyListeners();
  }

  List<MeditationSession> sessionsForDay(DateTime date) {
    return _sessions
        .where((session) => _isSameDay(session.date, date))
        .toList();
  }

  List<MeditationSession> getTodaySessions() {
    return sessionsForDay(DateTime.now());
  }

  List<MeditationSession> recentSessions([int limit = 10]) {
    final sorted = [..._sessions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  Future<void> _persistSessions() async {
    await _repository?.saveSessions(_sessions);
  }

  void _recalculateStats({bool persist = true}) {
    final completed = _sessions.where((session) => session.completed).toList();
    if (completed.isEmpty) {
      _stats = UserStats.initial().copyWith(
        longestStreak: _stats.longestStreak,
        weeklyGoal: _stats.weeklyGoal,
      );
      if (persist) {
        unawaited(_repository?.saveStats(_stats));
      }
      return;
    }

    final totalMinutes =
        (completed.fold<int>(0, (sum, s) => sum + s.duration) / 60).round();
    final uniqueDates = completed
        .map((session) => DateTime(
              session.date.year,
              session.date.month,
              session.date.day,
            ))
        .toSet()
        .toList()
      ..sort();

    final currentStreak = _calculateCurrentStreak(uniqueDates);
    final longestStreak = _calculateLongestStreak(uniqueDates);

    final moodImprovements = completed
        .map((session) => session.moodDelta.toDouble())
        .where((delta) => delta != 0)
        .toList();
    final averageMoodImprovement = moodImprovements.isEmpty
        ? 0.0
        : double.parse(
            (moodImprovements.reduce((a, b) => a + b) / moodImprovements.length)
                .toStringAsFixed(1),
          );

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final weeklyProgress =
        completed.where((session) => session.date.isAfter(sevenDaysAgo)).length;

    _stats = _stats.copyWith(
      totalSessions: completed.length,
      totalMinutes: totalMinutes,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      averageMoodImprovement: averageMoodImprovement,
      weeklyProgress: weeklyProgress,
    );

    if (persist) {
      unawaited(_repository?.saveStats(_stats));
    }
  }

  int _calculateCurrentStreak(List<DateTime> dates) {
    final dateSet = dates.toSet();
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    while (dateSet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    var longest = 1;
    var streak = 1;

    for (var i = 1; i < dates.length; i++) {
      final previous = dates[i - 1];
      final current = dates[i];
      final difference = current.difference(previous).inDays;

      if (difference == 0) continue;

      if (difference == 1) {
        streak++;
      } else {
        streak = 1;
      }

      if (streak > longest) {
        longest = streak;
      }
    }

    return longest;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
