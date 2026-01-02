// lib/soundscape_engine/adaptation/param_smoother.dart
import '../engine_types.dart';
import '../control_params.dart';

class ParamSmoother {
  /// Smaller => slower changes.
  final double tauSeconds;

  const ParamSmoother({required this.tauSeconds});

  const ParamSmoother.standard() : tauSeconds = 3.5;

  SoundscapeParams step({
    required SoundscapeParams current,
    required SoundscapeParams target,
    required double dtSeconds,
    required SoundscapeMode mode,
  }) {
    // Sleep should change even more slowly.
    final tau = (mode == SoundscapeMode.sleep) ? (tauSeconds * 1.6) : tauSeconds;
    final a = 1.0 - _expNeg(dtSeconds / tau);

    double lerp(double x, double y) => x + (y - x) * a;

    return SoundscapeParams(
      density: lerp(current.density, target.density),
      brightness: lerp(current.brightness, target.brightness),
      harmonicStability: lerp(current.harmonicStability, target.harmonicStability),
      predictability: lerp(current.predictability, target.predictability),
      spatialWidth: lerp(current.spatialWidth, target.spatialWidth),
      variation: lerp(current.variation, target.variation),
      level: lerp(current.level, target.level),
    );
  }

  double _expNeg(double x) {
    // Simple approximation is fine here; avoids dart:math exp in hot path if you want.
    // For correctness you can import dart:math and use exp(-x).
    // This approximation is stable for small x.
    final x2 = x * x;
    return 1.0 / (1.0 + x + 0.5 * x2);
  }
}
