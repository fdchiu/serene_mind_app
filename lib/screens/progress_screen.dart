import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../state/meditation_controller.dart';
import '../widgets/session_history.dart';
import '../widgets/stats_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MeditationController>();
    final stats = controller.stats;
    final weekDays = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: glassDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Goal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${stats.weeklyProgress} of ${stats.weeklyGoal} sessions',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (stats.weeklyProgress / stats.weeklyGoal)
                        .clamp(0, 1)
                        .toDouble(),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatsCard(
                  label: 'Current Streak',
                  value: '${stats.currentStreak}d',
                  icon: const Icon(Icons.local_fire_department),
                ),
                StatsCard(
                  label: 'Longest Streak',
                  value: '${stats.longestStreak}d',
                  icon: const Icon(Icons.workspace_premium_outlined),
                ),
                StatsCard(
                  label: 'Total Time',
                  value: stats.totalMinutes >= 60
                      ? '${stats.totalMinutes ~/ 60}h ${stats.totalMinutes % 60}m'
                      : '${stats.totalMinutes}m',
                  icon: const Icon(Icons.timer_outlined),
                ),
                StatsCard(
                  label: 'Avg Mood Boost',
                  value: stats.averageMoodImprovement > 0
                      ? '+${stats.averageMoodImprovement}'
                      : '—',
                  icon: const Icon(Icons.trending_up),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                final hasSession = controller
                    .sessionsForDay(day)
                    .any((session) => session.completed);
                final isToday = DateUtils.isSameDay(day, DateTime.now());
                return Column(
                  children: [
                    Text(
                      ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day.weekday % 7],
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.white54),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: hasSession
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        border: isToday
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      child: Text('${day.day}'),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SessionHistory(
              sessions: controller.recentSessions(),
              onDelete: (id) => controller.deleteSession(id),
            ),
          ],
        ),
      ),
    );
  }
}
