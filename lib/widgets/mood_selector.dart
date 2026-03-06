import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static const _moods = [
    (emoji: '😔', label: 'Stressed', value: 1),
    (emoji: '😕', label: 'Uneasy', value: 2),
    (emoji: '😐', label: 'Neutral', value: 3),
    (emoji: '🙂', label: 'Good', value: 4),
    (emoji: '😌', label: 'Peaceful', value: 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _moods
          .map(
            (mood) => _MoodButton(
              emoji: mood.emoji,
              label: mood.label,
              isSelected: mood.value == value,
              onTap: () => onChanged(mood.value),
            ),
          )
          .toList(),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 62,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
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
