import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../models/meditation_session.dart';

class SessionHistory extends StatelessWidget {
  const SessionHistory({
    super.key,
    required this.sessions,
    this.onDelete,
  });

  final List<MeditationSession> sessions;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: glassDecoration(context),
        alignment: Alignment.center,
        child: Text(
          'No sessions yet. Start your first meditation!',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: sessions
          .map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: glassDecoration(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _SessionChip(
                                text:
                                    '${session.type.name[0].toUpperCase()}${session.type.name.substring(1)}',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeAgo(session.date),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.white60),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatDuration(session.duration),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (session.notes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                session.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: () => onDelete!(session.id),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.white60,
                      ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    if (minutes == 0) return '$remaining sec';
    if (remaining == 0) return '$minutes min';
    return '$minutes min $remaining sec';
  }

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    return DateFormat('MMM d').format(date);
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
