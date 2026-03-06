// lib/soundscape_engine/generators/bell_events.dart
import 'dart:typed_data';
import '../control_params.dart';
import '../dsp/envelope.dart';
import '../dsp/osc.dart';
import '../dsp/rng.dart';
import 'generator_base.dart';

class BellEvents extends GeneratorNode {
  final Rng _rng = Rng(0x90ABCDEF);

  final List<AdEnvelope> _env = [];
  final List<SineOsc> _osc = [];
  final List<double> _freq = [];
  final List<double> _pan = [];

  BellEvents(super.sampleRate) {
    for (int i = 0; i < 6; i++) {
      _env.add(AdEnvelope(sampleRate));
      _osc.add(SineOsc(sampleRate));
      _freq.add(440.0);
      _pan.add(0.0);
    }
  }

  @override
  void reset() {}

  @override
  void render(Float32List out, int frames, SoundscapeParams p) {
    // Event rate controlled by density, but also predictability.
    // More predictability => fewer surprises (fewer bells).
    final ratePerMin = (0.2 + 2.2 * p.density * (1.0 - p.predictability)).clamp(0.05, 2.0);
    final pEvent = (ratePerMin / 60.0) / sampleRate;

    final gain = (0.010 + 0.035 * p.harmonicStability).clamp(0.008, 0.06);

    for (int i = 0; i < frames; i++) {
      if (_rng.nextDouble01() < pEvent) {
        for (int k = 0; k < _env.length; k++) {
          if (!_env[k].isActive) {
            // Choose from a soft pentatonic set.
            final base = 220.0;
            final choices = [1.0, 1.125, 1.25, 1.5, 1.667];
            final ratio = choices[_rng.nextU32() % choices.length];
            _freq[k] = base * ratio * (0.85 + 0.35 * p.brightness);

            _pan[k] = (_rng.nextSigned() * (0.20 + 0.60 * p.spatialWidth)).clamp(-0.9, 0.9);

            final a = 0.003;
            final d = (0.25 + 0.75 * (1.0 - p.variation)).clamp(0.20, 1.50);
            _env[k].trigger(attackSeconds: a, decaySeconds: d);
            break;
          }
        }
      }

      double l = 0, r = 0;
      for (int k = 0; k < _env.length; k++) {
        final e = _env[k].next();
        if (e <= 0) continue;

        // Simple bell-ish: fundamental + faint partial
        final f = _freq[k];
        final s = _osc[k].next(f) * 0.8 + _osc[k].next(f * 2.7) * 0.2;
        final y = s * e * gain;

        final pan = _pan[k];
        l += y * (0.5 - 0.5 * pan);
        r += y * (0.5 + 0.5 * pan);
      }

      out[i * 2] += l;
      out[i * 2 + 1] += r;
    }
  }
}
