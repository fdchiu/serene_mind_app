// lib/soundscape_engine/state_inputs.dart
import 'engine_types.dart';

/// Privacy-first, trend-based inputs.
/// Nothing here requires raw sensors.
class SoundscapeInputs {
  /// 0..1 (coarse, smoothed)
  final double arousal;

  /// 0..1 (smoothed; “tiredness / sleep pressure”)
  final double fatigue;

  /// Arousal direction (smoothed classification)
  final ArousalTrend arousalTrend;

  /// Fatigue direction (smoothed classification)
  final FatigueTrend fatigueTrend;

  /// 0..1 “context load” (calendar density, notifications, etc.)
  final double cognitiveLoad;

  /// Optional: HRV trend proxy 0..1 (higher means “better recovery”)
  final double recoveryIndex;

  const SoundscapeInputs({
    required this.arousal,
    required this.fatigue,
    required this.arousalTrend,
    required this.fatigueTrend,
    required this.cognitiveLoad,
    required this.recoveryIndex,
  });

  factory SoundscapeInputs.zero() => const SoundscapeInputs(
        arousal: 0,
        fatigue: 0,
        arousalTrend: ArousalTrend.stable,
        fatigueTrend: FatigueTrend.stable,
        cognitiveLoad: 0,
        recoveryIndex: 0,
      );

  SoundscapeInputs clamp01() => SoundscapeInputs(
        arousal: arousal.clamp(0.0, 1.0),
        fatigue: fatigue.clamp(0.0, 1.0),
        arousalTrend: arousalTrend,
        fatigueTrend: fatigueTrend,
        cognitiveLoad: cognitiveLoad.clamp(0.0, 1.0),
        recoveryIndex: recoveryIndex.clamp(0.0, 1.0),
      );
}
