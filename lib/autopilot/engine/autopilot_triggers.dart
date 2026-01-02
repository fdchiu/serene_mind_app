import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AutopilotTriggerType { quickReset90s }

class AutopilotTrigger {
  final AutopilotTriggerType type;
  final String reason;
  final int createdAtMs;

  AutopilotTrigger({
    required this.type,
    required this.reason,
    required this.createdAtMs,
  });
}

final autopilotTriggerBusProvider = Provider<AutopilotTriggerBus>((ref) {
  final bus = AutopilotTriggerBus();
  ref.onDispose(bus.dispose);
  return bus;
});

class AutopilotTriggerBus {
  final _controller = StreamController<AutopilotTrigger>.broadcast();
  Stream<AutopilotTrigger> get stream => _controller.stream;

  void emit(AutopilotTrigger trigger) => _controller.add(trigger);
  void dispose() => _controller.close();
}
