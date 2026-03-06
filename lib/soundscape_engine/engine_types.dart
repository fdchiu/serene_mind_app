// lib/soundscape_engine/engine_types.dart
enum SoundscapeMode { focus, downshift, sleep }

/// Session phase for shaping params over time.
/// - intro: gentler density/brightness/variation, slightly lower level
/// - steady: baseline
/// - windDown: lower density/brightness/variation, slightly lower level
enum SoundscapePhase { intro, steady, windDown }

enum ArousalTrend { decreasing, stable, increasing }

enum FatigueTrend { recovering, stable, worsening }
