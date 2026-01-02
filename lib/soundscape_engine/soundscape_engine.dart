// lib/soundscape_engine/soundscape_engine.dart
library soundscape_engine;

import 'dart:typed_data';
import 'engine_config.dart';
import 'engine_types.dart';
import 'state_inputs.dart';
import 'control_params.dart';
import 'adaptation/adaptation_policy.dart';
import 'adaptation/param_smoother.dart';
import 'graph/audio_graph.dart';
import 'presets/preset_factory.dart';

/// Main entry point.
///
/// Integration expectation:
/// - Call engine.updateInputs(...) periodically (e.g. 2–10 Hz)
/// - Your audio callback calls engine.renderInterleavedFloat32(...)
class SoundscapeEngine {
  final SoundscapeConfig config;
  final AudioGraph _graph;
  final AdaptationPolicy _policy;
  final ParamSmoother _smoother;

  /// Current target params (set by adaptation policy).
  SoundscapeParams _target = SoundscapeParams.defaults();

  /// Current smoothed params (what generators actually use).
  SoundscapeParams _current = SoundscapeParams.defaults();

  SoundscapeMode _mode = SoundscapeMode.focus;

  /// For change detection / stability logic.
  SoundscapeInputs _lastInputs = SoundscapeInputs.zero();

  SoundscapeEngine({
    SoundscapeConfig? config,
    AdaptationPolicy? policy,
    ParamSmoother? smoother,
  })  : config = config ?? const SoundscapeConfig(),
        _policy = policy ?? const DefaultAdaptationPolicy(),
        _smoother = smoother ?? const ParamSmoother.standard(),
        _graph = AudioGraph(sampleRate: (config ?? const SoundscapeConfig()).sampleRate) {
    // Build a default graph (mode-based preset).
    _graph.setPreset(PresetFactory.build(_mode, _graph.sampleRate));
  }

  SoundscapeMode get mode => _mode;
  SoundscapeParams get currentParams => _current;
  SoundscapeParams get targetParams => _target;

  /// Switch between Focus / Downshift / Sleep.
  /// Uses a conservative crossfade inside the graph.
  void setMode(SoundscapeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _graph.setPreset(PresetFactory.build(_mode, _graph.sampleRate));
  }

  /// Update the high-level inputs (privacy-first trends).
  /// Call at ~2–10 Hz.
  void updateInputs(SoundscapeInputs inputs) {
    // Compute next target using conservative, hysteresis-based policy.
    _target = _policy.computeTargetParams(
      mode: _mode,
      prevInputs: _lastInputs,
      inputs: inputs,
      prevTarget: _target,
      sampleRate: _graph.sampleRate,
    );
    _lastInputs = inputs;
  }

  /// Render audio (interleaved stereo float32): [L, R, L, R, ...]
  /// This should be called from your audio sink callback.
  void renderInterleavedFloat32(Float32List outInterleaved) {
    final frames = outInterleaved.length ~/ 2;

    // Smooth params (avoid oscillation + audible stepping).
    _current = _smoother.step(
      current: _current,
      target: _target,
      dtSeconds: frames / _graph.sampleRate,
      mode: _mode,
    );

    _graph.render(outInterleaved, frames, _current);
  }

  /// Optional helper: reset internal generator state.
  void reset() {
    _graph.reset();
    _target = SoundscapeParams.defaults();
    _current = SoundscapeParams.defaults();
    _lastInputs = SoundscapeInputs.zero();
  }

  void dispose() {
    _graph.dispose();
  }
}
