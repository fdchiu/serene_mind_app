enum SoundCategory {
  weather,
  ocean,
  animals,
  forest,
  fire,
  night,
  focus,
  garden,
  instruments,
  pipes,
  insects,
}

enum SynthKind { noise, tone, hybrid }

class SoundPreset {
  final String id;
  final String name;
  final SoundCategory category;
  final SynthKind kind;

  final double baseGain;
  final double noiseSmooth;
  final double lowpassHz;
  final double highpassHz;
  final double lfoHz;
  final double lfoDepth;
  final double eventRate;
  final double eventDecay;
  final double eventGain;
  final double? toneHz;
  final double? secondToneHz;
  final double chirpMix;

  const SoundPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.kind,
    this.baseGain = 0.4,
    this.noiseSmooth = 0.08,
    this.lowpassHz = 3000,
    this.highpassHz = 0,
    this.lfoHz = 0.2,
    this.lfoDepth = 0.5,
    this.eventRate = 0.0,
    this.eventDecay = 0.08,
    this.eventGain = 0.0,
    this.toneHz,
    this.secondToneHz,
    this.chirpMix = 0.0,
  });
}

class SoundPresetCollection {
  final SoundCategory category;
  final String label;
  final String icon;
  final List<SoundPreset> presets;

  const SoundPresetCollection({
    required this.category,
    required this.label,
    required this.icon,
    required this.presets,
  });
}

const soundPresetCollections = [
  SoundPresetCollection(
    category: SoundCategory.weather,
    label: 'Rain & Thunder',
    icon: '🌧️',
    presets: [
      SoundPreset(
        id: 'synth_rain_soft',
        name: 'Soft Rain',
        category: SoundCategory.weather,
        kind: SynthKind.noise,
        baseGain: 0.34,
        noiseSmooth: 0.12,
        lowpassHz: 3600,
        highpassHz: 180,
        lfoHz: 4.5,
        lfoDepth: 0.18,
        eventRate: 28,
        eventDecay: 0.035,
        eventGain: 0.12,
      ),
      SoundPreset(
        id: 'synth_rainstorm',
        name: 'Rainstorm',
        category: SoundCategory.weather,
        kind: SynthKind.hybrid,
        baseGain: 0.5,
        noiseSmooth: 0.06,
        lowpassHz: 2400,
        highpassHz: 120,
        lfoHz: 0.18,
        lfoDepth: 0.75,
        eventRate: 14,
        eventDecay: 0.045,
        eventGain: 0.32,
      ),
    ],
  ),
  SoundPresetCollection(
    category: SoundCategory.ocean,
    label: 'Ocean & Tides',
    icon: '🌊',
    presets: [
      SoundPreset(
        id: 'synth_ocean_deep',
        name: 'Deep Tide',
        category: SoundCategory.ocean,
        kind: SynthKind.noise,
        baseGain: 0.52,
        noiseSmooth: 0.05,
        lowpassHz: 1600,
        highpassHz: 70,
        lfoHz: 0.08,
        lfoDepth: 0.9,
      ),
      SoundPreset(
        id: 'synth_shoreline',
        name: 'Shoreline Wind',
        category: SoundCategory.ocean,
        kind: SynthKind.hybrid,
        baseGain: 0.4,
        noiseSmooth: 0.04,
        lowpassHz: 1800,
        highpassHz: 90,
        lfoHz: 0.3,
        lfoDepth: 0.65,
        eventRate: 6,
        eventDecay: 0.06,
        eventGain: 0.22,
      ),
    ],
  ),
  SoundPresetCollection(
    category: SoundCategory.forest,
    label: 'Forest & Birds',
    icon: '🌿',
    presets: [
      SoundPreset(
        id: 'synth_forest_morning',
        name: 'Morning Birds',
        category: SoundCategory.forest,
        kind: SynthKind.hybrid,
        baseGain: 0.24,
        noiseSmooth: 0.08,
        lowpassHz: 4200,
        highpassHz: 380,
        lfoHz: 0.2,
        lfoDepth: 0.25,
        eventRate: 1.4,
        eventDecay: 0.14,
        eventGain: 0.34,
        chirpMix: 0.95,
      ),
      const SoundPreset(
        id: 'morning_birds',
        name: 'Morning Birds 2',
        category: SoundCategory.forest,
        kind: SynthKind.hybrid,
        baseGain: 0.26, // moderate loudness
        noiseSmooth: 0.07, // bright, thin bed
        lowpassHz: 4800, // open top end for chirps
        highpassHz: 520, // thin out low rumble
        lfoHz: 0.24, // gentle motion
        lfoDepth: 0.22,
        eventRate: 2.0, // more frequent calls
        eventDecay: 0.12, // short chirp tail
        eventGain: 0.32, // audible but controlled
        chirpMix: 1.0,
      ),
      SoundPreset(
        id: 'synth_forest_breeze',
        name: 'Forest Breeze',
        category: SoundCategory.forest,
        kind: SynthKind.noise,
        baseGain: 0.32,
        noiseSmooth: 0.16,
        lowpassHz: 1800,
        highpassHz: 140,
        lfoHz: 0.18,
        lfoDepth: 0.35,
      ),
    ],
  ),
  SoundPresetCollection(
    category: SoundCategory.fire,
    label: 'Fire & Embers',
    icon: '🔥',
    presets: [
      SoundPreset(
        id: 'synth_fireplace',
        name: 'Fireplace',
        category: SoundCategory.fire,
        kind: SynthKind.noise,
        baseGain: 0.36,
        noiseSmooth: 0.06,
        lowpassHz: 1600,
        highpassHz: 140,
        lfoHz: 0.35,
        lfoDepth: 0.32,
        eventRate: 14,
        eventDecay: 0.035,
        eventGain: 0.35,
      ),
      SoundPreset(
        id: 'synth_embers',
        name: 'Glowing Embers',
        category: SoundCategory.fire,
        kind: SynthKind.hybrid,
        baseGain: 0.28,
        noiseSmooth: 0.08,
        lowpassHz: 1400,
        highpassHz: 180,
        lfoHz: 0.45,
        lfoDepth: 0.25,
        eventRate: 24,
        eventDecay: 0.018,
        eventGain: 0.42,
      ),
    ],
  ),
  SoundPresetCollection(
    category: SoundCategory.focus,
    label: 'Focus Tones',
    icon: '🎧',
    presets: [
      SoundPreset(
        id: 'synth_focus_alpha',
        name: 'Alpha Drift',
        category: SoundCategory.focus,
        kind: SynthKind.tone,
        baseGain: 0.25,
        lfoHz: 0.05,
        lfoDepth: 0.3,
        toneHz: 210,
        secondToneHz: 200,
      ),
      SoundPreset(
        id: 'synth_focus_beta',
        name: 'Beta Pulse',
        category: SoundCategory.focus,
        kind: SynthKind.tone,
        baseGain: 0.22,
        lfoHz: 0.08,
        lfoDepth: 0.4,
        toneHz: 430,
        secondToneHz: 418,
      ),
    ],
  ),
  SoundPresetCollection(
    category: SoundCategory.night,
    label: 'Night Chorus',
    icon: '🌙',
    presets: [
      SoundPreset(
        id: 'synth_crickets',
        name: 'Crickets',
        category: SoundCategory.night,
        kind: SynthKind.hybrid,
        baseGain: 0.22,
        noiseSmooth: 0.05,
        lowpassHz: 5200,
        highpassHz: 650,
        lfoHz: 0.3,
        lfoDepth: 0.12,
        eventRate: 11,
        eventDecay: 0.035,
        eventGain: 0.3,
        chirpMix: 1.0,
      ),
      const SoundPreset(
        id: 'crickets_v2',
        name: 'Crickets',
        category: SoundCategory.night,
        kind: SynthKind.hybrid,
        baseGain: 0.2,
        noiseSmooth: 0.07, // bright hiss
        lowpassHz: 4800, // open highs
        highpassHz: 520, // thin timbre
        lfoHz: 0.22,
        lfoDepth: 0.18,
        eventRate: 8.0, // steady ticks
        eventDecay: 0.045, // short chirps
        eventGain: 0.24, // controlled clicks
        chirpMix: 0.85,
      ),

      SoundPreset(
        id: 'synth_insects',
        name: 'Night Insects',
        category: SoundCategory.insects,
        kind: SynthKind.noise,
        baseGain: 0.2,
        noiseSmooth: 0.1,
        lowpassHz: 3600,
        highpassHz: 400,
        lfoHz: 0.32,
        lfoDepth: 0.18,
        eventRate: 5,
        eventDecay: 0.06,
        eventGain: 0.18,
        chirpMix: 0.3,
      ),
    ],
  ),
  SoundPresetCollection(
    category: SoundCategory.garden,
    label: 'Garden Air',
    icon: '🌼',
    presets: [
      SoundPreset(
        id: 'synth_wind_chimes',
        name: 'Wind Chimes',
        category: SoundCategory.instruments,
        kind: SynthKind.tone,
        baseGain: 0.2,
        lfoHz: 0.5,
        lfoDepth: 0.4,
        toneHz: 660,
        secondToneHz: 990,
        eventRate: 10,
        eventDecay: 0.2,
        eventGain: 0.4,
      ),
      SoundPreset(
        id: 'synth_garden_breeze',
        name: 'Garden Breeze',
        category: SoundCategory.garden,
        kind: SynthKind.noise,
        baseGain: 0.3,
        noiseSmooth: 0.09,
        lowpassHz: 2200,
        highpassHz: 160,
        lfoHz: 0.22,
        lfoDepth: 0.38,
      ),
    ],
  ),
];
