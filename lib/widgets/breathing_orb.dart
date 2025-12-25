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
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )
        ..repeat();

  double _heartbeatValue(double t) {
    // Layer two sine waves to mimic a double heartbeat pulse.
    final primary = math.sin(t * math.pi * 2);
    final secondary = math.sin(t * math.pi * 4) * 0.5;
    final composite = (primary + secondary + 2) / 4;
    return composite.clamp(0, 1);
  }

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
            final beat = _heartbeatValue(_controller.value);
            final colorScheme = Theme.of(context).colorScheme;
            final pulseScale = 0.78 + beat * 0.35;
            final glowScale = pulseScale + 0.12;
            final haloScale = pulseScale + 0.25;
            return Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(3, (index) {
                  final rippleProgress =
                      (_controller.value + index / 3) % 1.0;
                  final opacity = (1 - rippleProgress).clamp(0.0, 1.0);
                  final rippleSize =
                      widget.size * (1.2 + rippleProgress * 1.1);
                  return Container(
                    width: rippleSize,
                    height: rippleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(
                              colorScheme.primary,
                              colorScheme.secondary,
                              0.5,
                            )!
                            .withValues(alpha: 0.22 * opacity),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
                Container(
                  width: widget.size * haloScale,
                  height: widget.size * haloScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary
                        .withValues(alpha: 0.06 + beat * 0.07),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.secondary
                            .withValues(alpha: 0.2 + beat * 0.2),
                        blurRadius: 50 + beat * 20,
                        spreadRadius: 20 + beat * 10,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: widget.size * glowScale,
                  height: widget.size * glowScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.95),
                        colorScheme.secondary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.secondary.withValues(alpha: 0.3),
                        blurRadius: 35 + beat * 15,
                        spreadRadius: 8 + beat * 6,
                      )
                    ],
                  ),
                ),
                Container(
                  width: widget.size * pulseScale,
                  height: widget.size * pulseScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.95),
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
