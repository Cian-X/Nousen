import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_onnxruntime/src/flutter_onnxruntime_platform_interface.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';
import 'package:liburan_create/features/stats/domain/stats_models.dart';
import 'package:liburan_create/services/ml/ml_model_encoder_service.dart';
import 'package:liburan_create/services/ml/ml_model_schema_service.dart';
import 'package:liburan_create/services/ml/onnx_model_service.dart';

class ActivityDetailMlPrediction {
  const ActivityDetailMlPrediction({
    required this.isTodaySuitable,
    this.predictedTimeMinutes,
    this.predictedTimeSlotKey,
  });

  final bool isTodaySuitable;
  final int? predictedTimeMinutes;
  final String? predictedTimeSlotKey;
}

class ActivityDetailMlService {
  ActivityDetailMlService({
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

  Future<ActivityDetailMlPrediction?> predict({
    required ActivityModel activity,
    required List<ProgressEntryModel> entries,
    required ActivityBreakdown? breakdown,
    required DateTime today,
  }) async {
    await SmartActivityAdvisor.initializeProfiles();
    final SmartActivityMlProfile profile =
        _advisor.mlProfileFor(activity.title) ?? _fallbackProfileFor(activity);

    final MlEncoderBundle encoders = await _encoderService.load();
    final int? familyEnc = encoders.encodeFamily(profile.familyKey);
    final int? categoryEnc = encoders.encodeCategory(profile.categoryKey);
    final int? effortEnc = encoders.encodeEffort(profile.effortLevelKey);
    if (familyEnc == null || categoryEnc == null || effortEnc == null) {
      debugPrint(
        '[ML Detail] encoder missing for "${activity.title}" '
        'family=${profile.familyKey} category=${profile.categoryKey} effort=${profile.effortLevelKey}',
      );
      return null;
    }

    final int totalScheduled = breakdown?.scheduledCount ?? entries.length;
    final int totalCompleted = breakdown?.completedCount ??
        entries.where((ProgressEntryModel entry) => entry.isCompleted).length;
    final double completionRate = totalScheduled <= 0
        ? 0
        : totalCompleted / totalScheduled;
    final int streak = breakdown?.currentStreak ?? 0;
    final int todayWeekday = today.weekday - 1;
    final int isStable =
        totalScheduled >= 4 && (completionRate >= 0.65 || streak >= 3) ? 1 : 0;
    final String bestTimeSlotKey = _bestTimeSlotKey(
      activity: activity,
      entries: entries,
      profile: profile,
    );
    final int? bestTimeSlotEnc = encoders.encodeBestTimeSlot(bestTimeSlotKey);
    if (bestTimeSlotEnc == null) {
      debugPrint(
        '[ML Detail] bestTimeSlot encoder missing for "${activity.title}" '
        'slot=$bestTimeSlotKey',
      );
      return null;
    }

    final List<double> features = <double>[
      familyEnc.toDouble(),
      categoryEnc.toDouble(),
      effortEnc.toDouble(),
      todayWeekday.toDouble(),
      streak.toDouble(),
      completionRate,
      totalScheduled.toDouble(),
      totalCompleted.toDouble(),
      isStable.toDouble(),
      bestTimeSlotEnc.toDouble(),
    ];

    final MlModelSchema? daySchema = await _schemaService.schemaFor(
      MlModelKind.detailDay,
    );
    final MlModelSchema? timeSchema = await _schemaService.schemaFor(
      MlModelKind.detailTime,
    );
    if (daySchema == null || timeSchema == null) {
      debugPrint('[ML Detail] schema missing for "${activity.title}"');
      return null;
    }
    if (daySchema.featureOrder.length != features.length ||
        timeSchema.featureOrder.length != features.length) {
      debugPrint(
        '[ML Detail] feature length mismatch for "${activity.title}" '
        'day=${daySchema.featureOrder.length} time=${timeSchema.featureOrder.length} actual=${features.length}',
      );
      return null;
    }

    try {
      final bool? isTodaySuitable = await _runClassifier(
        kind: MlModelKind.detailDay,
        schema: daySchema,
        features: features,
      );
      final int? predictedTimeMinutes = await _runRegressor(
        kind: MlModelKind.detailTime,
        schema: timeSchema,
        features: features,
      );
      if (isTodaySuitable == null && predictedTimeMinutes == null) {
        return null;
      }

      final int? normalizedTime = predictedTimeMinutes == null
          ? null
          : _normalizePredictedTime(predictedTimeMinutes);
      final String? predictedTimeSlotKey = normalizedTime == null
          ? null
          : _timeBucketKey(normalizedTime);

      return ActivityDetailMlPrediction(
        isTodaySuitable: isTodaySuitable ?? false,
        predictedTimeMinutes: normalizedTime,
        predictedTimeSlotKey: predictedTimeSlotKey,
      );
    } catch (error, stackTrace) {
      debugPrint('[ML Detail] inference failed for "${activity.title}": $error');
      debugPrintStack(
        label: '[ML Detail] stack for "${activity.title}"',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _bestTimeSlotKey({
    required ActivityModel activity,
    required List<ProgressEntryModel> entries,
    required SmartActivityMlProfile profile,
  }) {
    final Map<String, int> bucketCounts = <String, int>{};
    for (final ProgressEntryModel entry in entries) {
      if (!entry.isCompleted) {
        continue;
      }
      final DateTime? completionTime = entry.effectiveCompletionTime;
      if (completionTime == null) {
        continue;
      }
      final String bucket = _timeBucketKey(
        completionTime.hour * 60 + completionTime.minute,
      );
      bucketCounts[bucket] = (bucketCounts[bucket] ?? 0) + 1;
    }

    if (bucketCounts.isNotEmpty) {
      return ([...bucketCounts.entries]
            ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
              final int byCount = b.value.compareTo(a.value);
              if (byCount != 0) {
                return byCount;
              }
              return a.key.compareTo(b.key);
            }))
          .first
          .key;
    }

    if (profile.preferredTimeWindows.isNotEmpty) {
      return _bucketKeyFromWindow(profile.preferredTimeWindows.first);
    }

    return _timeBucketKey(activity.timeMinutes);
  }

  SmartActivityMlProfile _fallbackProfileFor(ActivityModel activity) {
    final String bucket = _timeBucketKey(activity.timeMinutes);
    final SmartActivityTimeWindow window = switch (bucket) {
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
      defaultTimeMinutes: activity.timeMinutes,
    );
  }

  String _bucketKeyFromWindow(SmartActivityTimeWindow window) {
    return switch (window) {
      SmartActivityTimeWindow.earlyMorning ||
      SmartActivityTimeWindow.morning => 'morning',
      SmartActivityTimeWindow.midday => 'midday',
      SmartActivityTimeWindow.afternoon => 'afternoon',
      SmartActivityTimeWindow.evening ||
      SmartActivityTimeWindow.night => 'night',
    };
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
          '[ML Detail] classifier raw output invalid for "${kind.label}": $rawLabel',
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
          '[ML Detail] regressor raw output invalid for "${kind.label}": $rawOutput',
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
