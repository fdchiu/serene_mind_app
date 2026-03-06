// lib/soundscape_engine/presets/preset_factory.dart
import '../engine_types.dart';
import '../graph/audio_node.dart';
import 'focus_preset.dart';
import 'downshift_preset.dart';
import 'sleep_preset.dart';

class PresetFactory {
  static List<AudioNode> build(SoundscapeMode mode, int sampleRate) {
    switch (mode) {
      case SoundscapeMode.focus:
        return buildFocusPreset(sampleRate);
      case SoundscapeMode.downshift:
        return buildDownshiftPreset(sampleRate);
      case SoundscapeMode.sleep:
        return buildSleepPreset(sampleRate);
    }
  }
}
