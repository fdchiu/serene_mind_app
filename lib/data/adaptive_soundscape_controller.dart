import 'dart:async';
import 'dart:typed_data';

import '../soundscape_engine/soundscape_engine.dart';
import '../soundscape_engine/engine_types.dart';
import '../soundscape_engine/state_inputs.dart';
import 'ambient_synth.dart';

class AdaptiveSoundscapeController {
  final AmbientSynth _audio = AmbientSynth(channels: 2); // stereo for adaptive
  final SoundscapeEngine _engine = SoundscapeEngine();

  bool _muted = false;
  double _volume = 0.5;

  Timer? _inputsTimer;
  SoundscapeMode _mode = SoundscapeMode.focus;
  SoundscapeInputs _inputs = SoundscapeInputs.zero();

  // Prevent overlapping start/stop when user taps quickly.
  bool _busy = false;

  bool get isPlaying => _audio.isRunning;
  SoundscapeMode get mode => _mode;

  Future<void> start(SoundscapeMode mode) async {
    if (_busy) return;
    _busy = true;

    // If already running, restarting is cheap but do it cleanly.
    // This guarantees mode switches work even during rapid taps.
    try {
      await stop(); // safe even if already stopped

      _mode = mode;
      _engine.setMode(mode);

      await _audio.startWithRenderer(
        channels: 2,
        render: (Float32List interleavedStereo) {
          // Engine fills interleaved stereo float32 [-1..1].
          _engine.renderInterleavedFloat32(interleavedStereo);
        },
      );

      // Apply current UI state to audio sink.
      _audio.setMuted(_muted);
      _audio.setVolume(_volume);

      _inputsTimer?.cancel();
      _inputsTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _engine.updateInputs(_inputs);
      });
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    if (_busy) return;
    _busy = true;
    try {
      _inputsTimer?.cancel();
      _inputsTimer = null;

      // If you added fadeOutAndStop() to AmbientSynth, prefer it:
      // await _audio.fadeOutAndStop(fadeMs: 80);
      await _audio.stop();
    } finally {
      _busy = false;
    }
  }

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    _audio.setVolume(_volume);
  }

  void setMuted(bool m) {
    _muted = m;
    _audio.setMuted(m);
  }

  void updateInputs(SoundscapeInputs inputs) {
    _inputs = inputs;
  }
}
