import 'dart:math' as math;

import 'package:flutter/material.dart';

class BreathingOrb extends StatefulWidget {
  const BreathingOrb({
    super.key,
    this.isActive = true,
    this.size = 220,
  });

  final bool isActive;
  final double size;

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isActive ? 1 : 0.95,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * (1.4 + value * 0.2),
                  height: widget.size * (1.4 + value * 0.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.02 + value * 0.05),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.white.withValues(alpha: 0.1 + value * 0.1),
                        blurRadius: 60,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: widget.size * (1.2 + value * 0.1),
                  height: widget.size * (1.2 + value * 0.1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8AB4FF).withValues(alpha: 0.4),
                        const Color(0xFFAE96FF).withValues(alpha: 0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAE96FF).withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8AB4FF), Color(0xFF71D4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
