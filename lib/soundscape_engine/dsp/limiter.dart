// lib/soundscape_engine/dsp/limiter.dart
class SoftLimiter {
  double drive;

  SoftLimiter({this.drive = 1.2});

  double process(double x) {
    // Soft clipper (tanh-ish rational approx)
    final y = x * drive;
    return y / (1.0 + y.abs());
  }
}
