import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'sound_preset.dart';

typedef PcmRenderer = void Function(Float32List interleavedStereo);

class AmbientSynth {
  final int sampleRate;
  final int channels; // default channels for preset mode
  final int frameMs;

  FlutterSoundPlayer? _player;
  StreamController<Food>? _foodCtrl;
  StreamSubscription<Food>? _foodSub;
  Timer? _timer;

  SoundPreset? _preset;

  // Renderer mode
  PcmRenderer? _renderer;
  int _activeChannels = 1;

  double _volume = 0.5;
  bool _muted = false;

  // DSP state (preset mode)
  double _lp = 0.0;
  double _lp2 = 0.0;
  double _eventEnv = 0.0;
  double _tonePhase = 0.0;
  double _lfoPhase = 0.0;

  final Random _rng = Random();

  // Smooth gain ramp
  double _gainCurrent = 0.0;
  double _gainTarget = 0.0;

  // Serialize engine operations
  Future<void> _op = Future.value();

  // Only increment this when we must invalidate an existing timer (stream restart/stop).
  int _epoch = 0;

  // 60ms ramp
  double get _gainStepPerSample {
    const rampSeconds = 0.06;
    return 1.0 / (rampSeconds * sampleRate);
  }

  AmbientSynth({
    this.sampleRate = 48000,
    this.channels = 1,
    this.frameMs = 20,
  });

  bool get isRunning => _timer != null;

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    _gainTarget = _muted ? 0.0 : _volume;
  }

  void setMuted(bool m) {
    _muted = m;
    _gainTarget = _muted ? 0.0 : _volume;
  }

  /// Apply preset parameters WITHOUT restarting audio.
  /// IMPORTANT: does not invalidate timer.
  Future<void> applyPreset(SoundPreset preset) {
    return _op = _op.then((_) async {
      _preset = preset;
      _renderer = null;
      _gainTarget = _muted ? 0.0 : _volume;
      // Keep DSP state (phases) continuous to avoid clicks.
    });
  }

  // ----------------------------
  // Preset mode
  // ----------------------------
  Future<void> startWithPreset(SoundPreset preset) {
    return _op = _op.then((_) async {
      // If already running in preset mode with same channel config, just apply params.
      final sameStream = isRunning && _renderer == null && _activeChannels == channels;
      _preset = preset;
      _renderer = null;
      _activeChannels = channels;

      if (sameStream) {
        _gainTarget = _muted ? 0.0 : _volume;
        return;
      }

      // Restart path: invalidate current timer.
      _epoch++;

      await _fadeOutAndStopInternal(fadeMs: 80);
      _resetDspStateForPreset();
      _gainCurrent = 0.0;
      _gainTarget = _muted ? 0.0 : _volume;

      await _startStream(numChannels: _activeChannels);

      final samplesPerFrame = sampleRate * frameMs ~/ 1000;
      final int myEpoch = _epoch;

      _timer = Timer.periodic(Duration(milliseconds: frameMs), (_) {
        if (myEpoch != _epoch) return;

        final pcm = _renderFramePreset(samplesPerFrame);
        final bytes = Uint8List(pcm.length * 2);
        final bd = ByteData.view(bytes.buffer);
        for (int i = 0; i < pcm.length; i++) {
          bd.setInt16(i * 2, pcm[i], Endian.little);
        }

        final ctrl = _foodCtrl;
        if (ctrl == null || ctrl.isClosed) return;
        try {
          ctrl.add(FoodData(bytes));
        } catch (_) {}
      });
    });
  }

  // ----------------------------
  // Renderer mode
  // ----------------------------
  Future<void> startWithRenderer({
    required int channels,
    required PcmRenderer render,
  }) {
    return _op = _op.then((_) async {
      if (channels != 2) {
        throw ArgumentError('Adaptive renderer expects stereo (channels=2).');
      }

      final sameStream = isRunning && _renderer != null && _activeChannels == channels;
      _preset = null;
      _renderer = render;
      _activeChannels = channels;

      if (sameStream) {
        _gainTarget = _muted ? 0.0 : _volume;
        return;
      }

      // Restart path: invalidate current timer.
      _epoch++;

      await _fadeOutAndStopInternal(fadeMs: 80);
      _gainCurrent = 0.0;
      _gainTarget = _muted ? 0.0 : _volume;

      await _startStream(numChannels: _activeChannels);

      final framesPerTick = sampleRate * frameMs ~/ 1000;
      final floatBuf = Float32List(framesPerTick * 2);
      final intBuf = Int16List(framesPerTick * 2);

      final int myEpoch = _epoch;

      _timer = Timer.periodic(Duration(milliseconds: frameMs), (_) {
        if (myEpoch != _epoch) return;

        floatBuf.fillRange(0, floatBuf.length, 0.0);
        _renderer?.call(floatBuf);

        for (int i = 0; i < floatBuf.length; i++) {
          _gainCurrent += (_gainTarget - _gainCurrent)
              .clamp(-_gainStepPerSample, _gainStepPerSample);

          final v = (floatBuf[i] * _gainCurrent).clamp(-1.0, 1.0);
          intBuf[i] = (v * 32767.0).round();
        }

        final bytes = Uint8List(intBuf.length * 2);
        final bd = ByteData.view(bytes.buffer);
        for (int i = 0; i < intBuf.length; i++) {
          bd.setInt16(i * 2, intBuf[i], Endian.little);
        }

        final ctrl = _foodCtrl;
        if (ctrl == null || ctrl.isClosed) return;
        try {
          ctrl.add(FoodData(bytes));
        } catch (_) {}
      });
    });
  }

  Future<void> fadeOutAndStop({int fadeMs = 80}) {
    return _op = _op.then((_) async {
      _epoch++; // invalidate timer
      await _fadeOutAndStopInternal(fadeMs: fadeMs);
    });
  }

  Future<void> stop() {
    return _op = _op.then((_) async {
      _epoch++; // invalidate timer
      await _stopInternal();
    });
  }

  // ----------------------------
  // Internals
  // ----------------------------

  void _resetDspStateForPreset() {
    _lp = 0.0;
    _lp2 = 0.0;
    _eventEnv = 0.0;
    // Keep phases continuous by default.
  }

  Future<void> _fadeOutAndStopInternal({required int fadeMs}) async {
    _gainTarget = 0.0;
    await Future<void>.delayed(Duration(milliseconds: fadeMs));
    await _stopInternal();
  }

  Future<void> _startStream({required int numChannels}) async {
    // Ensure fully stopped before opening a new stream.
    await _stopInternal();

    final player = FlutterSoundPlayer();
    await player.openPlayer();

    // Broadcast is fine; we only listen once, but this prevents accidental misuse.
    final ctrl = StreamController<Food>.broadcast();

    final samplesPerFrame = sampleRate * frameMs ~/ 1000;

    await player.startPlayerFromStream(
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      numChannels: numChannels,
      bufferSize: samplesPerFrame,
      interleaved: numChannels > 1,
    );

    final sub = ctrl.stream.listen((food) {
      final sink = player.foodSink;
      if (sink == null) return;
      try {
        sink.add(food);
      } catch (_) {}
    });

    _player = player;
    _foodCtrl = ctrl;
    _foodSub = sub;
  }

  Future<void> _stopInternal() async {
    _timer?.cancel();
    _timer = null;

    _renderer = null;

    final foodSub = _foodSub;
    _foodSub = null;
    try {
      await foodSub?.cancel();
    } catch (_) {}

    final foodCtrl = _foodCtrl;
    _foodCtrl = null;
    try {
      await foodCtrl?.close();
    } catch (_) {}

    final player = _player;
    _player = null;
    if (player != null) {
      try {
        await player.stopPlayer();
      } catch (_) {}
      try {
        await player.closePlayer();
      } catch (_) {}
    }
  }

  List<int> _renderFramePreset(int n) {
    final p = _preset;
    if (p == null) return List<int>.filled(n, 0);

    final out = List<int>.filled(n, 0);

    final vol = (_muted ? 0.0 : _volume) * p.baseGain;
    final alpha = p.noiseSmooth;
    final eventProb = p.eventRate / sampleRate;

    for (int i = 0; i < n; i++) {
      double x = 0.0;

      if (p.kind != SynthKind.tone) {
        final wn = _rng.nextDouble() * 2 - 1;
        _lp += alpha * (wn - _lp);
        _lp2 += alpha * 0.5 * (_lp - _lp2);
        x += (p.kind == SynthKind.hybrid) ? _lp2 : _lp;
      }

      if (p.kind != SynthKind.noise && p.toneHz != null) {
        _tonePhase += 2 * pi * p.toneHz! / sampleRate;
        if (_tonePhase > 2 * pi) _tonePhase -= 2 * pi;
        x += sin(_tonePhase);
      }

      _lfoPhase += 2 * pi * p.lfoHz / sampleRate;
      if (_lfoPhase > 2 * pi) _lfoPhase -= 2 * pi;
      final lfo = sin(_lfoPhase) * 0.5 + 0.5;
      x *= (1.0 - p.lfoDepth) + p.lfoDepth * lfo;

      if (_rng.nextDouble() < eventProb) {
        _eventEnv = 1.0;
      }
      final decay = (p.eventDecay <= 0.0005) ? 0.0005 : p.eventDecay;
      _eventEnv *= exp(-1 / (decay * sampleRate));
      x += _eventEnv * p.eventGain;

      _gainCurrent += (_gainTarget - _gainCurrent)
          .clamp(-_gainStepPerSample, _gainStepPerSample);

      x = _tanh(x * vol) * _gainCurrent;
      out[i] = (x.clamp(-1.0, 1.0) * 32767).round();
    }

    return out;
  }

  double _tanh(double x) {
    final e2x = exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }
}
