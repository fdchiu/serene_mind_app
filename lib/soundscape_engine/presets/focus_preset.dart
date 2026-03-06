// lib/soundscape_engine/presets/focus_preset.dart
import '../graph/audio_node.dart';
import '../generators/noise_bed.dart';
import '../generators/harmonic_drone.dart';
import '../generators/rain.dart';
import '../generators/granular_shimmer.dart';

List<AudioNode> buildFocusPreset(int sr) => [
      NoiseBed(sr),
      HarmonicDrone(sr),
      // A little rain can provide “masking” for focus.
      Rain(sr),
      GranularShimmer(sr),
    ];
