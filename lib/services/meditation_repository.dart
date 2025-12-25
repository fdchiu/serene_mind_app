import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_quote.dart';
import '../models/meditation_session.dart';
import '../models/user_stats.dart';

class MeditationRepository {
  MeditationRepository._(this._prefs);

  static const _sessionsKey = 'mindful_sessions';
  static const _statsKey = 'mindful_stats';
  static const _quoteKey = 'daily_quote';

  final SharedPreferences _prefs;

  static Future<MeditationRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MeditationRepository._(prefs);
  }

  List<MeditationSession> loadSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null) return [];
    try {
      return MeditationSession.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<MeditationSession> sessions) async {
    await _prefs.setString(
        _sessionsKey, MeditationSession.encodeList(sessions));
  }

  UserStats loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) {
      return UserStats.initial();
    }

    try {
      return UserStats.decode(raw);
    } catch (_) {
      return UserStats.initial();
    }
  }

  Future<void> saveStats(UserStats stats) async {
    await _prefs.setString(_statsKey, UserStats.encode(stats));
  }

  DailyQuote? loadQuote({required String key}) {
    final raw = _prefs.getString(_quoteKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['date'] == key) {
        return DailyQuote.fromJson(decoded['quote'] as Map<String, dynamic>);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> saveQuote({
    required String key,
    required DailyQuote quote,
  }) async {
    await _prefs.setString(
      _quoteKey,
      jsonEncode({'date': key, 'quote': quote.toJson()}),
    );
  }
}
