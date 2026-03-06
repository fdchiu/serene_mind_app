// lib/soundscape_engine/control_params.dart
/// “Mechanism-level” parameters.
/// Generators read these continuously.
class SoundscapeParams {
  /// 0..1: perceived event density / “tempo-like” activity
  final double density;

  /// 0..1: brightness / spectral centroid proxy
  final double brightness;

  /// 0..1: tonal stability (1 = stable harmonic, 0 = noisier/rougher)
  final double harmonicStability;

  /// 0..1: rhythmic predictability (1 = very predictable)
  final double predictability;

  /// 0..1: stereo width / subtle motion
  final double spatialWidth;

  /// 0..1: micro-variation (how quickly textures evolve)
  final double variation;

  /// 0..1 master level (before limiter)
  final double level;

  const SoundscapeParams({
    required this.density,
    required this.brightness,
    required this.harmonicStability,
    required this.predictability,
    required this.spatialWidth,
    required this.variation,
    required this.level,
  });

  factory SoundscapeParams.defaults() => const SoundscapeParams(
        density: 0.35,
        brightness: 0.35,
        harmonicStability: 0.65,
        predictability: 0.75,
        spatialWidth: 0.35,
        variation: 0.35,
        level: 0.65,
      );

  SoundscapeParams clamp01() => SoundscapeParams(
        density: density.clamp(0.0, 1.0),
        brightness: brightness.clamp(0.0, 1.0),
        harmonicStability: harmonicStability.clamp(0.0, 1.0),
        predictability: predictability.clamp(0.0, 1.0),
        spatialWidth: spatialWidth.clamp(0.0, 1.0),
        variation: variation.clamp(0.0, 1.0),
        level: level.clamp(0.0, 1.0),
      );

  SoundscapeParams copyWith({
    double? density,
    double? brightness,
    double? harmonicStability,
    double? predictability,
    double? spatialWidth,
    double? variation,
    double? level,
  }) =>
      SoundscapeParams(
        density: density ?? this.density,
        brightness: brightness ?? this.brightness,
        harmonicStability: harmonicStability ?? this.harmonicStability,
        predictability: predictability ?? this.predictability,
        spatialWidth: spatialWidth ?? this.spatialWidth,
        variation: variation ?? this.variation,
        level: level ?? this.level,
      );
}
