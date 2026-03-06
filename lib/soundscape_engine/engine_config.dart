// lib/soundscape_engine/engine_config.dart
class SoundscapeConfig {
  final int sampleRate;

  /// Conservative “engine headroom” to reduce clipping risk.
  final double masterHeadroom;

  const SoundscapeConfig({
    this.sampleRate = 48000,
    this.masterHeadroom = 0.85,
  });
}
