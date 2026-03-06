// lib/soundscape_engine/dsp/osc.dart
import 'dart:math' as math;

class SineOsc {
  final int sampleRate;
  double _phase = 0.0;

  SineOsc(this.sampleRate);

  double next(double freqHz) {
    final inc = (2.0 * math.pi * freqHz) / sampleRate;
    _phase += inc;
    if (_phase > 2.0 * math.pi) _phase -= 2.0 * math.pi;
    return math.sin(_phase);
  }

  void reset() => _phase = 0.0;
}
