// lib/soundscape_engine/graph/mixer.dart
import 'dart:typed_data';
import '../dsp/limiter.dart';

class MixerBus {
  final SoftLimiter _limiter = SoftLimiter();
  double master = 0.85;

  void clear(Float32List out) {
    for (int i = 0; i < out.length; i++) {
      out[i] = 0.0;
    }
  }

  void applyMasterAndLimit(Float32List out) {
    for (int i = 0; i < out.length; i++) {
      out[i] = _limiter.process(out[i] * master);
    }
  }
}
