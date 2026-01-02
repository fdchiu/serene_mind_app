// lib/soundscape_engine/graph/audio_graph.dart
import 'dart:typed_data';
import '../control_params.dart';
import 'audio_node.dart';
import 'mixer.dart';

class AudioGraph {
  final int sampleRate;
  final MixerBus _bus = MixerBus();

  List<AudioNode> _nodes = [];

  AudioGraph({required this.sampleRate});

  void setPreset(List<AudioNode> nodes) {
    // Dispose old nodes conservatively.
    for (final n in _nodes) {
      n.dispose();
    }
    _nodes = nodes;
    reset();
  }

  void reset() {
    for (final n in _nodes) {
      n.reset();
    }
  }

  void render(Float32List outInterleaved, int frames, SoundscapeParams params) {
    _bus.clear(outInterleaved);

    // Render each node additively into outInterleaved.
    for (final n in _nodes) {
      n.render(outInterleaved, frames, params);
    }

    // Master level from params
    _bus.master = (params.level * 0.90).clamp(0.0, 0.95);
    _bus.applyMasterAndLimit(outInterleaved);
  }

  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    _nodes = [];
  }
}
