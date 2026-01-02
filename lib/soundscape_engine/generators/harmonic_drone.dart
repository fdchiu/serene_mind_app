// lib/soundscape_engine/generators/harmonic_drone.dart
import 'dart:typed_data';
import '../control_params.dart';
import '../dsp/osc.dart';
import '../dsp/rng.dart';
import 'generator_base.dart';

class HarmonicDrone extends GeneratorNode {
  final SineOsc _a;
  final SineOsc _b;
  final SineOsc _c;
  final Rng _rng = Rng(0x44556677);

  double _baseHz = 110.0;

  HarmonicDrone(super.sampleRate)
      : _a = SineOsc(sampleRate),
        _b = SineOsc(sampleRate),
        _c = SineOsc(sampleRate);

  @override
  void reset() {
    _a.reset();
    _b.reset();
    _c.reset();
    _baseHz = 110.0;
  }

  @override
  void render(Float32List out, int frames, SoundscapeParams p) {
    // harmonicStability: 1 => very stable, 0 => more detune/roughness
    final detuneCents = (2.0 + 18.0 * (1.0 - p.harmonicStability)).clamp(2.0, 24.0);
    final detuneRatio = _centsToRatio(detuneCents);

    // Brightness pushes base slightly upward (subtle)
    final base = (_baseHz * (0.85 + 0.35 * p.brightness)).clamp(70.0, 220.0);

    // Variation: micro drift of base frequency (very subtle)
    final drift = (p.variation * 0.00002);
    _baseHz *= (1.0 + (_rng.nextSigned() * drift));
    _baseHz = _baseHz.clamp(80.0, 140.0);

    final gain = (0.025 + 0.060 * p.harmonicStability).clamp(0.02, 0.10);

    // Stereo width: tiny phase offset effect by pan gain
    final pan = (p.spatialWidth * 0.35);

    for (int i = 0; i < frames; i++) {
      final s1 = _a.next(base);
      final s2 = _b.next(base * 2.0 * detuneRatio);
      final s3 = _c.next(base * 3.0);

      final mono = (s1 * 0.55 + s2 * 0.30 + s3 * 0.15) * gain;

      out[i * 2] += mono * (0.5 - pan * 0.5);
      out[i * 2 + 1] += mono * (0.5 + pan * 0.5);
    }
  }

  double _centsToRatio(double cents) {
    // 2^(cents/1200)
    return _pow2(cents / 1200.0);
  }

  double _pow2(double x) {
    // minimal pow2 approximation; acceptable for small x
    final ln2 = 0.69314718056;
    // exp(x*ln2) approx: 1 + y + y^2/2
    final y = x * ln2;
    return 1.0 + y + 0.5 * y * y;
  }
}
