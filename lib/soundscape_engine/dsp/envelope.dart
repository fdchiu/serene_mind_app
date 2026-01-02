// lib/soundscape_engine/dsp/envelope.dart
class AdEnvelope {
  final int sampleRate;
  double _value = 0.0;
  double _attack = 0.01;
  double _decay = 0.25;
  int _state = 0; // 0 idle, 1 attack, 2 decay

  AdEnvelope(this.sampleRate);

  void trigger({double attackSeconds = 0.005, double decaySeconds = 0.35}) {
    _attack = attackSeconds.clamp(0.001, 2.0);
    _decay = decaySeconds.clamp(0.01, 5.0);
    _state = 1;
  }

  double next() {
    if (_state == 0) return 0.0;

    if (_state == 1) {
      final step = 1.0 / (_attack * sampleRate);
      _value += step;
      if (_value >= 1.0) {
        _value = 1.0;
        _state = 2;
      }
      return _value;
    } else {
      final step = 1.0 / (_decay * sampleRate);
      _value -= step;
      if (_value <= 0.0) {
        _value = 0.0;
        _state = 0;
      }
      return _value;
    }
  }

  bool get isActive => _state != 0;
}
