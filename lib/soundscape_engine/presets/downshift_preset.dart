// lib/soundscape_engine/presets/downshift_preset.dart
import '../graph/audio_node.dart';
import '../generators/noise_bed.dart';
import '../generators/wind.dart';
import '../generators/harmonic_drone.dart';
import '../generators/bell_events.dart';

List<AudioNode> buildDownshiftPreset(int sr) => [
      NoiseBed(sr),
      Wind(sr),
      HarmonicDrone(sr),
      BellEvents(sr),
    ];
