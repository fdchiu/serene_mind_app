import '../data/sound_designer_models.dart'; // adjust import to where SyntheticSoundParams lives
// If SyntheticSoundParams is in the same file as the page today,
// move it into lib/data/sound_designer_models.dart (recommended) OR
// change this import to the actual file path.

import 'dart:math' as math;

/// A perceptual macro layer that maps to many technical parameters.
class MacroState {
  final double intensity; // 0..1
  final double warmth;    // 0..1 (darker -> brighter)
  final double movement;  // 0..1
  final double texture;   // 0..1 (noise -> tone)
  final double tone;      // 0..1 (low -> high pitch band)

  const MacroState({
    required this.intensity,
    required this.warmth,
    required this.movement,
    required this.texture,
    required this.tone,
  });

  MacroState copyWith({
    double? intensity,
    double? warmth,
    double? movement,
    double? texture,
    double? tone,
  }) {
    return MacroState(
      intensity: intensity ?? this.intensity,
      warmth: warmth ?? this.warmth,
      movement: movement ?? this.movement,
      texture: texture ?? this.texture,
      tone: tone ?? this.tone,
    );
  }

  static const defaults = MacroState(
    intensity: 0.55,
    warmth: 0.40,
    movement: 0.35,
    texture: 0.35,
    tone: 0.35,
  );
}

double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);
double _clamp01(double v) => v.clamp(0.0, 1.0);

/// Category-aware mapping: safe ranges, perceptual intent.
/// This is designed to be stable and hard to "break".
SyntheticSoundParams applyMacrosToParams(SyntheticSoundParams p, MacroState m) {
  final cat = p.category.toLowerCase();

  final bool isOcean = cat.contains('ocean');
  final bool isForest = cat.contains('forest') || cat.contains('garden');
  final bool isFire = cat.contains('fire');
  final bool isNight = cat.contains('night') || cat.contains('insect');
  final bool isFocus = cat.contains('focus');
  final bool isRain = cat.contains('rain') || cat.contains('wind');

  // Intensity (safe gain range)
  final masterGain = _lerp(0.20, 0.90, m.intensity);

  // Warmth -> LP cutoff
  final cutoffMin = isOcean ? 350.0 : isFire ? 700.0 : isFocus ? 900.0 : 500.0;
  final cutoffMax = isOcean ? 4200.0 : isFire ? 9000.0 : isFocus ? 12000.0 : 8000.0;
  final lpCutoff = _lerp(cutoffMin, cutoffMax, m.warmth);

  // Movement -> LFO + flutter (lower for focus)
  final lfoRateMax = isFocus ? 0.9 : 2.2;
  final lfoRate = _lerp(0.06, lfoRateMax, m.movement);
  final lfoDepth = _lerp(isFocus ? 0.05 : 0.08, isFocus ? 0.35 : 0.60, m.movement);

  final flutterMax = isFocus ? 0.22 : isFire ? 0.75 : isRain ? 0.60 : 0.45;
  final noiseFlutter = _lerp(0.02, flutterMax, m.movement);

  // Texture -> noise vs tone
  final toneMix = _lerp(0.15, 0.90, m.texture);
  final noiseMix = _lerp(0.90, 0.15, m.texture);

  // Tone -> base freq band
  final baseMin = isOcean ? 70.0 : isForest ? 90.0 : isNight ? 160.0 : isFire ? 120.0 : 90.0;
  final baseMax = isOcean ? 240.0 : isForest ? 320.0 : isNight ? 900.0 : isFire ? 520.0 : 420.0;
  final baseFreq = _lerp(baseMin, baseMax, m.tone);

  // Resonance / detune tuned conservatively
  final resonance = _lerp(0.45, isFire ? 1.8 : 1.2, (m.warmth * 0.6 + m.movement * 0.4));
  final detune = isFocus ? _lerp(-2.0, 2.0, m.movement) : _lerp(-8.0, 8.0, m.movement);

  // Noise color defaults by category
  final NoiseColor noiseColor = isOcean || isForest
      ? NoiseColor.pink
      : isNight
      ? NoiseColor.brown
      : NoiseColor.white;

  // Envelope
  final attack = _lerp(0.01, 0.18, (1.0 - m.movement));
  final release = _lerp(isFocus ? 0.35 : 0.60, isFocus ? 1.6 : 2.4, (1.0 - m.movement));

  // Future-proof partials
  final partialCount = (1 + (m.texture * 5)).round().clamp(1, 8);
  final partialSpread = _lerp(0.08, 0.45, m.warmth);

  return p.copyWith(
    masterGain: masterGain,
    lpCutoff: lpCutoff,
    lpResonance: resonance,
    lfoRate: lfoRate,
    lfoDepth: lfoDepth,
    noiseMix: _clamp01(noiseMix),
    toneMix: _clamp01(toneMix),
    baseFreq: baseFreq,
    detuneCents: detune,
    noiseFlutter: _clamp01(noiseFlutter),
    noiseColor: noiseColor,
    attack: attack,
    release: release,
    partialCount: partialCount,
    partialSpread: partialSpread,
    lfoTarget: LfoTarget.cutoff,
  );
}

/// Safe random walk for "Variation" button.
MacroState varyMacros(MacroState m, {double radius = 0.12}) {
  final r = math.Random();
  double bump(double v) => (v + (r.nextDouble() * 2 - 1) * radius).clamp(0.0, 1.0);
  return m.copyWith(
    intensity: bump(m.intensity),
    warmth: bump(m.warmth),
    movement: bump(m.movement),
    texture: bump(m.texture),
    tone: bump(m.tone),
  );
}
