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

// Import your theme helpers
import '../../app_theme.dart'; // adjust path to where buildSereneTheme/glassDecoration/sereneTheme live

// Model/types: point this to the file where SyntheticSoundParams is defined.
// If you keep it in this file, remove this import and keep the model inline.
import '../data/sound_designer_models.dart';

// Macros
import '../../data/sound_macros.dart';


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

class SoundDesignerPage extends StatefulWidget {
  final ValueChanged<SyntheticSoundParams>? onChanged;
  final SyntheticSoundParams? initial;

  const SoundDesignerPage({super.key, this.onChanged, this.initial});

  @override
  State<SoundDesignerPage> createState() => _SoundDesignerPageState();
}

class _SoundDesignerPageState extends State<SoundDesignerPage> {
  final _store = PresetStore();
  final AmbientController _previewController = AmbientController();

  late SyntheticSoundParams _p;

  // Macros (default UX)
  MacroState _m = MacroState.defaults;

  Map<String, SyntheticSoundParams> _saved = {};
  String? _selectedPresetId;
  bool _previewing = false;

  late final TextEditingController _nameCtrl;

  Timer? _previewDebounce;
  Future<void> _previewSerial = Future.value();
  int _previewEpoch = 0;

  int _lastSnackMs = 0;
  bool _showAdvanced = false;

  static const _categories = <String>[
    'Ocean', 'Animal', 'Forest', 'Fire', 'Night', 'Focus', 'Garden',
    'Instrument', 'Pipe', 'Insect', 'Rain', 'Wind', 'Custom',
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
      if (decoded is! Map<String, dynamic>) throw Exception('Invalid JSON structure');

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
    final theme = Theme.of(context);
    final serene = sereneTheme(context);

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
          _sectionTitle('Presets'),
          _glassCard(child: _presetRow()),
          const SizedBox(height: 12),

          _sectionTitle('Quick Controls'),
          _glassCard(child: _macroControls(theme)),
          const SizedBox(height: 12),

          _sectionTitle('Identity'),
          _glassCard(child: _identity(theme)),
          const SizedBox(height: 12),

          _glassCard(
            child: ListTile(
              title: const Text('Advanced Controls'),
              subtitle: const Text('Fine-tune details (optional).'),
              trailing: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            ),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 12),
            _sectionTitle('Mixer'),
            _glassCard(child: _mixer(theme)),
            const SizedBox(height: 12),

            _sectionTitle('Noise'),
            _glassCard(child: _noise(theme)),
            const SizedBox(height: 12),

            _sectionTitle('Tone'),
            _glassCard(child: _tone(theme)),
            const SizedBox(height: 12),

            _sectionTitle('Envelope'),
            _glassCard(child: _envelope(theme)),
            const SizedBox(height: 12),

            _sectionTitle('Filter'),
            _glassCard(child: _filter(theme)),
            const SizedBox(height: 12),

            _sectionTitle('LFO'),
            _glassCard(child: _lfo(theme)),
          ],

          const SizedBox(height: 16),
          _glassCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: _togglePreview,
                    icon: Icon(_previewing ? Icons.stop : Icons.play_arrow),
                    label: Text(_previewing ? 'Stop Preview' : 'Play Preview'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: Start with Quick Controls. Use Advanced only if needed.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _glassCard(
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
          ),

          const SizedBox(height: 24),

          // subtle footer accent
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  serene.heroGradient.colors.first.withOpacity(0.0),
                  serene.heroGradient.colors.first.withOpacity(0.45),
                  serene.heroGradient.colors.last.withOpacity(0.45),
                  serene.heroGradient.colors.last.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI pieces ----------------

  Widget _sectionTitle(String title) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: t.textTheme.titleMedium),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: glassDecoration(context),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _presetRow() {
    final items = _saved.entries.toList()
      ..sort((a, b) => ('${a.value.category} ${a.value.name}')
          .compareTo('${b.value.category} ${b.value.name}'));

    return Row(
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
    );
  }

  Widget _macroControls(ThemeData theme) {
    return Column(
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
          help: 'Lower ↔ higher pitch band.',
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
                label: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _variation,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Variation'),
              ),
            ),
          ],
        ),
      ],
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

  Widget _identity(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _mixer(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _noise(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _tone(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _envelope(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _filter(ThemeData theme) {
    return Column(
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
    );
  }

  Widget _lfo(ThemeData theme) {
    return Column(
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
    );
  }

  // -------------- sliders --------------

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

  // -------------- macros and state updates --------------

  void _setMacros(MacroState next) {
    setState(() => _m = next);
    _set(applyMacrosToParams(_p, _m));
  }

  void _variation() {
    final next = varyMacros(_m, radius: 0.12);
    setState(() => _m = next);
    _set(applyMacrosToParams(_p, _m));
  }

  void _set(SyntheticSoundParams next) {
    setState(() => _p = next);
    _emit();
    _scheduleLivePreviewUpdate();
  }

  // -------------- preview pipeline --------------

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
}
