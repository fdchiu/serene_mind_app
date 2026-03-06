import 'dart:convert';

enum SessionType { guided, timer, breathing, soundscape }

SessionType sessionTypeFromString(String value) {
  return SessionType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => SessionType.timer,
  );
}

class MeditationSession {
  MeditationSession({
    required this.id,
    required this.date,
    required this.duration,
    required this.type,
    required this.moodBefore,
    required this.moodAfter,
    this.notes,
    this.completed = true,
  });

  final String id;
  final DateTime date;
  final int duration; // seconds
  final SessionType type;
  final int moodBefore;
  final int moodAfter;
  final String? notes;
  final bool completed;

  int get moodDelta => moodAfter - moodBefore;

  MeditationSession copyWith({
    String? id,
    DateTime? date,
    int? duration,
    SessionType? type,
    int? moodBefore,
    int? moodAfter,
    String? notes,
    bool? completed,
  }) {
    return MeditationSession(
      id: id ?? this.id,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration': duration,
      'type': type.name,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
      'notes': notes,
      'completed': completed,
    };
  }

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      duration: (json['duration'] as num).toInt(),
      type: sessionTypeFromString(json['type'] as String),
      moodBefore: (json['moodBefore'] as num).toInt(),
      moodAfter: (json['moodAfter'] as num).toInt(),
      notes: json['notes'] as String?,
      completed: json['completed'] as bool? ?? true,
    );
  }

  static List<MeditationSession> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) =>
            MeditationSession.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<MeditationSession> sessions) {
    return jsonEncode(sessions.map((session) => session.toJson()).toList());
  }
}
