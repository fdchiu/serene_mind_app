// lib/soundscape_engine/dsp/stereo.dart
class Stereo {
  static void panAdd({
    required double sample,
    required double pan, // -1..1
    required List<double> accumLR,
    required int idx, // frame index
  }) {
    final p = pan.clamp(-1.0, 1.0);
    final l = (1.0 - p) * 0.5;
    final r = (1.0 + p) * 0.5;
    accumLR[idx * 2] += sample * l;
    accumLR[idx * 2 + 1] += sample * r;
  }
}
