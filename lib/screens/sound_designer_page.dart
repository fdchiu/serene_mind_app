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
      return MapEntry(k, const SyntheticSoundParams(
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
      ));
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
  /// Provide this callback to apply parameters into your synth engine.
  /// Example:
  ///   onChanged: (p) => engine.applyParams(p);
  final ValueChanged<SyntheticSoundParams>? onChanged;

  /// Optional initial params (e.g. coming from a preset).
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

  // Saved presets (id -> preset)
  Map<String, SyntheticSoundParams> _saved = {};
  String? _selectedPresetId;
  bool _previewing = false;

  // UI categories you mentioned
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

    _loadSaved();
    _emit();
  }

  Future<void> _loadSaved() async {
    final all = await _store.loadAll();
    if (!mounted) return;
    setState(() => _saved = all);
  }

  void _emit() {
    widget.onChanged?.call(_p);
  }

  String _makeId(SyntheticSoundParams p) {
    // stable enough for UI use; if you want strong uniqueness use uuid package
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
    });
    _emit();
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
      });
      _emit();
      _snack('Imported preset: ${preset.category} / ${preset.name}');
    } catch (e) {
      _snack('Import failed: $e');
    }
  }

  @override
  void dispose() {
    unawaited(_previewController.stop());
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Designer'),
        actions: [
          IconButton(
            tooltip: 'Import',
            onPressed: _importPreset,
            icon: const Icon(Icons.file_open),
          ),
          IconButton(
            tooltip: 'Export',
            onPressed: _exportSelected,
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _saveCurrent,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Preset'),
          _presetRow(theme),
          const SizedBox(height: 16),

          _sectionHeader('Identity'),
          _identityCard(),
          const SizedBox(height: 16),

          _sectionHeader('Mixer'),
          _sliderCard([
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
          ]),
          const SizedBox(height: 16),

          _sectionHeader('Noise'),
          _noiseCard(),
          const SizedBox(height: 16),

          _sectionHeader('Tone / Partials'),
          _toneCard(),
          const SizedBox(height: 16),

          _sectionHeader('Envelope'),
          _sliderCard([
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
          ]),
          const SizedBox(height: 16),

          _sectionHeader('Filter'),
          _sliderCard([
            _slider(
              label: 'LP Cutoff (Hz)',
              value: _p.lpCutoff,
              min: 50,
              max: 20000,
              format: (v) => v.toStringAsFixed(0),
              onChanged: (v) => _set(_p.copyWith(lpCutoff: v)),
            ),
            _slider(
              label: 'Resonance (Q)',
              value: _p.lpResonance,
              min: 0.1,
              max: 10,
              format: (v) => v.toStringAsFixed(2),
              onChanged: (v) => _set(_p.copyWith(lpResonance: v)),
            ),
          ]),
          const SizedBox(height: 16),

          _sectionHeader('LFO'),
          _lfoCard(),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _togglePreview,
            icon: Icon(_previewing ? Icons.stop : Icons.play_arrow),
            label: Text(_previewing ? 'Stop Preview' : 'Play Preview'),
          ),
          const SizedBox(height: 8),

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
    );
  }

  Widget _presetRow(ThemeData theme) {
    final items = _saved.entries.toList()
      ..sort((a, b) => ('${a.value.category} ${a.value.name}')
          .compareTo('${b.value.category} ${b.value.name}'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPresetId,
                decoration: const InputDecoration(
                  labelText: 'Saved presets',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('— None —'),
                  ),
                  ...items.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.key,
                      child: Text('${e.value.category} / ${e.value.name}'),
                    );
                  }),
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
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => _set(_p.copyWith(category: v ?? 'Custom')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _p.name,
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

  Widget _noiseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<NoiseColor>(
              value: _p.noiseColor,
              decoration: const InputDecoration(
                labelText: 'Noise color',
                border: OutlineInputBorder(),
              ),
              items: NoiseColor.values
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.name),
              ))
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
      ),
    );
  }

  Widget _toneCard() {
    return _sliderCard([
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
    ]);
  }

  Widget _lfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<LfoTarget>(
              value: _p.lfoTarget,
              decoration: const InputDecoration(
                labelText: 'LFO target',
                border: OutlineInputBorder(),
              ),
              items: LfoTarget.values
                  .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name),
              ))
                  .toList(),
              onChanged: (v) => _set(_p.copyWith(lfoTarget: v)),
            ),
            const SizedBox(height: 12),
            _slider(
              label: 'LFO Rate (Hz)',
              value: _p.lfoRate,
              min: 0,
              max: 10,
              format: (v) => v.toStringAsFixed(2),
              onChanged: (v) => _set(_p.copyWith(lfoRate: v)),
            ),
            _slider(
              label: 'LFO Depth',
              value: _p.lfoDepth,
              min: 0,
              max: 1,
              format: (v) => v.toStringAsFixed(2),
              onChanged: (v) => _set(_p.copyWith(lfoDepth: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _sliderCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(format(value), style: const TextStyle(fontFeatures: [])),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$value'),
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

  Future<void> _togglePreview() async {
    if (_previewing) {
      await _stopPreview();
    } else {
      await _startPreview();
    }
  }

  Future<void> _startPreview() async {
    try {
      final preset = _buildPreviewPreset(_p);
      await _previewController.play(preset);
      _previewController.setMuted(false);
      _previewController.setVolume(_p.masterGain.clamp(0.1, 1.0));
      if (!mounted) return;
      setState(() => _previewing = true);
    } catch (e) {
      _snack('Could not start preview: $e');
      await _previewController.stop();
      if (mounted) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _stopPreview() async {
    await _previewController.stop();
    if (!mounted) return;
    setState(() => _previewing = false);
  }

  Future<void> _applyLivePreview() async {
    if (!_previewing) return;
    await _previewController.stop();
    if (!mounted) return;
    await _startPreview();
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
    final toneHz = kind == SynthKind.noise
        ? null
        : params.baseFreq.clamp(40.0, 2000.0);
    final detuneRatio = math.pow(2, params.detuneCents / 1200.0).toDouble();
    final secondToneHz =
        toneHz == null ? null : (toneHz * detuneRatio).clamp(40.0, 2400.0);

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
    if (normalized.contains('forest') || normalized.contains('garden')) {
      return SoundCategory.forest;
    }
    if (normalized.contains('fire')) return SoundCategory.fire;
    if (normalized.contains('night') || normalized.contains('insect')) {
      return SoundCategory.night;
    }
    if (normalized.contains('focus')) return SoundCategory.focus;
    if (normalized.contains('pipe')) return SoundCategory.pipes;
    if (normalized.contains('instrument')) {
      return SoundCategory.instruments;
    }
    if (normalized.contains('rain') || normalized.contains('weather')) {
      return SoundCategory.weather;
    }
    if (normalized.contains('wind')) return SoundCategory.weather;
    return SoundCategory.weather;
  }

  void _set(SyntheticSoundParams next) {
    setState(() => _p = next);
    _emit();
    unawaited(_applyLivePreview());
  }
}
