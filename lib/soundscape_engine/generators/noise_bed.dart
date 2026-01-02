// lib/soundscape_engine/generators/noise_bed.dart
import 'dart:typed_data';
import '../control_params.dart';
import '../dsp/noise.dart';
import '../dsp/one_pole.dart';
import 'generator_base.dart';

class NoiseBed extends GeneratorNode {
  final PinkishNoise _noise = PinkishNoise(0x11112222);
  final OnePole _tone = OnePole();

  NoiseBed(super.sampleRate);

  @override
  void reset() {
    _tone.z = 0.0;
  }

  @override
  void render(Float32List out, int frames, SoundscapeParams p) {
    // brightness controls “air” by reducing smoothing
    // more brightness => less smoothing => more hiss detail
    final smooth = (0.997 - 0.010 * p.brightness).clamp(0.960, 0.998);

    // bed gain shaped by density (but conservative)
    final gain = (0.06 + 0.10 * (1.0 - p.density)).clamp(0.03, 0.16);

    for (int i = 0; i < frames; i++) {
      final n = _noise.next();
      final y = _tone.process(n, smooth) * gain;
      out[i * 2] += y;
      out[i * 2 + 1] += y;
    }
  }
}
