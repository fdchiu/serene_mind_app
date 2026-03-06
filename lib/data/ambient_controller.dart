import 'dart:async';

import 'ambient_synth.dart';
import 'sound_preset.dart';

class AmbientController {
  final AmbientSynth _engine = AmbientSynth();
  SoundPreset? _current;

  Future<void> _op = Future.value();

  bool get isPlaying => _engine.isRunning;

  Future<void> play(SoundPreset preset) {
    _op = _op.then((_) async {
      // If same preset id and running, prefer apply (no restart).
      if (_engine.isRunning && _current?.id == preset.id) {
        _current = preset;
        await _engine.applyPreset(preset);
        return;
      }

      _current = preset;
      await _engine.startWithPreset(preset);
    });
    return _op;
  }

  /// Explicit apply for live preview; does not force restart.
  Future<void> apply(SoundPreset preset) {
    _op = _op.then((_) async {
      _current = preset;
      if (_engine.isRunning) {
        await _engine.applyPreset(preset);
      } else {
        await _engine.startWithPreset(preset);
      }
    });
    return _op;
  }

  Future<void> stop() {
    _op = _op.then((_) async {
      await _engine.stop();
      _current = null;
    });
    return _op;
  }

  Future<void> toggle(SoundPreset preset) {
    _op = _op.then((_) async {
      if (_current?.id == preset.id && _engine.isRunning) {
        await _engine.stop();
        _current = null;
      } else {
        _current = preset;
        await _engine.startWithPreset(preset);
      }
    });
    return _op;
  }

  void setVolume(double v) => _engine.setVolume(v);
  void setMuted(bool m) => _engine.setMuted(m);
}
