
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_onnxruntime/src/flutter_onnxruntime_platform_interface.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/services/ml/ml_model_encoder_service.dart';
import 'package:liburan_create/services/ml/ml_model_schema_service.dart';
import 'package:liburan_create/services/ml/onnx_model_service.dart';

@immutable
class ActivityFormMlRequest {
  const ActivityFormMlRequest({
    required this.activityTitle,
    required this.recommendedTimeMinutes,
    required this.userWakeUpMinutes,
    required this.userSleepMinutes,
    required this.numWorkdays,
    required this.avgRoutineStartMinutes,
    required this.avgRoutineEndMinutes,
  });

  final String activityTitle;
  final int recommendedTimeMinutes;
  final int userWakeUpMinutes;
  final int userSleepMinutes;
  final int numWorkdays;
  final int avgRoutineStartMinutes;
  final int avgRoutineEndMinutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ActivityFormMlRequest &&
        other.activityTitle == activityTitle &&
        other.recommendedTimeMinutes == recommendedTimeMinutes &&
        other.userWakeUpMinutes == userWakeUpMinutes &&
        other.userSleepMinutes == userSleepMinutes &&
        other.numWorkdays == numWorkdays &&
        other.avgRoutineStartMinutes == avgRoutineStartMinutes &&
        other.avgRoutineEndMinutes == avgRoutineEndMinutes;
  }

  @override
  int get hashCode => Object.hash(
    activityTitle,
    recommendedTimeMinutes,
    userWakeUpMinutes,
    userSleepMinutes,
    numWorkdays,
    avgRoutineStartMinutes,
    avgRoutineEndMinutes,
  );
}

class ActivityFormMlPrediction {
  const ActivityFormMlPrediction({
    required this.isSuitable,
    this.predictedTimeMinutes,
  });

  final bool isSuitable;
  final int? predictedTimeMinutes;
}

class ActivityFormMlService {
  ActivityFormMlService({
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

  Future<ActivityFormMlPrediction?> predict({
    required ActivityFormMlRequest request,
  }) async {
    await SmartActivityAdvisor.initializeProfiles();
    final SmartActivityMlProfile profile =
        _advisor.mlProfileFor(request.activityTitle) ??
        _fallbackProfileFor(request);

    final MlEncoderBundle encoders = await _encoderService.load();
    final int? categoryEnc = encoders.encodeCategory(profile.categoryKey);
    final int? familyEnc = encoders.encodeFamily(profile.familyKey);
    final int? effortEnc = encoders.encodeEffort(profile.effortLevelKey);
    if (categoryEnc == null || familyEnc == null || effortEnc == null) {
      debugPrint(
        '[ML Create] encoder missing for "${request.activityTitle}" '
        'category=${profile.categoryKey} family=${profile.familyKey} effort=${profile.effortLevelKey}',
      );
      return null;
    }

    final List<double> features = <double>[
      categoryEnc.toDouble(),
      familyEnc.toDouble(),
      effortEnc.toDouble(),
      request.recommendedTimeMinutes.toDouble(),
      request.userWakeUpMinutes.toDouble(),
      request.userSleepMinutes.toDouble(),
      request.numWorkdays.toDouble(),
      request.avgRoutineStartMinutes.toDouble(),
      request.avgRoutineEndMinutes.toDouble(),
    ];

    final MlModelSchema? daySchema = await _schemaService.schemaFor(
      MlModelKind.activityDay,
    );
    final MlModelSchema? timeSchema = await _schemaService.schemaFor(
      MlModelKind.activityTime,
    );
    if (daySchema == null || timeSchema == null) {
      debugPrint('[ML Create] schema missing for "${request.activityTitle}"');
      return null;
    }
    if (daySchema.featureOrder.length != features.length ||
        timeSchema.featureOrder.length != features.length) {
      debugPrint(
        '[ML Create] feature length mismatch for "${request.activityTitle}" '
        'day=${daySchema.featureOrder.length} time=${timeSchema.featureOrder.length} actual=${features.length}',
      );
      return null;
    }

    try {
      final bool? isSuitable = await _runClassifier(
        kind: MlModelKind.activityDay,
        schema: daySchema,
        features: features,
      );
      final int? predictedTimeMinutes = await _runRegressor(
        kind: MlModelKind.activityTime,
        schema: timeSchema,
        features: features,
      );
      if (isSuitable == null && predictedTimeMinutes == null) {
        return null;
      }

      return ActivityFormMlPrediction(
        isSuitable: isSuitable ?? true,
        predictedTimeMinutes: predictedTimeMinutes == null
            ? null
            : _normalizePredictedTime(predictedTimeMinutes),
      );
    } catch (error, stackTrace) {
      debugPrint('[ML Create] inference failed for "${request.activityTitle}": $error');
      debugPrintStack(
        label: '[ML Create] stack for "${request.activityTitle}"',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  SmartActivityMlProfile _fallbackProfileFor(ActivityFormMlRequest request) {
    final SmartActivityTimeWindow window = switch (_timeBucketKey(
      request.recommendedTimeMinutes,
    )) {
      'morning' => SmartActivityTimeWindow.morning,
      'midday' => SmartActivityTimeWindow.midday,
      'afternoon' => SmartActivityTimeWindow.afternoon,
      _ => SmartActivityTimeWindow.night,
    };
    return SmartActivityMlProfile(
      familyKey: 'umum',
      categoryKey: 'umum',
      effortLevelKey: 'medium',
      preferredTimeWindows: <SmartActivityTimeWindow>[window],
      routineCompatible: false,
      routinePlacement: SmartActivityRoutinePlacement.none,
      defaultTimeMinutes: request.recommendedTimeMinutes,
    );
  }

  String _timeBucketKey(int minutes) {
    if (minutes >= 5 * 60 && minutes < 11 * 60) {
      return 'morning';
    }
    if (minutes >= 11 * 60 && minutes < 15 * 60) {
      return 'midday';
    }
    if (minutes >= 15 * 60 && minutes < 18 * 60) {
      return 'afternoon';
    }
    return 'night';
  }

  int _normalizePredictedTime(int rawMinutes) {
    int minutes = rawMinutes;
    if (minutes >= 0 && minutes <= 24) {
      minutes *= 60;
    }
    minutes = minutes.clamp(0, 23 * 60 + 59).toInt();
    return ((minutes / 5).round() * 5).clamp(0, 23 * 60 + 59).toInt();
  }

  Future<bool?> _runClassifier({
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
          '[ML Create] classifier raw output invalid for "${kind.label}": $rawLabel',
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
      return (values.first as num).toInt() == 1;
    } finally {
      await inputTensor?.dispose();
      await labelTensor?.dispose();
    }
  }

  Future<int?> _runRegressor({
    required MlModelKind kind,
    required MlModelSchema schema,
    required List<double> features,
  }) async {
    final OrtSession session = await _runtime.sessionFor(kind);
    OrtValue? inputTensor;
    OrtValue? outputTensor;
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
      final String outputName =
          (schema.outputConfig['name'] as String?) ?? session.outputNames.first;
      final Object? rawOutput = rawOutputs[outputName];
      if (rawOutput is! List || rawOutput.length < 3) {
        debugPrint(
          '[ML Create] regressor raw output invalid for "${kind.label}": $rawOutput',
        );
        return null;
      }
      outputTensor = OrtValue.fromMap(<String, dynamic>{
        'valueId': rawOutput[0],
        'dataType': rawOutput[1],
        'shape': rawOutput[2],
      });
      final List<dynamic> values = await outputTensor.asFlattenedList();
      if (values.isEmpty) {
        return null;
      }
      return (values.first as num).round();
    } finally {
      await inputTensor?.dispose();
      await outputTensor?.dispose();
    }
  }
}
