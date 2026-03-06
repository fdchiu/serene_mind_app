import 'package:flutter/material.dart';

import 'ambient_synth.dart';
import 'sound_preset.dart';

// Example preset list. Replace with your full list in sound_preset.dart
const List<SoundPreset> allPresets = [
  SoundPreset(
    id: 'rain',
    name: 'Rain',
    category: SoundCategory.weather,
    kind: SynthKind.noise,
    baseGain: 0.35,
    noiseSmooth: 0.10,
    lowpassHz: 3500,
    lfoHz: 6.0,
    lfoDepth: 0.25,
    eventRate: 30.0,
    eventDecay: 0.02,
    eventGain: 0.12,
  ),
  SoundPreset(
    id: 'ocean',
    name: 'Ocean',
    category: SoundCategory.ocean,
    kind: SynthKind.noise,
    baseGain: 0.45,
    noiseSmooth: 0.05,
    lowpassHz: 1200,
    highpassHz: 80,
    lfoHz: 0.10,
    lfoDepth: 0.80,
  ),
  SoundPreset(
    id: 'fire',
    name: 'Fire',
    category: SoundCategory.fire,
    kind: SynthKind.noise,
    baseGain: 0.35,
    noiseSmooth: 0.06,
    lowpassHz: 1800,
    highpassHz: 120,
    lfoHz: 0.35,
    lfoDepth: 0.35,
    eventRate: 12.0,
    eventDecay: 0.03,
    eventGain: 0.35,
  ),
  SoundPreset(
    id: 'night',
    name: 'Night',
    category: SoundCategory.night,
    kind: SynthKind.noise,
    baseGain: 0.15,
    noiseSmooth: 0.15,
    lowpassHz: 1400,
    lfoHz: 0.15,
    lfoDepth: 0.10,
  ),
];

class AmbientPage extends StatefulWidget {
  const AmbientPage({super.key});

  @override
  State<AmbientPage> createState() => _AmbientPageState();
}

class _AmbientPageState extends State<AmbientPage> {
  final AmbientSynth synth = AmbientSynth();

  SoundPreset selected = allPresets.first;
  double volume = 0.5;
  bool muted = false;

  @override
  void dispose() {
    synth.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (synth.isRunning) {
      await synth.stop();
    } else {
      await synth.startWithPreset(selected);
      synth.setVolume(volume);
      synth.setMuted(muted);
    }
    setState(() {});
  }

  Future<void> _switchPreset(SoundPreset preset) async {
    setState(() => selected = preset);

    // If currently playing, restart immediately with the new preset
    if (synth.isRunning) {
      await synth.startWithPreset(selected);
      synth.setVolume(volume);
      synth.setMuted(muted);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Procedural Ambient')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<SoundPreset>(
              value: selected,
              isExpanded: true,
              items: allPresets.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.category.name} · ${p.name}'),
                );
              }).toList(),
              onChanged: (p) {
                if (p == null) return;
                _switchPreset(p);
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Text('Volume'),
                Expanded(
                  child: Slider(
                    value: volume,
                    onChanged: (v) {
                      setState(() => volume = v);
                      synth.setVolume(v);
                    },
                  ),
                ),
              ],
            ),

            SwitchListTile(
              title: const Text('Muted'),
              value: muted,
              onChanged: (m) {
                setState(() => muted = m);
                synth.setMuted(m);
              },
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _toggle,
              child: Text(synth.isRunning ? 'Stop' : 'Play'),
            ),

            const SizedBox(height: 12),

            Text(
              synth.isRunning
                  ? 'Playing: ${selected.name} (${selected.category.name})'
                  : 'Stopped',
            ),
          ],
        ),
      ),
    );
  }
}
