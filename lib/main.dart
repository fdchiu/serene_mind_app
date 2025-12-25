import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/meditate_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/sounds_screen.dart';
import 'screens/videos_screen.dart';
import 'state/meditation_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final meditationController = MeditationController();
  await meditationController.initialize();
  final themeController = ThemeController();
  await themeController.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MeditationController>.value(
          value: meditationController,
        ),
        ChangeNotifierProvider<ThemeController>.value(
          value: themeController,
        ),
      ],
      child: const SereneMindApp(),
    ),
  );
}

class SereneMindApp extends StatelessWidget {
  const SereneMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'Serene Mind Space',
          debugShowCheckedModeBanner: false,
          theme: buildSereneTheme(themeController.palette),
          home: const _HomeShell(),
        );
      },
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  void _setIndex(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MeditationController>();
    final colors = sereneTheme(context);

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomeScreen(
        onStartMeditation: () => _setIndex(1),
        onOpenSounds: () => _setIndex(2),
      ),
      const MeditateScreen(),
      const SoundsScreen(),
      const VideosScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages.map((page) {
          return Container(
            decoration: BoxDecoration(
              gradient: colors.backgroundGradient,
            ),
            child: page,
          );
        }).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor:
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        indicatorColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        selectedIndex: _index,
        onDestinationSelected: _setIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'Meditate',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Sounds',
          ),
          NavigationDestination(
            icon: Icon(Icons.ondemand_video_outlined),
            selectedIcon: Icon(Icons.ondemand_video),
            label: 'Videos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
