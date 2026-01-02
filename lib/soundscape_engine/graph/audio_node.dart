// lib/soundscape_engine/graph/audio_node.dart
import 'dart:typed_data';
import '../control_params.dart';

abstract class AudioNode {
  void reset();
  void render(Float32List outInterleaved, int frames, SoundscapeParams params);
  void dispose() {}
}
