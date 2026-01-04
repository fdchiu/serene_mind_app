import 'sound_macros.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);

double _clamp01(double v) => v.clamp(0.0, 1.0);

/// Category-aware macro mapping.
/// - Keeps changes safe and perceptual.
/// - Does not try to be "perfect synthesis"; the goal is usability.
/*SyntheticSoundParams applyMacrosToParams(
    SyntheticSoundParams p,
    MacroState m,
    ) {
  final cat = p.category.toLowerCase();

  // Bias defaults by category.
  // These are intentionally conservative to avoid silence/harshness.
  final bool isOcean = cat.contains('ocean');
  final bool isForest = cat.contains('forest') || cat.contains('garden');
  final bool isFire = cat.contains('fire');
  final bool isNight = cat.contains('night') || cat.contains('insect');
  final bool isFocus = cat.contains('focus');
  final bool isRain = cat.contains('rain') || cat.contains('wind');

  // Intensity: primarily master gain, plus a bit of event energy for fire/rain.
  final masterGain = _lerp(0.20, 0.90, m.intensity);

  // Warmth: map to lowpass cutoff (darker->brighter).
  // Category constrains ranges to stay plausible.
  final cutoffMin = isOcean ? 350.0 : isFire ? 700.0 : isFocus ? 900.0 : 500.0;
  final cutoffMax = isOcean ? 4200.0 : isFire ? 9000.0 : isFocus ? 12000.0 : 8000.0;
  final lpCutoff = _lerp(cutoffMin, cutoffMax, m.warmth);

  // Movement: LFO rate/depth + flutter. Keep LFO conservative in Focus.
  final lfoRateMax = isFocus ? 0.9 : 2.2;
  final lfoRate = _lerp(0.06, lfoRateMax, m.movement);
  final lfoDepth = _lerp(isFocus ? 0.05 : 0.08, isFocus ? 0.35 : 0.60, m.movement);

  // Texture: noise <-> tone balance
  // texture=0 => more noise, texture=1 => more tone
  // Keep hybrid in the middle; avoid both near zero.
  final toneMix = _lerp(0.15, 0.90, m.texture);
  final noiseMix = _lerp(0.90, 0.15, m.texture);

  // Tone: base frequency. Different bands by category.
  final baseMin = isOcean ? 70.0 : isForest ? 90.0 : isNight ? 160.0 : isFire ? 120.0 : 90.0;
  final baseMax = isOcean ? 240.0 : isForest ? 320.0 : isNight ? 900.0 : isFire ? 520.0 : 420.0;
  final baseFreq = _lerp(baseMin, baseMax, m.tone);

  // Flutter: more in fire/rain, less in focus.
  final flutterMax = isFocus ? 0.22 : isFire ? 0.75 : isRain ? 0.60 : 0.45;
  final noiseFlutter = _lerp(0.02, flutterMax, m.movement);

  // Resonance: small movement with warmth (bright can take slightly higher Q, but cap).
  final resonance = _lerp(0.45, isFire ? 1.8 : 1.2, (m.warmth * 0.6 + m.movement * 0.4));

  // Detune: subtle chorus feel; keep it near 0 for focus.
  final detune = isFocus ? _lerp(-2.0, 2.0, m.movement) : _lerp(-8.0, 8.0, m.movement);

  // Noise color: warmer categories pick pink/brown.
  final NoiseColor noiseColor = isOcean || isForest
      ? NoiseColor.pink
      : isNight
      ? NoiseColor.brown
      : NoiseColor.white;

  // Envelope: keep attack short and release moderate; vary slightly with movement.
  final attack = _lerp(0.01, 0.18, (1.0 - m.movement));
  final release = _lerp(isFocus ? 0.35 : 0.60, isFocus ? 1.6 : 2.4, (1.0 - m.movement));

  // Partials: your synth currently doesn't use partialCount/partialSpread in DSP,
  // but keep meaningful values for future.
  final partialCount = (1 + (m.texture * 5)).round().clamp(1, 8);
  final partialSpread = _lerp(0.08, 0.45, m.warmth);

  // LFO target: cutoff is the most perceptually safe default.
  final lfoTarget = LfoTarget.cutoff;

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
    lfoTarget: lfoTarget,
  );
}*/

class SyntheticSoundParams {
  // Identity
  final String category; // e.g. "Ocean", "Forest", "Fire", "Night", etc.
  final String name;

  // Mixer
  final double noiseMix; // 0..1
  final double toneMix; // 0..1
  final double masterGain; // 0..1

  // Tone
  final double baseFreq; // Hz
  final double detuneCents; // -50..+50
  final int partialCount; // 1..8
  final double partialSpread; // 0..1 (how far partials spread from base)

  // Envelope (global amplitude)
  final double attack; // seconds 0..2
  final double release; // seconds 0..5

  // Filter
  final double lpCutoff; // Hz 50..20000
  final double lpResonance; // 0.1..10

  // Modulation (LFO)
  final double lfoRate; // Hz 0..10
  final double lfoDepth; // 0..1
  final LfoTarget lfoTarget; // cutoff or gain or pitch

  // Noise shaping
  final NoiseColor noiseColor; // white/pink/brown
  final double noiseFlutter; // 0..1 (slow random wobble intensity)

  const SyntheticSoundParams({
    required this.category,
    required this.name,
    required this.noiseMix,
    required this.toneMix,
    required this.masterGain,
    required this.baseFreq,
    required this.detuneCents,
    required this.partialCount,
    required this.partialSpread,
    required this.attack,
    required this.release,
    required this.lpCutoff,
    required this.lpResonance,
    required this.lfoRate,
    required this.lfoDepth,
    required this.lfoTarget,
    required this.noiseColor,
    required this.noiseFlutter,
  });

  SyntheticSoundParams copyWith({
    String? category,
    String? name,
    double? noiseMix,
    double? toneMix,
    double? masterGain,
    double? baseFreq,
    double? detuneCents,
    int? partialCount,
    double? partialSpread,
    double? attack,
    double? release,
    double? lpCutoff,
    double? lpResonance,
    double? lfoRate,
    double? lfoDepth,
    LfoTarget? lfoTarget,
    NoiseColor? noiseColor,
    double? noiseFlutter,
  }) {
    return SyntheticSoundParams(
      category: category ?? this.category,
      name: name ?? this.name,
      noiseMix: noiseMix ?? this.noiseMix,
      toneMix: toneMix ?? this.toneMix,
      masterGain: masterGain ?? this.masterGain,
      baseFreq: baseFreq ?? this.baseFreq,
      detuneCents: detuneCents ?? this.detuneCents,
      partialCount: partialCount ?? this.partialCount,
      partialSpread: partialSpread ?? this.partialSpread,
      attack: attack ?? this.attack,
      release: release ?? this.release,
      lpCutoff: lpCutoff ?? this.lpCutoff,
      lpResonance: lpResonance ?? this.lpResonance,
      lfoRate: lfoRate ?? this.lfoRate,
      lfoDepth: lfoDepth ?? this.lfoDepth,
      lfoTarget: lfoTarget ?? this.lfoTarget,
      noiseColor: noiseColor ?? this.noiseColor,
      noiseFlutter: noiseFlutter ?? this.noiseFlutter,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'category': category,
    'name': name,
    'noiseMix': noiseMix,
    'toneMix': toneMix,
    'masterGain': masterGain,
    'baseFreq': baseFreq,
    'detuneCents': detuneCents,
    'partialCount': partialCount,
    'partialSpread': partialSpread,
    'attack': attack,
    'release': release,
    'lpCutoff': lpCutoff,
    'lpResonance': lpResonance,
    'lfoRate': lfoRate,
    'lfoDepth': lfoDepth,
    'lfoTarget': lfoTarget.name,
    'noiseColor': noiseColor.name,
    'noiseFlutter': noiseFlutter,
  };

  static SyntheticSoundParams fromJson(Map<String, dynamic> j) {
    // tolerate missing keys for forward/backward compatibility
    final lfoTarget = LfoTarget.values
        .where((e) => e.name == (j['lfoTarget'] ?? 'cutoff'))
        .cast<LfoTarget?>()
        .firstOrNull;
    final noiseColor = NoiseColor.values
        .where((e) => e.name == (j['noiseColor'] ?? 'white'))
        .cast<NoiseColor?>()
        .firstOrNull;

    return SyntheticSoundParams(
      category: (j['category'] ?? 'Custom').toString(),
      name: (j['name'] ?? 'Untitled').toString(),
      noiseMix: _asDouble(j['noiseMix'], 0.7),
      toneMix: _asDouble(j['toneMix'], 0.3),
      masterGain: _asDouble(j['masterGain'], 0.6),
      baseFreq: _asDouble(j['baseFreq'], 180.0),
      detuneCents: _asDouble(j['detuneCents'], 0.0),
      partialCount: _asInt(j['partialCount'], 3).clamp(1, 8),
      partialSpread: _asDouble(j['partialSpread'], 0.25),
      attack: _asDouble(j['attack'], 0.05),
      release: _asDouble(j['release'], 1.2),
      lpCutoff: _asDouble(j['lpCutoff'], 2200.0),
      lpResonance: _asDouble(j['lpResonance'], 0.7),
      lfoRate: _asDouble(j['lfoRate'], 0.25),
      lfoDepth: _asDouble(j['lfoDepth'], 0.25),
      lfoTarget: lfoTarget ?? LfoTarget.cutoff,
      noiseColor: noiseColor ?? NoiseColor.white,
      noiseFlutter: _asDouble(j['noiseFlutter'], 0.15),
    );
  }

  static double _asDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

enum LfoTarget { cutoff, gain, pitch }
enum NoiseColor { white, pink, brown }
