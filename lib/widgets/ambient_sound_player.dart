import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../app_theme.dart';
import '../data/ambient_controller.dart';
import '../data/ambient_sounds.dart';
import '../data/sound_preset.dart';
import '../data/adaptive_soundscape_controller.dart';
import '../soundscape_engine/engine_types.dart';
import '../services/pixabay_proxy_client.dart';

enum AmbientAudioSource { recordings, synth, adaptive }

class AmbientSoundPlayerController {
  _AmbientSoundPlayerState? _state;

  Future<void> stop() async {
    final state = _state;
    if (state != null) {
      await state._stopAll();
    }
  }

  void _attach(_AmbientSoundPlayerState state) {
    _state = state;
  }

  void _detach(_AmbientSoundPlayerState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

class AmbientSoundPlayer extends StatefulWidget {
  const AmbientSoundPlayer({
    super.key,
    this.compact = false,
    this.controller,
  });

  final bool compact;
  final AmbientSoundPlayerController? controller;

  @override
  State<AmbientSoundPlayer> createState() => _AmbientSoundPlayerState();
}

class _AmbientSoundPlayerState extends State<AmbientSoundPlayer> {
  final AudioPlayer _player = AudioPlayer();
  final AmbientController _synthController = AmbientController();
  final AdaptiveSoundscapeController _adaptiveController =
  AdaptiveSoundscapeController();

  AmbientAudioSource _source = AmbientAudioSource.synth;

  AmbientSoundCategory? _activeCategory;
  AmbientTrack? _activeTrack;

  SoundPresetCollection? _activePresetCollection;
  SoundPreset? _activePreset;

  double _volume = 0.5;
  bool _muted = false;

  String? _loadingTrackId;
  bool _synthLoading = false;
  String? _error;

  Directory? _cacheDir;
  late final PixabayProxyClient _proxyClient;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _player.setReleaseMode(ReleaseMode.loop);
    _proxyClient = PixabayProxyClient();
  }

  @override
  void didUpdateWidget(covariant AmbientSoundPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _player.dispose();
    _synthController.stop();
    _adaptiveController.stop();
    super.dispose();
  }

  Future<void> _stopAll() async {
    await _player.stop();
    await _synthController.stop();
    await _adaptiveController.stop();
    if (!mounted) return;
    setState(() {
      _activeCategory = null;
      _activeTrack = null;
      _activePresetCollection = null;
      _activePreset = null;
      _loadingTrackId = null;
      _synthLoading = false;
      _error = null;
    });
  }

  Future<void> _switchSource(AmbientAudioSource source) async {
    if (_source == source) return;

    setState(() {
      _source = source;
      _error = null;

      // Clear selection state; each source manages its own selection
      _activeCategory = null;
      _activeTrack = null;
      _activePresetCollection = null;
      _activePreset = null;

      _loadingTrackId = null;
      _synthLoading = false;
    });

    // Always stop all pipelines when switching source.
    await _player.stop();
    await _synthController.stop();
    await _adaptiveController.stop();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleCategoryTap(AmbientSoundCategory category) async {
    if (_activeCategory?.id == category.id) {
      await _player.stop();
      setState(() {
        _activeCategory = null;
        _activeTrack = null;
        _error = null;
      });
      return;
    }

    final track = category.tracks.length == 1
        ? category.tracks.first
        : await _showTrackPicker(category);
    if (track == null) return;
    await _startPlayback(category, track);
  }

  Future<void> _handlePresetCollectionTap(SoundPresetCollection collection) async {
    if (_activePresetCollection?.category == collection.category) {
      await _synthController.stop();
      setState(() {
        _activePresetCollection = null;
        _activePreset = null;
        _error = null;
        _synthLoading = false;
      });
      return;
    }

    final preset = collection.presets.length == 1
        ? collection.presets.first
        : await _showPresetPicker(collection);
    if (preset == null) return;
    await _startSynthPlayback(collection, preset);
  }

  Future<void> _startAdaptive(SoundscapeMode mode) async {
    setState(() {
      _error = null;

      // Clear other selection state
      _activeCategory = null;
      _activeTrack = null;
      _activePresetCollection = null;
      _activePreset = null;

      _loadingTrackId = null;
      _synthLoading = false;
    });

    try {
      await _player.stop();
      await _synthController.stop();

      await _adaptiveController.start(mode);
      _adaptiveController.setMuted(_muted);
      _adaptiveController.setVolume(_volume);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to start adaptive soundscape: $e';
      });
    }
  }

  Future<Directory> _cacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final baseDir = await getTemporaryDirectory();
    final dir = Directory('${baseDir.path}/ambient_audio_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  Future<File?> _downloadTrack(AmbientTrack track) async {
    final dir = await _cacheDirectory();
    final file = File('${dir.path}/${track.id}.mp3');
    if (await file.exists()) return file;

    final sourceUri = Uri.parse(track.url);
    final uri = _proxyClient.rewriteIfPixabay(sourceUri);
    final client = http.Client();
    try {
      // Pixabay CDN can return 403s when a user agent / referrer is missing.
      final response = await client.get(
        uri,
        headers: const {
          'User-Agent': 'SereneMind/1.0 (+https://serenemind.app)',
          'Referer': 'https://pixabay.com/',
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to download ${track.id}: $error\n$stackTrace');
    } finally {
      client.close();
    }
    return null;
  }

  Future<void> _startPlayback(AmbientSoundCategory category, AmbientTrack track) async {
    setState(() {
      _loadingTrackId = track.id;
      _error = null;

      _activeCategory = category;
      _activeTrack = null;

      // Clear synth + adaptive selection
      _activePresetCollection = null;
      _activePreset = null;
      _synthLoading = false;
    });

    await _synthController.stop();
    await _adaptiveController.stop();

    final file = await _downloadTrack(track);
    if (!mounted) return;

    if (file == null) {
      setState(() {
        _loadingTrackId = null;
        _error = 'Unable to load audio. Check your connection and try again.';
      });
      return;
    }

    await _player.stop();
    await _player.setSource(DeviceFileSource(file.path));
    await _player.setVolume(_muted ? 0 : _volume);
    await _player.resume();

    setState(() {
      _activeCategory = category;
      _activeTrack = track;
      _loadingTrackId = null;
    });
  }

  Future<void> _startSynthPlayback(SoundPresetCollection collection, SoundPreset preset) async {
    setState(() {
      _synthLoading = true;
      _error = null;

      _activePresetCollection = collection;
      _activePreset = null;

      // Clear recordings + adaptive selection
      _activeCategory = null;
      _activeTrack = null;
      _loadingTrackId = null;
    });

    try {
      await _player.stop();
      await _adaptiveController.stop();

      await _synthController.play(preset);
      _synthController.setVolume(_muted ? 0 : _volume);
      _synthController.setMuted(_muted);

      if (!mounted) return;
      setState(() {
        _activePreset = preset;
        _synthLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _synthLoading = false;
        _error = 'Unable to start synth: $error';
        _activePresetCollection = null;
        _activePreset = null;
      });
    }
  }

  Future<AmbientTrack?> _showTrackPicker(AmbientSoundCategory category) {
    return showModalBottomSheet<AmbientTrack>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a ${category.label} track',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a track to start looping it.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ...category.tracks.map(
                    (track) => ListTile(
                  leading: Text(category.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(track.title),
                  subtitle: Text(
                    track.durationLabel != null
                        ? '${track.durationLabel} • pixabay.com'
                        : 'pixabay.com',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: _activeTrack?.id == track.id
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(track),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<SoundPreset?> _showPresetPicker(SoundPresetCollection collection) {
    return showModalBottomSheet<SoundPreset>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a ${collection.label} tone',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Procedural audio plays forever without downloading files.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ...collection.presets.map(
                    (preset) => ListTile(
                  leading: Text(collection.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(preset.name),
                  subtitle: Text(
                    preset.category.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: _activePreset?.id == preset.id
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(preset),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateVolume(double value) async {
    setState(() => _volume = value);
    if (!_muted) {
      await _player.setVolume(value);
      _synthController.setVolume(value);
      _adaptiveController.setVolume(value);
    }
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _player.setVolume(_muted ? 0 : _volume);
    _synthController.setMuted(_muted);
    _adaptiveController.setMuted(_muted);
  }

  @override
  Widget build(BuildContext context) {
    final baseDecoration = glassDecoration(context);

    final isRecordings = _source == AmbientAudioSource.recordings;
    final isSynth = _source == AmbientAudioSource.synth;
    final isAdaptive = _source == AmbientAudioSource.adaptive;

    final items = switch (_source) {
      AmbientAudioSource.synth => _buildSynthTiles(baseDecoration),
      AmbientAudioSource.recordings => _buildRecordingTiles(baseDecoration),
      AmbientAudioSource.adaptive => _buildAdaptiveTiles(baseDecoration),
    };

    final isLoading = isRecordings ? _loadingTrackId != null : (isSynth ? _synthLoading : false);

    final hasActive = isRecordings
        ? _activeTrack != null
        : isSynth
        ? _activePresetCollection != null
        : _adaptiveController.isPlaying;

    final activeText = isRecordings
        ? (_activeTrack != null
        ? '${_activeTrack!.title}${_activeTrack?.durationLabel != null ? ' • ${_activeTrack!.durationLabel}' : ''}'
        : null)
        : isSynth
        ? (_activePreset != null ? '${_activePreset!.name} • ${_activePresetCollection?.label}' : null)
        : (_adaptiveController.isPlaying ? 'Adaptive • ${_adaptiveController.mode.name}' : null);

    final sliderEnabled = hasActive && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<AmbientAudioSource>(
          segments: const [
            ButtonSegment(
              value: AmbientAudioSource.synth,
              icon: Icon(Icons.memory),
              label: Text('Synth'),
            ),
            ButtonSegment(
              value: AmbientAudioSource.adaptive,
              icon: Icon(Icons.auto_awesome),
              label: Text('Adaptive'),
            ),
            ButtonSegment(
              value: AmbientAudioSource.recordings,
              icon: Icon(Icons.library_music_outlined),
              label: Text('Soundtracks'),
            ),
          ],
          selected: {_source},
          onSelectionChanged: (set) => _switchSource(set.first),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items,
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (sliderEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleMute,
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                ),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: _updateVolume,
                  ),
                ),
              ],
            ),
          ),
        if (activeText != null && !isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              activeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAdaptiveTiles(BoxDecoration baseDecoration) {
    final modes = <({String label, String icon, SoundscapeMode mode})>[
      (label: 'Focus', icon: '🎯', mode: SoundscapeMode.focus),
      (label: 'Downshift', icon: '🌿', mode: SoundscapeMode.downshift),
      (label: 'Sleep', icon: '🌙', mode: SoundscapeMode.sleep),
    ];

    return modes.map((m) {
      final active = _adaptiveController.isPlaying && _adaptiveController.mode == m.mode;

      return GestureDetector(
        onTap: () async {
          if (active) {
            await _adaptiveController.stop();
            if (!mounted) return;
            setState(() {});
          } else {
            await _startAdaptive(m.mode);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: baseDecoration.copyWith(
            color: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : baseDecoration.color,
            border: Border.all(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.icon, style: const TextStyle(fontSize: 24)),
              if (!widget.compact) ...[
                const SizedBox(height: 8),
                Text(
                  m.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecordingTiles(BoxDecoration baseDecoration) {
    return ambientSoundCategories
        .map(
          (category) => GestureDetector(
        onTap: () => _handleCategoryTap(category),
        onLongPress: category.tracks.length > 1 ? () => _showTrackPicker(category) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: baseDecoration.copyWith(
            color: _activeCategory?.id == category.id
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : baseDecoration.color,
            border: Border.all(
              color: _activeCategory?.id == category.id
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 24)),
              if (!widget.compact) ...[
                const SizedBox(height: 8),
                Text(
                  category.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
              ],
              if (_loadingTrackId != null && _activeCategory?.id == category.id)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .toList();
  }

  List<Widget> _buildSynthTiles(BoxDecoration baseDecoration) {
    return soundPresetCollections
        .map(
          (collection) => GestureDetector(
        onTap: () => _handlePresetCollectionTap(collection),
        onLongPress: collection.presets.length > 1 ? () => _showPresetPicker(collection) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: baseDecoration.copyWith(
            color: _activePresetCollection?.category == collection.category
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : baseDecoration.color,
            border: Border.all(
              color: _activePresetCollection?.category == collection.category
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(collection.icon, style: const TextStyle(fontSize: 24)),
              if (!widget.compact) ...[
                const SizedBox(height: 8),
                Text(
                  collection.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
              ],
              if (_synthLoading && _activePresetCollection?.category == collection.category)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .toList();
  }
}
