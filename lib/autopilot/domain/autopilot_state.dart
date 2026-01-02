class AutopilotState {
  final double valence;
  final double arousal;
  final double confidence;
  final double trend;
  final int lastUpdatedMs;

  const AutopilotState({
    required this.valence,
    required this.arousal,
    required this.confidence,
    required this.trend,
    required this.lastUpdatedMs,
  });

  factory AutopilotState.initial() => AutopilotState(
        valence: 0.0,
        arousal: 0.4,
        confidence: 0.2,
        trend: 0.0,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
}
