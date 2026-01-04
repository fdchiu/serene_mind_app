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
        baseGain: 0.32,
        noiseSmooth: 0.12,
        lowpassHz: 3600,
        lfoHz: 5.0,
        lfoDepth: 0.2,
        eventRate: 24,
        eventDecay: 0.03,
        eventGain: 0.08,
      ),
      SoundPreset(
        id: 'synth_rainstorm',
        name: 'Rainstorm',
        category: SoundCategory.weather,
        kind: SynthKind.hybrid,
        baseGain: 0.42,
        noiseSmooth: 0.08,
        lowpassHz: 2800,
        lfoHz: 0.25,
        lfoDepth: 0.65,
        eventRate: 8,
        eventDecay: 0.04,
        eventGain: 0.25,
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
        baseGain: 0.45,
        noiseSmooth: 0.04,
        lowpassHz: 1400,
        highpassHz: 60,
        lfoHz: 0.1,
        lfoDepth: 0.85,
      ),
      SoundPreset(
        id: 'synth_shoreline',
        name: 'Shoreline Wind',
        category: SoundCategory.ocean,
        kind: SynthKind.hybrid,
        baseGain: 0.38,
        noiseSmooth: 0.06,
        lowpassHz: 1800,
        lfoHz: 0.35,
        lfoDepth: 0.55,
        eventRate: 5,
        eventDecay: 0.05,
        eventGain: 0.2,
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
        baseGain: 0.26,
        noiseSmooth: 0.12,
        lowpassHz: 2500,
        lfoHz: 0.18,
        lfoDepth: 0.35,
        eventRate: 18,
        eventDecay: 0.1,
        eventGain: 0.28,
        chirpMix: 0.6,
      ),
      const SoundPreset(
        id: 'morning_birds',
        name: 'Morning Birds 2',
        category: SoundCategory.forest,
        kind: SynthKind.hybrid,
        baseGain: 0.28, // moderate loudness
        noiseSmooth: 0.10, // light texture under chirps
        lowpassHz: 3200, // keep brightness for chirps
        highpassHz: 320, // thin out low rumble
        lfoHz: 0.22, // gentle motion
        lfoDepth: 0.28,
        eventRate: 0.8, // sparse calls
        eventDecay: 0.18, // chirp tail
        eventGain: 0.30, // audible but not spiky
        chirpMix: 0.85,
      ),
      SoundPreset(
        id: 'synth_forest_breeze',
        name: 'Forest Breeze',
        category: SoundCategory.forest,
        kind: SynthKind.noise,
        baseGain: 0.3,
        noiseSmooth: 0.15,
        lowpassHz: 2200,
        lfoHz: 0.12,
        lfoDepth: 0.25,
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
        baseGain: 0.34,
        noiseSmooth: 0.07,
        lowpassHz: 1800,
        highpassHz: 120,
        lfoHz: 0.3,
        lfoDepth: 0.3,
        eventRate: 15,
        eventDecay: 0.04,
        eventGain: 0.32,
      ),
      SoundPreset(
        id: 'synth_embers',
        name: 'Glowing Embers',
        category: SoundCategory.fire,
        kind: SynthKind.hybrid,
        baseGain: 0.25,
        noiseSmooth: 0.09,
        lowpassHz: 1500,
        lfoHz: 0.4,
        lfoDepth: 0.4,
        eventRate: 22,
        eventDecay: 0.02,
        eventGain: 0.4,
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
        baseGain: 0.2,
        noiseSmooth: 0.16,
        lowpassHz: 1600,
        lfoHz: 0.12,
        lfoDepth: 0.12,
        eventRate: 28,
        eventDecay: 0.05,
        eventGain: 0.22,
        chirpMix: 0.75,
      ),
      const SoundPreset(
        id: 'crickets_v2',
        name: 'Crickets',
        category: SoundCategory.night,
        kind: SynthKind.hybrid,
        baseGain: 0.24,
        noiseSmooth: 0.06, // brighter hiss
        lowpassHz: 5200, // very open top end
        highpassHz: 620, // thin, bright timbre
        lfoHz: 0.28,
        lfoDepth: 0.14,
        eventRate: 10.0, // rapid ticks
        eventDecay: 0.04, // very short chirps
        eventGain: 0.26, // ensure ticks are audible
        chirpMix: 0.9,
      ),

      SoundPreset(
        id: 'synth_insects',
        name: 'Night Insects',
        category: SoundCategory.insects,
        kind: SynthKind.noise,
        baseGain: 0.18,
        noiseSmooth: 0.18,
        lowpassHz: 2000,
        lfoHz: 0.2,
        lfoDepth: 0.18,
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
        baseGain: 0.28,
        noiseSmooth: 0.1,
        lowpassHz: 2000,
        lfoHz: 0.18,
        lfoDepth: 0.32,
      ),
    ],
  ),
];
