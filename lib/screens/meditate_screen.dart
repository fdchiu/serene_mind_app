import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../autopilot/engine/autopilot_engine.dart';
import '../models/meditation_session.dart';
import '../state/meditation_controller.dart';
import '../widgets/ambient_sound_player.dart';
import '../widgets/duration_selector.dart';
import '../widgets/meditation_timer.dart';
import '../widgets/mood_selector.dart';
import '';

enum _MeditationStep {
  duration,
  moodBefore,
  timer,
  moodAfter,
  notes,
  complete,
}

class MeditateScreen extends StatefulWidget {
  const MeditateScreen({super.key});

  @override
  State<MeditateScreen> createState() => _MeditateScreenState();
}

class _MeditateScreenState extends State<MeditateScreen> {
  _MeditationStep _step = _MeditationStep.duration;
  int _duration = 300;
  int _moodBefore = 3;
  int _moodAfter = 3;
  int _actualDuration = 0;
  String _notes = '';

  void _transitionToStep(
    _MeditationStep next, {
    VoidCallback? updateState,
  }) {
    final controller = context.read<MeditationController>();
    final wasTimer = _step == _MeditationStep.timer;
    final willBeTimer = next == _MeditationStep.timer;

    if (willBeTimer && !wasTimer) {
      controller.beginActiveSession();
    }

    setState(() {
      updateState?.call();
      _step = next;
    });

    if (wasTimer && !willBeTimer) {
      controller.endActiveSession();
    }
  }

  void _resetFlow() {
    _transitionToStep(
      _MeditationStep.duration,
      updateState: () {
        _duration = 300;
        _moodBefore = 3;
        _moodAfter = 3;
        _notes = '';
        _actualDuration = 0;
      },
    );
  }

  Future<void> _saveSession() async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<MeditationController>();
    final session = controller.buildSession(
      duration: _actualDuration,
      moodBefore: _moodBefore,
      moodAfter: _moodAfter,
      notes: _notes.isEmpty ? null : _notes,
      type: SessionType.timer,
    );
    await controller.saveSession(session);
    final container = ProviderScope.containerOf(context);
    container.read(autopilotEngineProvider.notifier).onSessionSaved(
      durationSeconds: _actualDuration,
      moodBefore: _moodBefore,
      moodAfter: _moodAfter,
    );

    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Session saved')));
    _transitionToStep(_MeditationStep.complete);
  }

  @override
  void dispose() {
    if (_step == _MeditationStep.timer) {
      context.read<MeditationController>().endActiveSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepContent = switch (_step) {
      _MeditationStep.duration => _DurationStep(
          duration: _duration,
          onDurationChanged: (value) => setState(() => _duration = value),
          onBegin: () => _transitionToStep(_MeditationStep.moodBefore),
        ),
      _MeditationStep.moodBefore => _MoodStep(
          title: 'How are you feeling?',
          onNext: () => _transitionToStep(_MeditationStep.timer),
          mood: _moodBefore,
          onMoodChanged: (value) => setState(() => _moodBefore = value),
        ),
      _MeditationStep.timer => MeditationTimer(
          initialSeconds: _duration,
          autoStart: true,
          onComplete: (value) {
            _transitionToStep(
              _MeditationStep.moodAfter,
              updateState: () => _actualDuration = value,
            );
          },
          onCancel: () => _transitionToStep(_MeditationStep.duration),
        ),
      _MeditationStep.moodAfter => _MoodStep(
          title: 'How do you feel now?',
          mood: _moodAfter,
          onMoodChanged: (value) => setState(() => _moodAfter = value),
          onNext: () => _transitionToStep(_MeditationStep.notes),
        ),
      _MeditationStep.notes => _NotesStep(
          notes: _notes,
          onNotesChanged: (value) => setState(() => _notes = value),
          onSave: _saveSession,
          onSkip: _saveSession,
        ),
      _MeditationStep.complete => _CompleteStep(
          duration: _actualDuration,
          moodDelta: _moodAfter - _moodBefore,
          onNewSession: _resetFlow,
        ),
    };

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const maxContentWidth = 560.0;
          final availableWidth = constraints.maxWidth;
          final contentWidth =
              availableWidth > maxContentWidth ? maxContentWidth : availableWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: SizedBox(
                    key: ValueKey(_step),
                    width: double.infinity,
                    child: stepContent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DurationStep extends StatelessWidget {
  const _DurationStep({
    required this.duration,
    required this.onDurationChanged,
    required this.onBegin,
  });

  final int duration;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'New Session',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        DurationSelector(
          selected: duration,
          onChanged: onDurationChanged,
        ),
        const SizedBox(height: 24),
        Text(
          'Background Sounds',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const AmbientSoundPlayer(compact: true),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onBegin,
          child: const Text('Begin Session'),
        ),
      ],
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({
    required this.title,
    required this.onNext,
    required this.mood,
    required this.onMoodChanged,
  });

  final String title;
  final VoidCallback onNext;
  final int mood;
  final ValueChanged<int> onMoodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Take a moment to check-in with yourself.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        MoodSelector(value: mood, onChanged: onMoodChanged),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onNext,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _NotesStep extends StatelessWidget {
  const _NotesStep({
    required this.notes,
    required this.onNotesChanged,
    required this.onSave,
    required this.onSkip,
  });

  final String notes;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any reflections?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Optional: capture your thoughts or feelings.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        TextField(
          maxLines: 5,
          onChanged: onNotesChanged,
          decoration: InputDecoration(
            hintText: 'How was your practice today?',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text('Save Session'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({
    required this.duration,
    required this.moodDelta,
    required this.onNewSession,
  });

  final int duration;
  final int moodDelta;
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0x3323A86B),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🧘', style: TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 16),
        Text(
          'Well Done!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'You completed ${(duration / 60).round()} minutes of meditation.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
        if (moodDelta > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Mood improved by +$moodDelta ✨',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: const Color(0xFF6BEFA3)),
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onNewSession,
          child: const Text('New Session'),
        ),
      ],
    );
  }
}
