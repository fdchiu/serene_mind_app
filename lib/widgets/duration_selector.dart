import 'package:flutter/material.dart';

import '../app_theme.dart';

const _durations = [
  (label: '1 min', seconds: 60, note: 'Quick reset'),
  (label: '3 min', seconds: 180, note: 'Short break'),
  (label: '5 min', seconds: 300, note: 'Mindful pause'),
  (label: '10 min', seconds: 600, note: 'Deep focus'),
  (label: '15 min', seconds: 900, note: 'Full session'),
  (label: '20 min', seconds: 1200, note: 'Extended'),
  (label: '30 min', seconds: 1800, note: 'Deep dive'),
];

class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Choose Duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _durations
              .map(
                (duration) => _DurationChip(
                  label: duration.label,
                  seconds: duration.seconds,
                  note: duration.note,
                  isSelected: selected == duration.seconds,
                  onTap: () => onChanged(duration.seconds),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.seconds,
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int seconds;
  final String note;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseDecoration = glassDecoration(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: baseDecoration.copyWith(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : baseDecoration.color,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              note,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
