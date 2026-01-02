// lib/soundscape_engine/generators/granular_shimmer.dart
import 'dart:typed_data';
import '../control_params.dart';
import '../dsp/rng.dart';
import '../dsp/envelope.dart';
import '../dsp/noise.dart';
import 'generator_base.dart';

class GranularShimmer extends GeneratorNode {
  final Rng _rng = Rng(0x13579BDF);
  final WhiteNoise _w = WhiteNoise(0x2468ACE0);

  final List<AdEnvelope> _grains = [];
  final List<double> _pan = [];

  GranularShimmer(super.sampleRate) {
    for (int i = 0; i < 10; i++) {
      _grains.add(AdEnvelope(sampleRate));
      _pan.add(0);
    }
  }

  @override
  void reset() {}

  @override
  void render(Float32List out, int frames, SoundscapeParams p) {
    // Shimmer should be near-zero for sleep; more for focus/downshift.
    final baseGain = (0.002 + 0.012 * p.brightness).clamp(0.0, 0.02);
    final spawnRate = (0.4 + 10.0 * p.variation * p.brightness).clamp(0.1, 10.0);
    final pEvent = spawnRate / sampleRate;

    for (int i = 0; i < frames; i++) {
      if (_rng.nextDouble01() < pEvent) {
        for (int k = 0; k < _grains.length; k++) {
          if (!_grains[k].isActive) {
            final a = 0.0015;
            final d = (0.03 + 0.10 * (1.0 - p.predictability)).clamp(0.02, 0.20);
            _grains[k].trigger(attackSeconds: a, decaySeconds: d);
            _pan[k] = (_rng.nextSigned() * (0.15 + 0.65 * p.spatialWidth)).clamp(-1.0, 1.0);
            break;
          }
        }
      }

      double l = 0, r = 0;
      for (int k = 0; k < _grains.length; k++) {
        final e = _grains[k].next();
        if (e <= 0) continue;

        // High-ish “sparkle”: just scale noise; brightness drives it.
        final y = _w.next() * e * baseGain;
        final pan = _pan[k];
        l += y * (0.5 - 0.5 * pan);
        r += y * (0.5 + 0.5 * pan);
      }

      out[i * 2] += l;
      out[i * 2 + 1] += r;
    }
  }
}
