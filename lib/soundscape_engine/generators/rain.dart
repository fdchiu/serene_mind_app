// lib/soundscape_engine/generators/rain.dart
import 'dart:typed_data';
import '../control_params.dart';
import '../dsp/rng.dart';
import '../dsp/envelope.dart';
import '../dsp/noise.dart';
import '../dsp/one_pole.dart';
import 'generator_base.dart';

class Rain extends GeneratorNode {
  final Rng _rng = Rng(0xDEAD10CC);
  final WhiteNoise _noise = WhiteNoise(0x10203040);
  final OnePole _hpish = OnePole();

  // A small pool of droplet envelopes.
  final List<AdEnvelope> _drops = [];
  final List<double> _dropPan = [];

  Rain(super.sampleRate) {
    for (int i = 0; i < 12; i++) {
      _drops.add(AdEnvelope(sampleRate));
      _dropPan.add(0.0);
    }
  }

  @override
  void reset() {
    // envelopes self-reset by state; nothing necessary
  }

  @override
  void render(Float32List out, int frames, SoundscapeParams p) {
    // Event probability per frame.
    // density increases droplet rate, but stay gentle.
    final eventsPerSecond = (0.4 + 3.5 * p.density).clamp(0.2, 5.0);
    final pEvent = eventsPerSecond / sampleRate;

    // Droplets brighter when brightness increases.
    final tone = (0.980 - 0.020 * p.brightness).clamp(0.950, 0.995);

    final gain = (0.010 + 0.040 * p.density).clamp(0.008, 0.07);

    for (int i = 0; i < frames; i++) {
      // Trigger new drop sometimes.
      if (_rng.nextDouble01() < pEvent) {
        for (int k = 0; k < _drops.length; k++) {
          if (!_drops[k].isActive) {
            final a = (0.002 + 0.010 * (1.0 - p.predictability)).clamp(0.002, 0.02);
            final d = (0.06 + 0.22 * (1.0 - p.harmonicStability)).clamp(0.06, 0.50);
            _drops[k].trigger(attackSeconds: a, decaySeconds: d);
            _dropPan[k] = (_rng.nextSigned() * (0.25 + 0.55 * p.spatialWidth)).clamp(-0.9, 0.9);
            break;
          }
        }
      }

      // Render active drops as filtered noise bursts.
      double l = 0.0, r = 0.0;
      for (int k = 0; k < _drops.length; k++) {
        final e = _drops[k].next();
        if (e <= 0.0) continue;

        // “HP-ish”: subtract smoothed version to get a transient pop.
        final n = _noise.next();
        final s = _hpish.process(n, tone);
        final hp = (n - s);
        final y = hp * e * gain;

        final pan = _dropPan[k];
        l += y * (0.5 - 0.5 * pan);
        r += y * (0.5 + 0.5 * pan);
      }

      out[i * 2] += l;
      out[i * 2 + 1] += r;
    }
  }
}
