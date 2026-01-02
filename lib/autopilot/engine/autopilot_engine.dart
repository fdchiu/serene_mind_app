import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/autopilot_store.dart';
import '../domain/autopilot_state.dart';
import 'autopilot_triggers.dart';

final autopilotEngineProvider =
NotifierProvider<AutopilotEngine, AutopilotState>(AutopilotEngine.new);

class AutopilotEngine extends Notifier<AutopilotState> {
  final _store = AutopilotStore();
  int _lastTriggerMs = 0;

  @override
  AutopilotState build() {
    _init();
    return AutopilotState.initial();
  }

  Future<void> _init() async {
    await _store.init();
    state = _store.load();
  }

  /// Keep this method for simple state refreshes if you ever need it,
  /// but it MUST NOT trigger UI.
  void onAppForegrounded() {
    _update(arousalDelta: 0.02);
  }

  /// Call this ONLY when the app is reopened (background -> foreground).
  /// This is the ONLY place we emit triggers.
  void onAppReopen() {
    // Update state first (optional)
    _update(arousalDelta: 0.02);

    // Decide whether to auto-trigger the 90s reset
    final meetsThreshold = state.arousal > 0.72 && state.confidence > 0.4;

    print('[AUTOPILOT] arousal=${state.arousal} conf=${state.confidence}');

    if (!meetsThreshold) return;

    _maybeTriggerQuickReset(
      'You seem a bit activated—let’s reset for 90 seconds.',
    );
  }

  void onSessionSaved({
    required int durationSeconds,
    required int moodBefore,
    required int moodAfter,
  }) {
    final delta = (moodAfter - moodBefore) / 5.0;
    _update(
      valenceDelta: delta,
      arousalDelta: -0.08,
      confidenceDelta: 0.15,
    );

    // IMPORTANT: no triggers here (per your requirement)
  }

  void _maybeTriggerQuickReset(String reason) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Throttle: max 1 trigger per 2 hours
    if (now - _lastTriggerMs < 2 * 60 * 60 * 1000) return;
    _lastTriggerMs = now;

    ref.read(autopilotTriggerBusProvider).emit(
      AutopilotTrigger(
        type: AutopilotTriggerType.quickReset90s,
        reason: reason,
        createdAtMs: now,
      ),
    );
  }

  void _update({
    double valenceDelta = 0,
    double arousalDelta = 0,
    double confidenceDelta = 0,
  }) {
    final next = AutopilotState(
      valence: (state.valence + valenceDelta).clamp(-1, 1),
      arousal: (state.arousal + arousalDelta).clamp(0, 1),
      confidence: (state.confidence + confidenceDelta).clamp(0, 1),
      trend: (state.trend * 0.8) + valenceDelta,
      lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = next;
    _store.save(next);
  }
}
