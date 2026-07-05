import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

enum MlModelKind {
  activityDay,
  activityTime,
  detailDay,
  detailTime,
  homeCompletion,
  statsConsistency,
  statsEffectiveSlot,
}

extension MlModelKindX on MlModelKind {
  String get assetPath {
    return switch (this) {
      MlModelKind.activityDay => 'assets/ml_model/days_model.onnx',
      MlModelKind.activityTime => 'assets/ml_model/time_model.onnx',
      MlModelKind.detailDay => 'assets/ml_model/detail_day_model.onnx',
      MlModelKind.detailTime => 'assets/ml_model/detail_time_model.onnx',
      MlModelKind.homeCompletion => 'assets/ml_model/home_model.onnx',
      MlModelKind.statsConsistency =>
        'assets/ml_model/statistik_consistent_model.onnx',
      MlModelKind.statsEffectiveSlot =>
        'assets/ml_model/statistik_slot_model.onnx',
    };
  }

  String get label {
    return switch (this) {
      MlModelKind.activityDay => 'Activity Day',
      MlModelKind.activityTime => 'Activity Time',
      MlModelKind.detailDay => 'Detail Day',
      MlModelKind.detailTime => 'Detail Time',
      MlModelKind.homeCompletion => 'Home Completion',
      MlModelKind.statsConsistency => 'Stats Consistency',
      MlModelKind.statsEffectiveSlot => 'Stats Effective Slot',
    };
  }
}

class MlModelSummary {
  const MlModelSummary({
    required this.kind,
    required this.inputNames,
    required this.outputNames,
    required this.inputInfo,
    required this.outputInfo,
    required this.metadata,
  });

  final MlModelKind kind;
  final List<String> inputNames;
  final List<String> outputNames;
  final List<Map<String, dynamic>> inputInfo;
  final List<Map<String, dynamic>> outputInfo;
  final OrtModelMetadata? metadata;
}

class OnnxModelService {
  OnnxModelService({OnnxRuntime? runtime}) : _runtime = runtime ?? OnnxRuntime();

  final OnnxRuntime _runtime;
  final Map<MlModelKind, Future<OrtSession>> _sessionCache =
      <MlModelKind, Future<OrtSession>>{};

  OrtSessionOptions get _defaultOptions => OrtSessionOptions();

  Future<String?> platformVersion() => _runtime.getPlatformVersion();

  Future<List<OrtProvider>> availableProviders() =>
      _runtime.getAvailableProviders();

  Future<OrtSession> sessionFor(
    MlModelKind kind, {
    OrtSessionOptions? options,
  }) {
    return _sessionCache.putIfAbsent(
      kind,
      () => _runtime.createSessionFromAsset(
        kind.assetPath,
        options: options ?? _defaultOptions,
      ),
    );
  }

  Future<MlModelSummary> inspect(MlModelKind kind) async {
    final OrtSession session = await sessionFor(kind);
    OrtModelMetadata? metadata;
    List<Map<String, dynamic>> inputInfo = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> outputInfo = const <Map<String, dynamic>>[];
    try {
      metadata = await session.getMetadata();
    } catch (_) {
      metadata = null;
    }
    try {
      inputInfo = await session.getInputInfo();
    } catch (_) {
      inputInfo = const <Map<String, dynamic>>[];
    }
    try {
      outputInfo = await session.getOutputInfo();
    } catch (_) {
      outputInfo = const <Map<String, dynamic>>[];
    }

    return MlModelSummary(
      kind: kind,
      inputNames: List<String>.from(session.inputNames),
      outputNames: List<String>.from(session.outputNames),
      inputInfo: inputInfo,
      outputInfo: outputInfo,
      metadata: metadata,
    );
  }

  Future<void> close(MlModelKind kind) async {
    final Future<OrtSession>? sessionFuture = _sessionCache.remove(kind);
    if (sessionFuture == null) {
      return;
    }

    try {
      final OrtSession session = await sessionFuture;
      await session.close();
    } catch (_) {
      // Ignore close failures during teardown.
    }
  }

  Future<void> closeAll() async {
    final List<Future<OrtSession>> sessionFutures =
        _sessionCache.values.toList(growable: false);
    _sessionCache.clear();

    for (final Future<OrtSession> sessionFuture in sessionFutures) {
      try {
        final OrtSession session = await sessionFuture;
        await session.close();
      } catch (_) {
        // Ignore close failures during teardown.
      }
    }
  }
}
