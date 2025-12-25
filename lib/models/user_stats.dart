import 'dart:convert';

class UserStats {
  const UserStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageMoodImprovement,
    required this.favoriteTime,
    required this.weeklyGoal,
    required this.weeklyProgress,
  });

  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final double averageMoodImprovement;
  final String favoriteTime;
  final int weeklyGoal;
  final int weeklyProgress;

  factory UserStats.initial() {
    return const UserStats(
      totalSessions: 0,
      totalMinutes: 0,
      currentStreak: 0,
      longestStreak: 0,
      averageMoodImprovement: 0,
      favoriteTime: 'morning',
      weeklyGoal: 7,
      weeklyProgress: 0,
    );
  }

  UserStats copyWith({
    int? totalSessions,
    int? totalMinutes,
    int? currentStreak,
    int? longestStreak,
    double? averageMoodImprovement,
    String? favoriteTime,
    int? weeklyGoal,
    int? weeklyProgress,
  }) {
    return UserStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      averageMoodImprovement:
          averageMoodImprovement ?? this.averageMoodImprovement,
      favoriteTime: favoriteTime ?? this.favoriteTime,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'averageMoodImprovement': averageMoodImprovement,
      'favoriteTime': favoriteTime,
      'weeklyGoal': weeklyGoal,
      'weeklyProgress': weeklyProgress,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      averageMoodImprovement:
          (json['averageMoodImprovement'] as num?)?.toDouble() ?? 0,
      favoriteTime: json['favoriteTime'] as String? ?? 'morning',
      weeklyGoal: (json['weeklyGoal'] as num?)?.toInt() ?? 7,
      weeklyProgress: (json['weeklyProgress'] as num?)?.toInt() ?? 0,
    );
  }

  static String encode(UserStats stats) => jsonEncode(stats.toJson());

  static UserStats decode(String raw) =>
      UserStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
