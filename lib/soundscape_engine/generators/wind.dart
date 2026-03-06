// lib/soundscape_engine/generators/wind.dart
import 'dart:typed_data';
import '../control_params.dart';
import '../dsp/noise.dart';
import '../dsp/one_pole.dart';
import '../dsp/rng.dart';
import 'generator_base.dart';

class Wind extends GeneratorNode {
  final WhiteNoise _w = WhiteNoise(0xCAFEBABE);
  final OnePole _lp = OnePole();
  final OnePole _gust = OnePole();
  final Rng _rng = Rng(0xABCDEF01);

  double _pan = 0.0;

  Wind(super.sampleRate);

  @override
  void reset() {
    _lp.z = 0;
    _gust.z = 0;
    _pan = 0;
  }

  @override
  void render(Float32List out, int frames, SoundscapeParams p) {
    // gust evolves slowly; higher variation => slightly more movement
    final gustSmooth = (0.9992 - 0.0006 * p.variation).clamp(0.9978, 0.9995);
    final toneSmooth = (0.995 - 0.010 * p.brightness).clamp(0.970, 0.997);

    // wind level inverse to brightness (sleep winds should be darker)
    final baseGain = (0.02 + 0.06 * (1.0 - p.brightness)).clamp(0.01, 0.10);

    // Pan drift controlled by spatial width.
    final panDrift = 0.00015 * p.spatialWidth;
    _pan += (_rng.nextSigned() * panDrift);
    _pan = _pan.clamp(-0.7, 0.7);

    for (int i = 0; i < frames; i++) {
      final raw = _w.next();
      final gust = _gust.process((_rng.nextSigned() * 0.5 + 0.5), gustSmooth);
      final y = _lp.process(raw, toneSmooth) * baseGain * (0.35 + 0.65 * gust);

      final l = y * (0.5 - 0.5 * _pan);
      final r = y * (0.5 + 0.5 * _pan);
      out[i * 2] += l;
      out[i * 2 + 1] += r;
    }
  }
}
