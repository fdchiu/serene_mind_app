import 'dart:async';

import 'package:flutter/material.dart';

import 'breathing_orb.dart';

class MeditationTimer extends StatefulWidget {
  const MeditationTimer({
    super.key,
    required this.initialSeconds,
    required this.onComplete,
    required this.onCancel,
    this.autoStart = false,
  });

  final int initialSeconds;
  final ValueChanged<int> onComplete;
  final VoidCallback onCancel;
  final bool autoStart;

  @override
  State<MeditationTimer> createState() => _MeditationTimerState();
}

class _MeditationTimerState extends State<MeditationTimer> {
  late int _remaining = widget.initialSeconds;
  bool _isRunning = false;
  bool _started = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    _startTimer();
  }

  void _startTimer() {
    if (_isRunning) return;
    if (!_started) {
      setState(() => _started = true);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _finish();
      } else {
        setState(() => _remaining--);
      }
    });

    setState(() => _isRunning = true);
  }

  void _finish({bool natural = true}) {
    _timer?.cancel();
    final completed = widget.initialSeconds - _remaining;
    setState(() {
      _remaining = natural ? 0 : _remaining;
      _isRunning = false;
    });
    widget.onComplete(natural ? widget.initialSeconds : completed);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.initialSeconds;
      _isRunning = false;
      _started = false;
    });
  }

  String _format() {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remaining / widget.initialSeconds).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            BreathingOrb(isActive: _isRunning, size: 260),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _format(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w200,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRunning
                      ? 'Breathe deeply...'
                      : _started
                          ? 'Paused'
                          : 'Ready to begin',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              color: Colors.white70,
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _toggleTimer,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(26),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Icon(
                _isRunning ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _started ? () => _finish(natural: false) : null,
              icon: const Icon(Icons.check),
              color: Colors.white70,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('End Session'),
        ),
      ],
    );
  }
}
