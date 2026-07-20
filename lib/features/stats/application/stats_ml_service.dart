
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_onnxruntime/src/flutter_onnxruntime_platform_interface.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/services/ml/ml_model_encoder_service.dart';
import 'package:liburan_create/services/ml/ml_model_schema_service.dart';
import 'package:liburan_create/services/ml/onnx_model_service.dart';

@immutable
class StatsMlRequest {
  const StatsMlRequest({
    required this.dominantActivityTitle,
    required this.totalScheduled,
    required this.totalCompleted,
    required this.streak,
  });

  final String dominantActivityTitle;
  final int totalScheduled;
  final int totalCompleted;
  final int streak;

  double get completionRate {
    if (totalScheduled <= 0) {
      return 0;
    }
    return totalCompleted / totalScheduled;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is StatsMlRequest &&
        other.dominantActivityTitle == dominantActivityTitle &&
        other.totalScheduled == totalScheduled &&
        other.totalCompleted == totalCompleted &&
        other.streak == streak;
  }

  @override
  int get hashCode => Object.hash(
    dominantActivityTitle,
    totalScheduled,
    totalCompleted,
    streak,
  );
}

class StatsMlInsight {
  const StatsMlInsight({
    required this.isConsistent,
    required this.effectiveSlotKey,
    required this.referenceActivityTitle,
  });

  final bool? isConsistent;
  final String? effectiveSlotKey;
  final String referenceActivityTitle;
}

class StatsMlService {
  StatsMlService({
    required OnnxModelService runtime,
    required MlModelSchemaService schemaService,
    required MlModelEncoderService encoderService,
    SmartActivityAdvisor? advisor,
  }) : _runtime = runtime,
       _schemaService = schemaService,
       _encoderService = encoderService,
       _advisor = advisor ?? const SmartActivityAdvisor();

  final OnnxModelService _runtime;
  final MlModelSchemaService _schemaService;
  final MlModelEncoderService _encoderService;
  final SmartActivityAdvisor _advisor;

  Future<StatsMlInsight?> predict({
    required StatsMlRequest request,
  }) async {
    if (request.totalScheduled <= 0) {
      return null;
    }

    await SmartActivityAdvisor.initializeProfiles();
    final SmartActivityMlProfile profile =
        _advisor.mlProfileFor(request.dominantActivityTitle) ??
        const SmartActivityMlProfile(
          familyKey: 'umum',
          categoryKey: 'umum',
          effortLevelKey: 'medium',
          preferredTimeWindows: <SmartActivityTimeWindow>[
            SmartActivityTimeWindow.afternoon,
          ],
          routineCompatible: false,
          routinePlacement: SmartActivityRoutinePlacement.none,
        );

    final MlEncoderBundle encoders = await _encoderService.load();
    final int? familyEnc = encoders.encodeFamily(profile.familyKey);
    final int? categoryEnc = encoders.encodeCategory(profile.categoryKey);
    final int? effortEnc = encoders.encodeEffort(profile.effortLevelKey);
    if (familyEnc == null || categoryEnc == null || effortEnc == null) {
      debugPrint(
        '[ML Stats] encoder missing for "${request.dominantActivityTitle}" '
        'family=${profile.familyKey} category=${profile.categoryKey} effort=${profile.effortLevelKey}',
      );
      return null;
    }

    final List<double> features = <double>[
      familyEnc.toDouble(),
      categoryEnc.toDouble(),
      effortEnc.toDouble(),
      request.totalScheduled.toDouble(),
      request.totalCompleted.toDouble(),
      request.completionRate,
      request.streak.toDouble(),
    ];

    final MlModelSchema? consistencySchema = await _schemaService.schemaFor(
      MlModelKind.statsConsistency,
    );
    final MlModelSchema? slotSchema = await _schemaService.schemaFor(
      MlModelKind.statsEffectiveSlot,
    );
    if (consistencySchema == null || slotSchema == null) {
      debugPrint(
        '[ML Stats] schema missing for "${request.dominantActivityTitle}"',
      );
      return null;
    }
    if (consistencySchema.featureOrder.length != features.length ||
        slotSchema.featureOrder.length != features.length) {
      debugPrint(
        '[ML Stats] feature length mismatch for "${request.dominantActivityTitle}" '
        'consistency=${consistencySchema.featureOrder.length} '
        'slot=${slotSchema.featureOrder.length} actual=${features.length}',
      );
      return null;
    }

    try {
      final int? consistencyLabel = await _runClassifierLabel(
        kind: MlModelKind.statsConsistency,
        schema: consistencySchema,
        features: features,
      );
      final int? slotLabel = await _runClassifierLabel(
        kind: MlModelKind.statsEffectiveSlot,
        schema: slotSchema,
        features: features,
      );
      if (consistencyLabel == null && slotLabel == null) {
        return null;
      }

      return StatsMlInsight(
        isConsistent: consistencyLabel == null ? null : consistencyLabel == 1,
        effectiveSlotKey: slotLabel == null
            ? null
            : _normalizeSlotKey(
                _labelFor(slotSchema, slotLabel) ?? slotLabel.toString(),
              ),
        referenceActivityTitle: request.dominantActivityTitle,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[ML Stats] inference failed for "${request.dominantActivityTitle}": $error',
      );
      debugPrintStack(
        label: '[ML Stats] stack for "${request.dominantActivityTitle}"',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String? _labelFor(MlModelSchema schema, int label) {
    final Map<String, dynamic> labels =
        (schema.outputConfig['labels'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return labels[label.toString()]?.toString();
  }

  String _normalizeSlotKey(String raw) {
    final String normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'pagi':
      case 'morning':
        return 'morning';
      case 'siang':
      case 'midday':
        return 'midday';
      case 'sore':
      case 'afternoon':
        return 'afternoon';
      default:
        return 'night';
    }
  }

  Future<int?> _runClassifierLabel({
    required MlModelKind kind,
    required MlModelSchema schema,
    required List<double> features,
  }) async {
    final OrtSession session = await _runtime.sessionFor(kind);
    OrtValue? inputTensor;
    OrtValue? labelTensor;
    try {
      inputTensor = await OrtValue.fromList(
        Float32List.fromList(features),
        <int>[1, features.length],
      );
      final Map<String, dynamic> rawOutputs =
          await FlutterOnnxruntimePlatform.instance.runInference(
            session.id,
            <String, OrtValue>{schema.inputName: inputTensor},
            runOptions: const <String, dynamic>{},
          );
      final String labelName =
          (schema.outputConfig['labelName'] as String?) ??
          session.outputNames.first;
      final Object? rawLabel = rawOutputs[labelName];
      if (rawLabel is! List || rawLabel.length < 3) {
        debugPrint(
          '[ML Stats] classifier raw output invalid for "${kind.label}": $rawLabel',
        );
        return null;
      }
      labelTensor = OrtValue.fromMap(<String, dynamic>{
        'valueId': rawLabel[0],
        'dataType': rawLabel[1],
        'shape': rawLabel[2],
      });
      final List<dynamic> values = await labelTensor.asFlattenedList();
      if (values.isEmpty) {
        return null;
      }
      return (values.first as num).toInt();
    } finally {
      await inputTensor?.dispose();
      await labelTensor?.dispose();
    }
  }
}
