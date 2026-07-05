import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:liburan_create/services/ml/onnx_model_service.dart';

class MlModelSchema {
  const MlModelSchema({
    required this.key,
    required this.assetPath,
    required this.taskType,
    required this.target,
    required this.inputName,
    required this.inputSize,
    required this.featureOrder,
    required this.outputConfig,
  });

  final String key;
  final String assetPath;
  final String taskType;
  final String target;
  final String inputName;
  final int inputSize;
  final List<String> featureOrder;
  final Map<String, dynamic> outputConfig;

  factory MlModelSchema.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> input =
        (json['input'] as Map).cast<String, dynamic>();
    return MlModelSchema(
      key: json['key'] as String,
      assetPath: json['assetPath'] as String,
      taskType: json['taskType'] as String,
      target: json['target'] as String,
      inputName: input['name'] as String,
      inputSize: (input['size'] as num).toInt(),
      featureOrder: (input['featureOrder'] as List<dynamic>)
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      outputConfig: ((json['output'] as Map?) ?? const <String, dynamic>{})
          .cast<String, dynamic>(),
    );
  }
}

class MlSchemaValidationResult {
  const MlSchemaValidationResult({
    required this.kind,
    required this.schema,
    required this.matchesInputCount,
    required this.matchesOutputShape,
    required this.notes,
  });

  final MlModelKind kind;
  final MlModelSchema schema;
  final bool matchesInputCount;
  final bool matchesOutputShape;
  final List<String> notes;

  bool get isSafeToWire =>
      matchesInputCount && matchesOutputShape && schema.featureOrder.length == schema.inputSize;
}

class MlModelSchemaService {
  const MlModelSchemaService();

  static const String _assetPath = 'assets/ml_model/model_schema.json';

  Future<List<MlModelSchema>> loadSchemas() async {
    final String raw = await rootBundle.loadString(_assetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> models =
        decoded['models'] as List<dynamic>? ?? const <dynamic>[];
    return models
        .whereType<Map>()
        .map(
          (Map item) =>
              MlModelSchema.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<MlModelSchema?> schemaFor(MlModelKind kind) async {
    final List<MlModelSchema> schemas = await loadSchemas();
    final String key = _keyForKind(kind);
    for (final MlModelSchema schema in schemas) {
      if (schema.key == key) {
        return schema;
      }
    }
    return null;
  }

  Future<MlSchemaValidationResult?> validateAgainstRuntime(
    MlModelKind kind,
    OnnxModelService runtime,
  ) async {
    final MlModelSchema? schema = await schemaFor(kind);
    if (schema == null) {
      return null;
    }

    final MlModelSummary summary = await runtime.inspect(kind);
    final int runtimeInputCount = summary.inputInfo.isEmpty
        ? summary.inputNames.length
        : ((summary.inputInfo.first['shape'] as List?)?.last as num?)?.toInt() ??
            summary.inputNames.length;

    final bool inputCountMatches = schema.inputSize == runtimeInputCount;
    final bool outputShapeMatches = summary.outputNames.isNotEmpty;
    final List<String> notes = <String>[
      if (!inputCountMatches)
        'Input size schema (${schema.inputSize}) berbeda dari runtime ($runtimeInputCount).',
      if (!outputShapeMatches) 'Runtime model tidak mengembalikan output yang bisa dibaca.',
      if (schema.featureOrder.length != schema.inputSize)
        'Jumlah featureOrder (${schema.featureOrder.length}) belum sesuai inputSize (${schema.inputSize}).',
    ];

    return MlSchemaValidationResult(
      kind: kind,
      schema: schema,
      matchesInputCount: inputCountMatches,
      matchesOutputShape: outputShapeMatches,
      notes: notes,
    );
  }

  String _keyForKind(MlModelKind kind) {
    return switch (kind) {
      MlModelKind.activityDay => 'activity_day',
      MlModelKind.activityTime => 'activity_time',
      MlModelKind.detailDay => 'detail_day',
      MlModelKind.detailTime => 'detail_time',
      MlModelKind.homeCompletion => 'home_completion',
      MlModelKind.statsConsistency => 'stats_consistency',
      MlModelKind.statsEffectiveSlot => 'stats_effective_slot',
    };
  }
}
