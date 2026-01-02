import '../engine_types.dart';
import '../control_params.dart';

class ParamSmoother {
  /// Base time constant in seconds. Actual tau is derived from mode + parameter.
  final double baseTauSeconds;

  const ParamSmoother({required this.baseTauSeconds});

  const ParamSmoother.standard() : baseTauSeconds = 3.2;

  SoundscapeParams step({
    required SoundscapeParams current,
    required SoundscapeParams target,
    required double dtSeconds,
    required SoundscapeMode mode,
    SoundscapePhase phase = SoundscapePhase.steady, // requires enum in engine_types.dart
  }) {
    // Mode multipliers:
    // - Focus reacts quicker (supports “state-following” during work)
    // - Downshift is calmer, slower
    // - Sleep is slowest (avoid attention-grabbing changes)
    final modeMul = switch (mode) {
      SoundscapeMode.focus => 0.85,
      SoundscapeMode.downshift => 1.15,
      SoundscapeMode.sleep => 1.85,
    };

    // Phase multipliers:
    // - Intro ramps in a bit faster so the user hears “it started”
    // - WindDown slows changes to avoid surprise near the end
    final phaseMul = switch (phase) {
      SoundscapePhase.intro => 0.80,
      SoundscapePhase.steady => 1.00,
      SoundscapePhase.windDown => 1.25,
    };

    // Per-parameter multipliers:
    // density/variation: faster (perceptible adaptation)
    // brightness/spatial: medium
    // harmonic/predictability: slower (avoid “wobble”)
    // level: slowest (avoid pumping)
    double tauForParam(double mul) => (baseTauSeconds * modeMul * phaseMul * mul).clamp(0.35, 12.0);

    final aDensity = _alpha(dtSeconds, tauForParam(0.70));
    final aBrightness = _alpha(dtSeconds, tauForParam(0.90));
    final aHarmonic = _alpha(dtSeconds, tauForParam(1.10));
    final aPredict = _alpha(dtSeconds, tauForParam(1.15));
    final aSpatial = _alpha(dtSeconds, tauForParam(0.95));
    final aVar = _alpha(dtSeconds, tauForParam(0.75));
    final aLevel = _alpha(dtSeconds, tauForParam(1.35));

    double lerp(double x, double y, double a) => x + (y - x) * a;

    return SoundscapeParams(
      density: lerp(current.density, target.density, aDensity),
      brightness: lerp(current.brightness, target.brightness, aBrightness),
      harmonicStability: lerp(current.harmonicStability, target.harmonicStability, aHarmonic),
      predictability: lerp(current.predictability, target.predictability, aPredict),
      spatialWidth: lerp(current.spatialWidth, target.spatialWidth, aSpatial),
      variation: lerp(current.variation, target.variation, aVar),
      level: lerp(current.level, target.level, aLevel),
    );
  }

  double _alpha(double dt, double tau) {
    // alpha = 1 - exp(-dt/tau)
    final x = (dt / tau).clamp(0.0, 10.0);
    return 1.0 - _expNeg(x);
  }

  double _expNeg(double x) {
    // Approximation of exp(-x) that is stable and cheap.
    // For correctness you can use exp(-x) from dart:math, but this is fine for smoothing.
    final x2 = x * x;
    return 1.0 / (1.0 + x + 0.5 * x2);
  }
}
