import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ambient_controller.dart';
import '../data/sound_preset.dart';

/// -------------------------------
/// Model
/// -------------------------------

// --- Add near the top of the file (below enums), or inside the State class file scope.

class MacroState {
  final double intensity; // 0..1
  final double warmth;    // 0..1 (darker -> brighter)
  final double movement;  // 0..1
  final double texture;   // 0..1 (noise -> tone)
  final double tone;      // 0..1 (low -> high pitch)

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

/// Category-aware macro mapping.
/// - Keeps changes safe and perceptual.
/// - Does not try to be "perfect synthesis"; the goal is usability.
SyntheticSoundParams applyMacrosToParams(
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
}

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

/// -------------------------------
/// Storage (SharedPreferences)
/// -------------------------------

class PresetStore {
  static const _key = 'synthetic_sound_presets_v1';

  Future<Map<String, SyntheticSoundParams>> loadAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    return decoded.map((k, v) {
      if (v is Map<String, dynamic>) {
        return MapEntry(k, SyntheticSoundParams.fromJson(v));
      }
      return MapEntry(
        k,
        const SyntheticSoundParams(
          category: 'Custom',
          name: 'Corrupt',
          noiseMix: 0.7,
          toneMix: 0.3,
          masterGain: 0.6,
          baseFreq: 180,
          detuneCents: 0,
          partialCount: 3,
          partialSpread: 0.25,
          attack: 0.05,
          release: 1.2,
          lpCutoff: 2200,
          lpResonance: 0.7,
          lfoRate: 0.25,
          lfoDepth: 0.25,
          lfoTarget: LfoTarget.cutoff,
          noiseColor: NoiseColor.white,
          noiseFlutter: 0.15,
        ),
      );
    });
  }

  Future<void> upsert(String id, SyntheticSoundParams params) async {
    final all = await loadAll();
    all[id] = params;
    await _saveAll(all);
  }

  Future<void> remove(String id) async {
    final all = await loadAll();
    all.remove(id);
    await _saveAll(all);
  }

  Future<void> _saveAll(Map<String, SyntheticSoundParams> all) async {
    final sp = await SharedPreferences.getInstance();
    final map = all.map((k, v) => MapEntry(k, v.toJson()));
    await sp.setString(_key, jsonEncode(map));
  }
}

/// -------------------------------
/// UI Page
/// -------------------------------

class SoundDesignerPage extends StatefulWidget {
  final ValueChanged<SyntheticSoundParams>? onChanged;
  final SyntheticSoundParams? initial;

  const SoundDesignerPage({
    super.key,
    this.onChanged,
    this.initial,
  });

  @override
  State<SoundDesignerPage> createState() => _SoundDesignerPageState();
}

class _SoundDesignerPageState extends State<SoundDesignerPage> {
  final _store = PresetStore();
  final AmbientController _previewController = AmbientController();

  late SyntheticSoundParams _p;

  // Macros
  MacroState _m = MacroState.defaults;

  Map<String, SyntheticSoundParams> _saved = {};
  String? _selectedPresetId;
  bool _previewing = false;

  late final TextEditingController _nameCtrl;

  Timer? _previewDebounce;
  Future<void> _previewSerial = Future.value();
  int _previewEpoch = 0;

  int _lastSnackMs = 0;

  // Advanced collapsed state
  bool _showAdvanced = false;

  static const _categories = <String>[
    'Ocean',
    'Animal',
    'Forest',
    'Fire',
    'Night',
    'Focus',
    'Garden',
    'Instrument',
    'Pipe',
    'Insect',
    'Rain',
    'Wind',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();

    _p = widget.initial ??
        const SyntheticSoundParams(
          category: 'Ocean',
          name: 'Deep Ocean',
          noiseMix: 0.75,
          toneMix: 0.25,
          masterGain: 0.60,
          baseFreq: 160.0,
          detuneCents: -3.0,
          partialCount: 3,
          partialSpread: 0.25,
          attack: 0.05,
          release: 1.25,
          lpCutoff: 1600.0,
          lpResonance: 0.7,
          lfoRate: 0.18,
          lfoDepth: 0.25,
          lfoTarget: LfoTarget.cutoff,
          noiseColor: NoiseColor.pink,
          noiseFlutter: 0.18,
        );

    _nameCtrl = TextEditingController(text: _p.name);

    _loadSaved();
    _emit();
  }

  Future<void> _loadSaved() async {
    final all = await _store.loadAll();
    if (!mounted) return;
    setState(() => _saved = all);
  }

  void _emit() => widget.onChanged?.call(_p);

  String _makeId(SyntheticSoundParams p) {
    final safeName = p.name.trim().isEmpty ? 'Untitled' : p.name.trim();
    return '${p.category}::$safeName';
  }

  Future<void> _saveCurrent() async {
    final id = _makeId(_p);
    await _store.upsert(id, _p);
    await _loadSaved();
    if (!mounted) return;
    setState(() => _selectedPresetId = id);
    _snack('Saved preset: ${_p.category} / ${_p.name}');
  }

  Future<void> _deleteSelected() async {
    final id = _selectedPresetId;
    if (id == null) return;
    await _store.remove(id);
    await _loadSaved();
    if (!mounted) return;
    setState(() => _selectedPresetId = null);
    _snack('Deleted preset.');
  }

  void _applyPreset(String id) {
    final preset = _saved[id];
    if (preset == null) return;
    setState(() {
      _selectedPresetId = id;
      _p = preset;
      _nameCtrl.text = preset.name;
    });
    _emit();
    _scheduleLivePreviewUpdate();
  }

  Future<void> _exportSelected() async {
    final id = _selectedPresetId;
    final preset = (id != null) ? _saved[id] : null;
    if (preset == null) {
      _snack('Select a preset to export.');
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(preset.toJson());
    final dir = await getTemporaryDirectory();
    final fileName =
    'preset_${preset.category}_${preset.name}'.replaceAll(RegExp(r'\s+'), '_');
    final file = File('${dir.path}/$fileName.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Synthetic sound preset: ${preset.category} / ${preset.name}',
    );
  }

  Future<void> _importPreset() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    try {
      final bytes = res.files.single.bytes;
      final path = res.files.single.path;
      final content = bytes != null
          ? utf8.decode(bytes)
          : (path != null ? await File(path).readAsString() : null);
      if (content == null) throw Exception('Empty file');

      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid JSON structure');
      }
      final preset = SyntheticSoundParams.fromJson(decoded);

      final id = _makeId(preset);
      await _store.upsert(id, preset);
      await _loadSaved();

      if (!mounted) return;
      setState(() {
        _selectedPresetId = id;
        _p = preset;
        _nameCtrl.text = preset.name;
      });
      _emit();
      _scheduleLivePreviewUpdate();
      _snack('Imported preset: ${preset.category} / ${preset.name}');
    } catch (e) {
      _snack('Import failed: $e');
    }
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _previewEpoch++;
    unawaited(_previewController.stop());
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSnackMs < 600) return;
    _lastSnackMs = now;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Designer'),
        actions: [
          IconButton(tooltip: 'Import', onPressed: _importPreset, icon: const Icon(Icons.file_open)),
          IconButton(tooltip: 'Export', onPressed: _exportSelected, icon: const Icon(Icons.ios_share)),
          IconButton(tooltip: 'Save', onPressed: _saveCurrent, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardSectionTitle(context, 'Presets'),
          _presetCard(),
          const SizedBox(height: 12),

          _cardSectionTitle(context, 'Quick Controls'),
          _macroCard(t),
          const SizedBox(height: 12),

          _cardSectionTitle(context, 'Identity'),
          _identityCard(),
          const SizedBox(height: 12),

          _advancedHeaderCard(),
          if (_showAdvanced) ...[
            const SizedBox(height: 12),
            _expansionCard(
              title: 'Mixer',
              children: [
                _slider(
                  label: 'Master Gain',
                  value: _p.masterGain,
                  min: 0,
                  max: 1,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(masterGain: v)),
                ),
                _slider(
                  label: 'Noise Mix',
                  value: _p.noiseMix,
                  min: 0,
                  max: 1,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(noiseMix: v)),
                ),
                _slider(
                  label: 'Tone Mix',
                  value: _p.toneMix,
                  min: 0,
                  max: 1,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(toneMix: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _expansionCard(
              title: 'Noise',
              children: [
                DropdownButtonFormField<NoiseColor>(
                  value: _p.noiseColor,
                  decoration: const InputDecoration(
                    labelText: 'Noise color',
                    border: OutlineInputBorder(),
                  ),
                  items: NoiseColor.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => _set(_p.copyWith(noiseColor: v)),
                ),
                const SizedBox(height: 12),
                _slider(
                  label: 'Noise Flutter',
                  value: _p.noiseFlutter,
                  min: 0,
                  max: 1,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(noiseFlutter: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _expansionCard(
              title: 'Tone / Partials',
              children: [
                _slider(
                  label: 'Base Frequency (Hz)',
                  value: _p.baseFreq,
                  min: 40,
                  max: 1200,
                  format: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => _set(_p.copyWith(baseFreq: v)),
                ),
                _slider(
                  label: 'Detune (cents)',
                  value: _p.detuneCents,
                  min: -50,
                  max: 50,
                  format: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => _set(_p.copyWith(detuneCents: v)),
                ),
                _intSlider(
                  label: 'Partial Count',
                  value: _p.partialCount,
                  min: 1,
                  max: 8,
                  onChanged: (v) => _set(_p.copyWith(partialCount: v)),
                ),
                _slider(
                  label: 'Partial Spread',
                  value: _p.partialSpread,
                  min: 0,
                  max: 1,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(partialSpread: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _expansionCard(
              title: 'Envelope',
              children: [
                _slider(
                  label: 'Attack (s)',
                  value: _p.attack,
                  min: 0,
                  max: 2,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(attack: v)),
                ),
                _slider(
                  label: 'Release (s)',
                  value: _p.release,
                  min: 0,
                  max: 5,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(release: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _expansionCard(
              title: 'Filter',
              children: [
                _slider(
                  label: 'Brightness (LP Cutoff)',
                  value: _p.lpCutoff,
                  min: 50,
                  max: 20000,
                  format: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => _set(_p.copyWith(lpCutoff: v)),
                ),
                _slider(
                  label: 'Edge (Resonance)',
                  value: _p.lpResonance,
                  min: 0.1,
                  max: 10,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(lpResonance: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _expansionCard(
              title: 'LFO',
              children: [
                DropdownButtonFormField<LfoTarget>(
                  value: _p.lfoTarget,
                  decoration: const InputDecoration(
                    labelText: 'LFO target',
                    border: OutlineInputBorder(),
                  ),
                  items: LfoTarget.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => _set(_p.copyWith(lfoTarget: v)),
                ),
                const SizedBox(height: 12),
                _slider(
                  label: 'Wobble Rate (Hz)',
                  value: _p.lfoRate,
                  min: 0,
                  max: 10,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(lfoRate: v)),
                ),
                _slider(
                  label: 'Wobble Depth',
                  value: _p.lfoDepth,
                  min: 0,
                  max: 1,
                  format: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => _set(_p.copyWith(lfoDepth: v)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _previewCard(),
          const SizedBox(height: 16),

          // Secondary actions
          _actionsCard(),
        ],
      ),
    );
  }

  Widget _cardSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _presetCard() {
    final items = _saved.entries.toList()
      ..sort((a, b) => ('${a.value.category} ${a.value.name}')
          .compareTo('${b.value.category} ${b.value.name}'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedPresetId,
                decoration: const InputDecoration(
                  labelText: 'Saved presets',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('— None —')),
                  ...items.map((e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text('${e.value.category} / ${e.value.name}'),
                  )),
                ],
                onChanged: (v) {
                  if (v == null) {
                    setState(() => _selectedPresetId = null);
                    return;
                  }
                  _applyPreset(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Delete selected',
              onPressed: _selectedPresetId == null ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroCard(ThemeData theme) {
    // Apply button is optional; I prefer immediate apply with debounce.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _macroSlider(
              label: 'Intensity',
              value: _m.intensity,
              help: 'Overall strength and loudness.',
              onChanged: (v) => _setMacros(_m.copyWith(intensity: v)),
            ),
            _macroSlider(
              label: 'Warmth',
              value: _m.warmth,
              help: 'Darker ↔ brighter tone.',
              onChanged: (v) => _setMacros(_m.copyWith(warmth: v)),
            ),
            _macroSlider(
              label: 'Movement',
              value: _m.movement,
              help: 'How alive and evolving it feels.',
              onChanged: (v) => _setMacros(_m.copyWith(movement: v)),
            ),
            _macroSlider(
              label: 'Texture',
              value: _m.texture,
              help: 'Noise ↔ tone balance.',
              onChanged: (v) => _setMacros(_m.copyWith(texture: v)),
            ),
            _macroSlider(
              label: 'Tone',
              value: _m.tone,
              help: 'Lower ↔ higher pitch region.',
              onChanged: (v) => _setMacros(_m.copyWith(tone: v)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _m = MacroState.defaults);
                      _set(applyMacrosToParams(_p, _m));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset macros'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _randomVariation,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Variation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroSlider({
    required String label,
    required double value,
    required String help,
    required ValueChanged<double> onChanged,
  }) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: t.textTheme.titleSmall)),
              Text(value.toStringAsFixed(2), style: t.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 2),
          Text(help, style: t.textTheme.bodySmall),
          Slider(value: value, min: 0, max: 1, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _identityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _categories.contains(_p.category) ? _p.category : 'Custom',
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                final next = _p.copyWith(category: v ?? 'Custom');
                // When category changes, re-apply macros to get category-aware defaults.
                _set(applyMacrosToParams(next, _m));
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Preset name',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _set(_p.copyWith(name: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _advancedHeaderCard() {
    return Card(
      child: ListTile(
        title: const Text('Advanced Controls'),
        subtitle: const Text('Fine-tune the sound. Most users won’t need this.'),
        trailing: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
        onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      ),
    );
  }

  Widget _expansionCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _previewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _togglePreview,
                    icon: Icon(_previewing ? Icons.stop : Icons.play_arrow),
                    label: Text(_previewing ? 'Stop Preview' : 'Play Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Mute',
                  onPressed: () {
                    // Toggle mute quickly (UI-state-free; use controller state if you want)
                    _previewController.setMuted(false);
                    _snack('Preview is unmuted.');
                  },
                  icon: const Icon(Icons.volume_up),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Use Quick Controls for most adjustments. Advanced is for precision.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            FilledButton.icon(
              onPressed: _saveCurrent,
              icon: const Icon(Icons.save),
              label: const Text('Save Preset'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _importPreset,
              icon: const Icon(Icons.file_open),
              label: const Text('Import Preset (.json)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _exportSelected,
              icon: const Icon(Icons.ios_share),
              label: const Text('Export Selected Preset'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // Setters: macros + params
  // ----------------------------

  void _setMacros(MacroState next) {
    setState(() => _m = next);
    _set(applyMacrosToParams(_p, _m));
  }

  void _randomVariation() {
    // Small, safe random walk around current macros.
    final r = math.Random();
    double bump(double v, double radius) => (v + (r.nextDouble() * 2 - 1) * radius).clamp(0.0, 1.0);

    final next = _m.copyWith(
      intensity: bump(_m.intensity, 0.10),
      warmth: bump(_m.warmth, 0.12),
      movement: bump(_m.movement, 0.12),
      texture: bump(_m.texture, 0.12),
      tone: bump(_m.tone, 0.12),
    );

    setState(() => _m = next);
    _set(applyMacrosToParams(_p, _m));
  }

  void _set(SyntheticSoundParams next) {
    setState(() => _p = next);
    _emit();
    _scheduleLivePreviewUpdate();
  }

  // ----------------------------
  // Preview pipeline (your existing logic preserved)
  // ----------------------------

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _stopPreview();
    } else {
      await _startPreview();
    }
  }

  Future<void> _startPreview() async {
    _previewEpoch++;
    try {
      await _playPreviewWithCurrentParams();
      if (!mounted) return;
      setState(() => _previewing = true);
    } catch (e) {
      _snack('Could not start preview: $e');
      await _previewController.stop();
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _stopPreview() async {
    _previewEpoch++;
    _previewDebounce?.cancel();
    await _previewController.stop();
    if (!mounted) return;
    setState(() => _previewing = false);
  }

  void _scheduleLivePreviewUpdate() {
    if (!_previewing) return;
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(_applyLivePreviewQueued());
    });
  }

  Future<void> _applyLivePreviewQueued() async {
    if (!_previewing) return;
    final int myEpoch = ++_previewEpoch;

    _previewSerial = _previewSerial.then((_) async {
      if (!mounted) return;
      if (!_previewing) return;
      if (myEpoch != _previewEpoch) return;

      try {
        await _playPreviewWithCurrentParams();
      } catch (e) {
        final errorStr = 'Could not update preview: $e';
        debugPrint(errorStr);
        _snack(errorStr);

        await _previewController.stop();
        if (mounted) setState(() => _previewing = false);
      }
    });

    return _previewSerial;
  }

  Future<void> _playPreviewWithCurrentParams() async {
    final preset = _buildPreviewPreset(_p);
    await _previewController.apply(preset);
    _previewController.setMuted(false);
    _previewController.setVolume(_p.masterGain.clamp(0.1, 1.0));
  }

  SoundPreset _buildPreviewPreset(SyntheticSoundParams params) {
    final category = _mapCategory(params.category);
    final kind = params.toneMix < 0.15
        ? SynthKind.noise
        : (params.noiseMix < 0.15 ? SynthKind.tone : SynthKind.hybrid);

    final baseGain = params.masterGain.clamp(0.05, 0.9).toDouble();
    final noiseSmooth =
    (0.02 + (1 - params.noiseMix).clamp(0.0, 1.0) * 0.18).toDouble();
    final lowpassHz = params.lpCutoff.clamp(200, 19000).toDouble();
    final highpassHz = params.baseFreq * 0.1;
    final lfoHz = params.lfoRate.clamp(0.05, 8.0).toDouble();
    final lfoDepth = params.lfoDepth.clamp(0.0, 1.0).toDouble();
    final eventRate = (params.noiseFlutter * 30).clamp(0.0, 30.0).toDouble();
    final eventDecay =
    (0.015 + ((params.attack + params.release) / 6.0).clamp(0.0, 0.2))
        .toDouble();
    final eventGain = (params.noiseFlutter * 0.35).clamp(0.0, 0.6).toDouble();
    final toneHz = kind == SynthKind.noise ? null : params.baseFreq.clamp(40.0, 2000.0);
    final detuneRatio = math.pow(2, params.detuneCents / 1200.0).toDouble();
    final secondToneHz = toneHz == null ? null : (toneHz * detuneRatio).clamp(40.0, 2400.0);

    return SoundPreset(
      id: 'custom_preview',
      name: params.name,
      category: category,
      kind: kind,
      baseGain: baseGain,
      noiseSmooth: noiseSmooth,
      lowpassHz: lowpassHz,
      highpassHz: highpassHz,
      lfoHz: lfoHz,
      lfoDepth: lfoDepth,
      eventRate: eventRate,
      eventDecay: eventDecay,
      eventGain: eventGain,
      toneHz: toneHz,
      secondToneHz: secondToneHz,
    );
  }

  SoundCategory _mapCategory(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('ocean')) return SoundCategory.ocean;
    if (normalized.contains('animal')) return SoundCategory.animals;
    if (normalized.contains('forest') || normalized.contains('garden')) return SoundCategory.forest;
    if (normalized.contains('fire')) return SoundCategory.fire;
    if (normalized.contains('night') || normalized.contains('insect')) return SoundCategory.night;
    if (normalized.contains('focus')) return SoundCategory.focus;
    if (normalized.contains('pipe')) return SoundCategory.pipes;
    if (normalized.contains('instrument')) return SoundCategory.instruments;
    if (normalized.contains('rain') || normalized.contains('weather')) return SoundCategory.weather;
    if (normalized.contains('wind')) return SoundCategory.weather;
    return SoundCategory.weather;
  }

  // ----------------------------
  // Slider widgets (theme-consistent)
  // ----------------------------

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: t.textTheme.bodyMedium)),
              Text(format(value), style: t.textTheme.bodySmall),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _intSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: t.textTheme.bodyMedium)),
              Text('$value', style: t.textTheme.bodySmall),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min),
            label: '$value',
            onChanged: (v) => onChanged(v.round().clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

