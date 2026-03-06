// lib/soundscape_engine/generators/generator_base.dart
import '../graph/audio_node.dart';

abstract class GeneratorNode extends AudioNode {
  final int sampleRate;
  GeneratorNode(this.sampleRate);
}
