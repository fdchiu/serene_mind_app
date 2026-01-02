// lib/soundscape_engine/dsp/one_pole.dart
class OnePole {
  double z = 0.0;

  double process(double x, double a) {
    // a in (0..1): closer to 1 => slower
    z = a * z + (1.0 - a) * x;
    return z;
  }
}
