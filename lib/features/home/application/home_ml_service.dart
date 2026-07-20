
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_onnxruntime/src/flutter_onnxruntime_platform_interface.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/services/ml/ml_model_encoder_service.dart';
import 'package:liburan_create/services/ml/ml_model_schema_service.dart';
import 'package:liburan_create/services/ml/onnx_model_service.dart';

@immutable
class HomeMlRequest {
  const HomeMlRequest({
    required this.activityTitle,
    required this.weekday,
    required this.isWeekend,
    required this.streak,
    required this.completionRate,
    required this.scheduledTimeMinutes,
    required this.numActivitiesToday,
    required this.totalScheduled,
    required this.totalCompleted,
  });

  final String activityTitle;
  final int weekday;
  final int isWeekend;
  final int streak;
  final double completionRate;
  final int scheduledTimeMinutes;
  final int numActivitiesToday;
  final int totalScheduled;
  final int totalCompleted;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is HomeMlRequest &&
        other.activityTitle == activityTitle &&
        other.weekday == weekday &&
        other.isWeekend == isWeekend &&
        other.streak == streak &&
        other.completionRate == completionRate &&
        other.scheduledTimeMinutes == scheduledTimeMinutes &&
        other.numActivitiesToday == numActivitiesToday &&
        other.totalScheduled == totalScheduled &&
        other.totalCompleted == totalCompleted;
  }

  @override
  int get hashCode => Object.hash(
    activityTitle,
    weekday,
    isWeekend,
    streak,
    completionRate,
    scheduledTimeMinutes,
    numActivitiesToday,
    totalScheduled,
    totalCompleted,
  );
}

class HomeMlPrediction {
  const HomeMlPrediction({
    required this.likelyComplete,
    required this.referenceActivityTitle,
  });

  final bool likelyComplete;
  final String referenceActivityTitle;
}

class HomeMlService {
  HomeMlService({
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

  Future<HomeMlPrediction?> predict({
    required HomeMlRequest request,
  }) async {
    await SmartActivityAdvisor.initializeProfiles();
    final SmartActivityMlProfile profile =
        _advisor.mlProfileFor(request.activityTitle) ??
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
        '[ML Home] encoder missing for "${request.activityTitle}" '
        'family=${profile.familyKey} category=${profile.categoryKey} effort=${profile.effortLevelKey}',
      );
      return null;
    }

    final List<double> features = <double>[
      familyEnc.toDouble(),
      categoryEnc.toDouble(),
      effortEnc.toDouble(),
      request.weekday.toDouble(),
      request.isWeekend.toDouble(),
      request.streak.toDouble(),
      request.completionRate,
      request.scheduledTimeMinutes.toDouble(),
      request.numActivitiesToday.toDouble(),
    ];

    final MlModelSchema? schema = await _schemaService.schemaFor(
      MlModelKind.homeCompletion,
    );
    if (schema == null) {
      debugPrint('[ML Home] schema missing for "${request.activityTitle}"');
      return null;
    }
    if (schema.featureOrder.length != features.length) {
      debugPrint(
        '[ML Home] feature length mismatch for "${request.activityTitle}" '
        'schema=${schema.featureOrder.length} actual=${features.length}',
      );
      return null;
    }

    try {
      final int? label = await _runClassifierLabel(
        kind: MlModelKind.homeCompletion,
        schema: schema,
        features: features,
      );
      if (label == null) {
        return null;
      }
      return HomeMlPrediction(
        likelyComplete: label == 1,
        referenceActivityTitle: request.activityTitle,
      );
    } catch (error, stackTrace) {
      debugPrint('[ML Home] inference failed for "${request.activityTitle}": $error');
      debugPrintStack(
        label: '[ML Home] stack for "${request.activityTitle}"',
        stackTrace: stackTrace,
      );
      return null;
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
          '[ML Home] classifier raw output invalid for "${kind.label}": $rawLabel',
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
