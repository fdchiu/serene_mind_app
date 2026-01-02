// lib/soundscape_engine/dsp/rng.dart
class Rng {
  int _state;
  Rng([int seed = 0x12345678]) : _state = seed;

  int nextU32() {
    // xorshift32
    int x = _state;
    x ^= (x << 13);
    x ^= (x >> 17);
    x ^= (x << 5);
    _state = x;
    return x & 0xFFFFFFFF;
  }

  double nextDouble01() => (nextU32() / 0xFFFFFFFF);

  double nextSigned() => nextDouble01() * 2.0 - 1.0;
}
