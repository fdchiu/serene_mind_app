import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../state/meditation_controller.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/daily_quote_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/theme_palette_sheet.dart';
import '../state/theme_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onStartMeditation,
    required this.onOpenSounds,
  });

  final VoidCallback onStartMeditation;
  final VoidCallback onOpenSounds;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MeditationController>();
    final stats = controller.stats;
    final todaySessions = controller.getTodaySessions();
    final todayMinutes = todaySessions.fold<int>(
      0,
      (sum, s) => sum + s.duration,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroHeader(onStartMeditation: onStartMeditation),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatsCard(
                  label: 'Day Streak',
                  value: stats.currentStreak.toString(),
                  icon: const Icon(Icons.local_fire_department),
                  subtext: 'Keep going!',
                ),
                StatsCard(
                  label: 'Total Minutes',
                  value: stats.totalMinutes.toString(),
                  icon: const Icon(Icons.timer_outlined),
                ),
                StatsCard(
                  label: 'Sessions',
                  value: stats.totalSessions.toString(),
                  icon: const Icon(Icons.self_improvement),
                ),
                StatsCard(
                  label: 'Mood Boost',
                  value: stats.averageMoodImprovement > 0
                      ? '+${stats.averageMoodImprovement}'
                      : '—',
                  icon: const Icon(Icons.trending_up),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DailyQuoteCard(quote: controller.quote),
            const SizedBox(height: 24),
            Text(
              'Quick Start',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'Timed Session',
                    subtitle: 'Choose your duration',
                    icon: Icons.timelapse,
                    onTap: onStartMeditation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Soundscapes',
                    subtitle: 'Ambient audio',
                    icon: Icons.music_note,
                    onTap: onOpenSounds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (todaySessions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: glassDecoration(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Practice",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${todaySessions.length} session${todaySessions.length > 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                    Text(
                      '${(todayMinutes / 60).round()} min',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onStartMeditation});

  final VoidCallback onStartMeditation;

  void _openThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      builder: (_) => const ThemePaletteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sereneColors = sereneTheme(context);
    final palette = context.watch<ThemeController>().palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openThemePicker(context),
              icon: const Icon(Icons.palette_outlined),
              label: Text('${palette.emoji} ${palette.name}'),
            ),
          ),
          Text(
            'Find Your',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w200,
                ),
          ),
          ShaderMask(
            shaderCallback: sereneColors.heroGradient.createShader,
            child: Text(
              'Inner Peace',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Take a moment to breathe, reflect, and reconnect with yourself.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          const BreathingOrb(size: 180),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onStartMeditation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Meditating'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: glassDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
