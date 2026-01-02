// lib/soundscape_engine/dsp/noise.dart
import 'rng.dart';

class WhiteNoise {
  final Rng _rng;
  WhiteNoise([int seed = 0x0A53C9E1]) : _rng = Rng(seed);

  double next() => _rng.nextSigned();
}

/// Very lightweight pink-ish noise via filtered white noise.
/// Not “true” pink, but perceptually useful for rain/wind beds.
class PinkishNoise {
  final WhiteNoise _w;
  double b0 = 0, b1 = 0, b2 = 0;
  PinkishNoise([int seed = 0xBEEF1234]) : _w = WhiteNoise(seed);

  double next() {
    final x = _w.next();
    b0 = 0.99765 * b0 + x * 0.0990460;
    b1 = 0.96300 * b1 + x * 0.2965164;
    b2 = 0.57000 * b2 + x * 1.0526913;
    return (b0 + b1 + b2 + x * 0.1848) * 0.05;
  }
}
