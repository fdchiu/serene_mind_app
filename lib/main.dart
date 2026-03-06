import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/meditate_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/sounds_screen.dart';
import 'screens/videos_screen.dart';
import 'state/meditation_controller.dart';
import 'state/theme_controller.dart';
import 'autopilot/engine/autopilot_engine.dart';
import 'autopilot/engine/autopilot_triggers.dart';
import 'autopilot/ui/quick_reset_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final meditationController = MeditationController();
  await meditationController.initialize();
  final themeController = ThemeController();
  await themeController.initialize();

  runApp(
    riverpod.ProviderScope(
      child: MultiProvider(
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

class _HomeShellState extends State<_HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  StreamSubscription? _triggerSub;
  bool _modalOpen = false;

  // Optional: prevent auto-trigger on the very first app start.
  // If you WANT it to trigger on first launch too, delete this flag and its check.
  bool _isResumedOnce = false;

  void _setIndex(int index) {
    if (index == _index) return;
    final controller = context.read<MeditationController>();
    final isLockedDestination = controller.isSessionActive && index != 1;
    if (isLockedDestination) {
      _showActiveSessionMessage();
      return;
    }
    setState(() => _index = index);
  }

  void _showActiveSessionMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Finish your meditation session before leaving.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Subscribe to autopilot triggers after first frame (context is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = riverpod.ProviderScope.containerOf(context);
      final bus = container.read(autopilotTriggerBusProvider);

      _triggerSub = bus.stream.listen((trigger) async {
        // Respect your existing lock: do not interrupt an active meditation session
        final controller = context.read<MeditationController>();
        if (controller.isSessionActive) return;

        // Avoid stacking modals
        if (_modalOpen) return;
        _modalOpen = true;

        try {
          await showModalBottomSheet(
            context: context,
            showDragHandle: true,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.95),
            builder: (_) => QuickResetSheet(reason: trigger.reason),
          );
        } finally {
          _modalOpen = false;
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only trigger on "reopen" (background -> foreground), not on the first initial launch.
      if (!_isResumedOnce) {
        _isResumedOnce = true;
        return;
      }

      final container = riverpod.ProviderScope.containerOf(context);

      // IMPORTANT: rename your engine method to onAppReopen()
      // so the trigger policy only lives here.
      unawaited(
        container.read(autopilotEngineProvider.notifier).onAppReopen(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _triggerSub?.cancel();
    super.dispose();
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
