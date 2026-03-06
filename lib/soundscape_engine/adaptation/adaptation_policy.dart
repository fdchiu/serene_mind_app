// lib/soundscape_engine/adaptation/adaptation_policy.dart
import '../engine_types.dart';
import '../state_inputs.dart';
import '../control_params.dart';

abstract class AdaptationPolicy {
  SoundscapeParams computeTargetParams({
    required SoundscapeMode mode,
    required SoundscapeInputs prevInputs,
    required SoundscapeInputs inputs,
    required SoundscapeParams prevTarget,
    required int sampleRate,
  });
}

/// Opinionated default:
/// - Focus: stabilize + reduce surprise, moderate brightness
/// - Downshift: gradually reduce density/brightness as arousal drops
/// - Sleep: lower brightness/density, higher predictability, minimal width
class DefaultAdaptationPolicy implements AdaptationPolicy {
  const DefaultAdaptationPolicy();

  @override
  SoundscapeParams computeTargetParams({
    required SoundscapeMode mode,
    required SoundscapeInputs prevInputs,
    required SoundscapeInputs inputs,
    required SoundscapeParams prevTarget,
    required int sampleRate,
  }) {
    final x = inputs.clamp01();

    // Base “intent priors”
    SoundscapeParams base;
    switch (mode) {
      case SoundscapeMode.focus:
        base = const SoundscapeParams(
          density: 0.35,
          brightness: 0.45,
          harmonicStability: 0.70,
          predictability: 0.85,
          spatialWidth: 0.25,
          variation: 0.25,
          level: 0.65,
        );
        break;
      case SoundscapeMode.downshift:
        base = const SoundscapeParams(
          density: 0.30,
          brightness: 0.30,
          harmonicStability: 0.75,
          predictability: 0.80,
          spatialWidth: 0.30,
          variation: 0.30,
          level: 0.70,
        );
        break;
      case SoundscapeMode.sleep:
        base = const SoundscapeParams(
          density: 0.18,
          brightness: 0.18,
          harmonicStability: 0.85,
          predictability: 0.92,
          spatialWidth: 0.12,
          variation: 0.15,
          level: 0.55,
        );
        break;
    }

    // Context modulation (coarse + conservative)
    // Higher arousal => reduce brightness/density (for downshift/sleep).
    // Higher cognitive load => for focus: slightly increase stability and reduce variation.
    double ar = x.arousal;
    double load = x.cognitiveLoad;
    double fat = x.fatigue;
    double rec = x.recoveryIndex;

    // Hysteresis: don’t flip aggressively on small changes.
    // If arousal trend increasing, cap density/brightness further for downshift/sleep.
    final trendPenalty = (x.arousalTrend == ArousalTrend.increasing) ? 0.10 : 0.0;

    SoundscapeParams mod = base;

    if (mode == SoundscapeMode.focus) {
      // Keep density stable; reduce variation when load is high.
      mod = mod.copyWith(
        density: (base.density + 0.08 * (1.0 - ar) - 0.05 * fat).clamp(0.18, 0.55),
        brightness: (base.brightness + 0.10 * (1.0 - fat) - 0.10 * ar).clamp(0.20, 0.60),
        harmonicStability: (base.harmonicStability + 0.10 * load).clamp(0.55, 0.90),
        predictability: (base.predictability + 0.08 * load).clamp(0.70, 0.98),
        variation: (base.variation - 0.12 * load + 0.08 * (1.0 - ar)).clamp(0.08, 0.45),
        spatialWidth: (base.spatialWidth + 0.10 * (1.0 - load)).clamp(0.10, 0.45),
      );
    } else if (mode == SoundscapeMode.downshift) {
      mod = mod.copyWith(
        density: (base.density - 0.16 * ar - trendPenalty + 0.06 * rec).clamp(0.08, 0.40),
        brightness: (base.brightness - 0.18 * ar - trendPenalty).clamp(0.06, 0.45),
        harmonicStability: (base.harmonicStability + 0.10 * (1.0 - ar)).clamp(0.55, 0.95),
        predictability: (base.predictability + 0.06 * (1.0 - ar)).clamp(0.65, 0.98),
        variation: (base.variation - 0.10 * ar + 0.06 * rec).clamp(0.08, 0.55),
        spatialWidth: (base.spatialWidth + 0.08 * (1.0 - ar)).clamp(0.10, 0.55),
      );
    } else {
      // sleep
      // More fatigue => lower density/brightness, higher stability/predictability.
      mod = mod.copyWith(
        density: (base.density - 0.14 * fat - 0.08 * ar).clamp(0.04, 0.30),
        brightness: (base.brightness - 0.14 * fat - 0.10 * ar).clamp(0.03, 0.28),
        harmonicStability: (base.harmonicStability + 0.08 * fat).clamp(0.65, 0.98),
        predictability: (base.predictability + 0.05 * fat).clamp(0.80, 0.99),
        variation: (base.variation - 0.08 * fat).clamp(0.03, 0.35),
        spatialWidth: (base.spatialWidth - 0.06 * fat).clamp(0.03, 0.20),
      );
    }

    // Safety: never jump target too far from previous target in one update.
    // This prevents “thrash” if upstream inputs glitch.
    SoundscapeParams limited = _limitDelta(prevTarget, mod, maxStep: 0.08);
    return limited.clamp01();
  }

  SoundscapeParams _limitDelta(SoundscapeParams prev, SoundscapeParams next, {required double maxStep}) {
    double step(double a, double b) {
      final d = b - a;
      if (d.abs() <= maxStep) return b;
      return a + maxStep * (d.sign);
    }

    return SoundscapeParams(
      density: step(prev.density, next.density),
      brightness: step(prev.brightness, next.brightness),
      harmonicStability: step(prev.harmonicStability, next.harmonicStability),
      predictability: step(prev.predictability, next.predictability),
      spatialWidth: step(prev.spatialWidth, next.spatialWidth),
      variation: step(prev.variation, next.variation),
      level: step(prev.level, next.level),
    );
  }
}
