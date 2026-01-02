// lib/soundscape_engine/presets/sleep_preset.dart
import '../graph/audio_node.dart';
import '../generators/noise_bed.dart';
import '../generators/wind.dart';
import '../generators/harmonic_drone.dart';

List<AudioNode> buildSleepPreset(int sr) => [
      // Keep it simple and dark.
      NoiseBed(sr),
      Wind(sr),
      HarmonicDrone(sr),
    ];
