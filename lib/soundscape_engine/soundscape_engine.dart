// lib/soundscape_engine/soundscape_engine.dart
library soundscape_engine;

import 'dart:math';
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
  final AdaptationPolicy _policy;
  final ParamSmoother _smoother;

  // We use two graphs for crossfade (A = current, B = incoming).
  late final AudioGraph _graphA;
  late final AudioGraph _graphB;

  bool _useAAsActive = true;

  // Crossfade state
  bool _xfadeActive = false;
  int _xfadePosSamples = 0;
  int _xfadeTotalSamples = 0;

  // Scratch buffers for rendering both graphs during crossfade
  Float32List _tmpA = Float32List(0);
  Float32List _tmpB = Float32List(0);

  /// Current target params (set by adaptation policy).
  SoundscapeParams _target = SoundscapeParams.defaults();

  /// Current smoothed params (what generators actually use).
  SoundscapeParams _current = SoundscapeParams.defaults();

  SoundscapeMode _mode = SoundscapeMode.focus;

  /// Optional session-phase shaping
  SoundscapePhase _phase = SoundscapePhase.steady;
  double _phaseProgress01 = 0.0;

  /// For change detection / stability logic.
  SoundscapeInputs _lastInputs = SoundscapeInputs.zero();

  SoundscapeEngine({
    SoundscapeConfig? config,
    AdaptationPolicy? policy,
    ParamSmoother? smoother,
  })  : config = config ?? const SoundscapeConfig(),
        _policy = policy ?? const DefaultAdaptationPolicy(),
        _smoother = smoother ?? const ParamSmoother.standard() {
    final sr = this.config.sampleRate;

    _graphA = AudioGraph(sampleRate: sr);
    _graphB = AudioGraph(sampleRate: sr);

    // Initialize A with default mode preset; B stays idle until crossfade.
    _graphA.setPreset(PresetFactory.build(_mode, sr));
    _graphA.reset();
    _graphB.setPreset(const []);
  }

  SoundscapeMode get mode => _mode;
  SoundscapePhase get phase => _phase;
  double get phaseProgress01 => _phaseProgress01;

  SoundscapeParams get currentParams => _current;
  SoundscapeParams get targetParams => _target;

  int get sampleRate => config.sampleRate;

  /// Optional: caller (meditation screen) can drive intro/steady/wind-down.
  /// progress01 is optional if you want to indicate how far into the phase you are.
  void setPhase(SoundscapePhase phase, {double progress01 = 0.0}) {
    _phase = phase;
    _phaseProgress01 = progress01.clamp(0.0, 1.0);
  }

  /// Switch between Focus / Downshift / Sleep with a true crossfade.
  ///
  /// This avoids audible artifacts from disposing nodes mid-render and makes
  /// mode transitions feel professional.
  void setMode(
      SoundscapeMode mode, {
        double crossfadeSeconds = 0.35,
      }) {
    if (mode == _mode && !_xfadeActive) return;

    _mode = mode;

    final sr = config.sampleRate;
    final nodes = PresetFactory.build(_mode, sr);

    // Prepare incoming graph with new preset.
    final incoming = _useAAsActive ? _graphB : _graphA;
    incoming.setPreset(nodes);
    incoming.reset();

    // Start crossfade
    _xfadeActive = true;
    _xfadePosSamples = 0;
    _xfadeTotalSamples = max(1, (crossfadeSeconds * sr).round());
  }

  /// Update the high-level inputs (privacy-first trends).
  /// Call at ~2–10 Hz.
  void updateInputs(SoundscapeInputs inputs, {bool immediate = false}) {
    _target = _policy.computeTargetParams(
      mode: _mode,
      prevInputs: _lastInputs,
      inputs: inputs,
      prevTarget: _target,
      sampleRate: config.sampleRate,
    );
    _lastInputs = inputs;

    if (immediate) {
      // Nudge current toward target to reduce perceived latency after a sudden change.
      _current = _smoother.step(
        current: _current,
        target: _applyPhaseShape(_target),
        dtSeconds: 0.25,
        mode: _mode,
      );
    }
  }

  /// Render audio (interleaved stereo float32): [L, R, L, R, ...]
  /// This should be called from your audio sink callback.
  void renderInterleavedFloat32(Float32List outInterleaved) {
    final frames = outInterleaved.length ~/ 2;
    if (frames <= 0) return;

    // Smooth params (avoid oscillation + audible stepping).
    _current = _smoother.step(
      current: _current,
      target: _applyPhaseShape(_target),
      dtSeconds: frames / config.sampleRate,
      mode: _mode,
      phase: _phase
    );

    if (!_xfadeActive) {
      _activeGraph().render(outInterleaved, frames, _current);
      return;
    }

    // Ensure temp buffers are large enough
    final needed = outInterleaved.length;
    if (_tmpA.length != needed) _tmpA = Float32List(needed);
    if (_tmpB.length != needed) _tmpB = Float32List(needed);

    final active = _activeGraph();
    final incoming = _incomingGraph();

    // Render both graphs with the same current params (keeps adaptation consistent).
    active.render(_tmpA, frames, _current);
    incoming.render(_tmpB, frames, _current);

    // Mix with a smooth equal-power crossfade across the rendered block.
    // We do per-sample fade so even large callbacks fade smoothly.
    final sr = config.sampleRate;
    final total = _xfadeTotalSamples;
    int pos = _xfadePosSamples;

    for (int i = 0; i < needed; i++) {
      // Progress 0..1
      final t = (pos / total).clamp(0.0, 1.0);

      // Equal-power fade
      final a = cos(t * (pi / 2));
      final b = sin(t * (pi / 2));

      outInterleaved[i] = (_tmpA[i] * a) + (_tmpB[i] * b);

      // Advance fade position every sample (not every frame) because interleaved stereo.
      pos++;
    }

    _xfadePosSamples = pos;

    if (_xfadePosSamples >= _xfadeTotalSamples) {
      // Finish: swap active graph, stop crossfade.
      _xfadeActive = false;
      _useAAsActive = !_useAAsActive;

      // It is now safe to clear the old graph by setting an empty preset
      // (optional). We keep it as-is for fast switching; you may clear to save memory.
      // _incomingGraph().setPreset(const []);
    }
  }

  /// Optional helper: reset internal generator state.
  /// hard=true resets current/target to defaults; hard=false preserves current smoothing state.
  void reset({bool hard = false}) {
    _activeGraph().reset();
    if (_xfadeActive) {
      _incomingGraph().reset();
    }
    _target = SoundscapeParams.defaults();
    if (hard) _current = SoundscapeParams.defaults();
    _lastInputs = SoundscapeInputs.zero();
  }

  void dispose() {
    _graphA.dispose();
    _graphB.dispose();
  }

  // -----------------------
  // Internals
  // -----------------------

  AudioGraph _activeGraph() => _useAAsActive ? _graphA : _graphB;
  AudioGraph _incomingGraph() => _useAAsActive ? _graphB : _graphA;

  SoundscapeParams _applyPhaseShape(SoundscapeParams p) {
    // Conservative shaping (keeps within 0..1 via clamp01()).
    // progress01 can further bias shaping if you later want continuous curves.
    switch (_phase) {
      case SoundscapePhase.intro:
        return p
            .copyWith(
          density: p.density * 0.75,
          brightness: p.brightness * 0.82,
          variation: p.variation * 0.80,
          level: p.level * 0.92,
        )
            .clamp01();
      case SoundscapePhase.windDown:
        return p
            .copyWith(
          density: p.density * 0.55,
          brightness: p.brightness * 0.70,
          variation: p.variation * 0.65,
          level: p.level * 0.90,
        )
            .clamp01();
      case SoundscapePhase.steady:
        return p.clamp01();
    }
  }

  void setPhaseByProgress(double progress01) {
    final p = progress01.clamp(0.0, 1.0);
    if (p < 0.15) {
      setPhase(SoundscapePhase.intro, progress01: p / 0.15);
    } else if (p > 0.85) {
      setPhase(SoundscapePhase.windDown, progress01: (p - 0.85) / 0.15);
    } else {
      setPhase(SoundscapePhase.steady, progress01: (p - 0.15) / 0.70);
    }
  }

}
