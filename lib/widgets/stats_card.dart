import 'package:flutter/material.dart';

import '../app_theme.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.subtext,
  });

  final String label;
  final String value;
  final Widget? icon;
  final String? subtext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: glassDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: icon,
            ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  height: 1,
                  fontWeight: FontWeight.w200,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.white70),
          ),
          if (subtext != null)
            Text(
              subtext!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white54),
            ),
        ],
      ),
    );
  }
}
