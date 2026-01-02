import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/autopilot_store.dart';
import '../domain/autopilot_state.dart';
import 'autopilot_triggers.dart';

final autopilotEngineProvider =
NotifierProvider<AutopilotEngine, AutopilotState>(AutopilotEngine.new);

class AutopilotEngine extends Notifier<AutopilotState> {
  final _store = AutopilotStore();
  int _lastTriggerMs = 0;
  bool _inited = false;

  @override
  AutopilotState build() {
    // Ensure init runs once per provider lifecycle.
    if (!_inited) {
      _inited = true;
      _init();
    }
    return stateOrInitial();
  }

  AutopilotState stateOrInitial() {
    // In Notifier, `state` is available, but in build we should return a value.
    // On first build, state is unset, so return initial.
    try {
      return state;
    } catch (_) {
      return AutopilotState.initial();
    }
  }

  Future<void> _init() async {
    await _store.init();
    state = await _store.load();
  }

  /// Keep this method for simple state refreshes if you ever need it,
  /// but it MUST NOT trigger UI.
  Future<void> onAppForegrounded() async {
    await _update(arousalDelta: 0.02);
  }

  /// Call this ONLY when the app is reopened (background -> foreground).
  /// This is the ONLY place we emit triggers.
  Future<void> onAppReopen() async {
    await _update(arousalDelta: 0.02);

    final meetsThreshold = state.arousal > 0.72 && state.confidence > 0.4;
    print('[AUTOPILOT] arousal=${state.arousal} conf=${state.confidence}');

    if (!meetsThreshold) return;

    _maybeTriggerQuickReset(
      'You seem a bit activated—let’s reset for 90 seconds.',
    );
  }

  Future<void> onSessionSaved({
    required int durationSeconds,
    required int moodBefore,
    required int moodAfter,
  }) async {
    final delta = (moodAfter - moodBefore) / 5.0;
    await _update(
      valenceDelta: delta,
      arousalDelta: -0.08,
      confidenceDelta: 0.15,
    );
  }

  Future<void> submitCheckIn({
    required double valence,
    required double arousal,
  }) async {
    final next = AutopilotState(
      valence: valence.clamp(-1.0, 1.0),
      arousal: arousal.clamp(0.0, 1.0),
      confidence: 0.9,
      trend: (valence - state.valence),
      lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
    );

    state = next;
    await _store.save(next);
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

  Future<void> _update({
    double valenceDelta = 0,
    double arousalDelta = 0,
    double confidenceDelta = 0,
  }) async {
    final next = AutopilotState(
      valence: (state.valence + valenceDelta).clamp(-1, 1),
      arousal: (state.arousal + arousalDelta).clamp(0, 1),
      confidence: (state.confidence + confidenceDelta).clamp(0, 1),
      trend: (state.trend * 0.8) + valenceDelta,
      lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = next;
    await _store.save(next);
  }
}
