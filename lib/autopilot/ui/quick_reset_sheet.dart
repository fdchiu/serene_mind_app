import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/breathing_orb.dart';

class QuickResetSheet extends StatefulWidget {
  const QuickResetSheet({super.key, required this.reason});
  final String reason;

  @override
  State<QuickResetSheet> createState() => _QuickResetSheetState();
}

class _QuickResetSheetState extends State<QuickResetSheet> {
  static const totalSeconds = 90;
  int _left = totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left -= 1);
      if (_left <= 0) {
        _timer?.cancel();
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_left / 60).floor();
    final seconds = (_left % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quick Reset', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            widget.reason,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const BreathingOrb(size: 160),
          const SizedBox(height: 16),
          Text(
            '$minutes:$seconds',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}
