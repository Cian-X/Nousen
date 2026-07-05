import 'dart:convert';

import 'package:flutter/services.dart';

class MlEncoderBundle {
  const MlEncoderBundle({
    required this.familyEnc,
    required this.categoryEnc,
    required this.effortEnc,
    required this.bestTimeSlotEnc,
  });

  final Map<String, int> familyEnc;
  final Map<String, int> categoryEnc;
  final Map<String, int> effortEnc;
  final Map<String, int> bestTimeSlotEnc;

  int? encodeFamily(String key) => familyEnc[key];

  int? encodeCategory(String key) => categoryEnc[key];

  int? encodeEffort(String key) => effortEnc[key];

  int? encodeBestTimeSlot(String key) => bestTimeSlotEnc[key];

  String? decodeBestTimeSlot(int value) {
    const List<String> preferredEnglishKeys = <String>[
      'afternoon',
      'midday',
      'morning',
      'night',
    ];
    for (final String key in preferredEnglishKeys) {
      if (bestTimeSlotEnc[key] == value) {
        return key;
      }
    }
    for (final MapEntry<String, int> entry in bestTimeSlotEnc.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }
}

class MlModelEncoderService {
  const MlModelEncoderService();

  static const String _assetPath = 'assets/ml_model/model_encoders.json';

  static const Map<String, int> _fallbackFamily = <String, int>{
    'belajar': 0,
    'hiburan': 1,
    'hidrasi': 2,
    'kerja': 3,
    'kesehatan': 4,
    'makan': 5,
    'olahraga': 6,
    'perawatanDiri': 7,
    'produktif': 8,
    'rehat': 9,
    'rumah': 10,
    'sosial': 11,
    'tidur': 12,
    'umum': 13,
  };

  static const Map<String, int> _fallbackCategory = <String, int>{
    'istirahat': 0,
    'kesehatan': 1,
    'produktif': 2,
    'sosial': 3,
    'umum': 4,
  };

  static const Map<String, int> _fallbackEffort = <String, int>{
    'high': 0,
    'low': 1,
    'medium': 2,
  };

  static const Map<String, int> _fallbackBestTimeSlot = <String, int>{
    'afternoon': 0,
    'sore': 0,
    'midday': 1,
    'siang': 1,
    'morning': 2,
    'pagi': 2,
    'night': 3,
    'malam': 3,
  };

  Future<MlEncoderBundle> load() async {
    try {
      final String raw = await rootBundle.loadString(_assetPath);
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic> encoders =
          (decoded['encoders'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      return MlEncoderBundle(
        familyEnc: _readMap(encoders['family_enc'], _fallbackFamily),
        categoryEnc: _readMap(encoders['category_enc'], _fallbackCategory),
        effortEnc: _readMap(encoders['effort_enc'], _fallbackEffort),
        bestTimeSlotEnc: _readMap(
          encoders['bestTimeSlot_enc'],
          _fallbackBestTimeSlot,
        ),
      );
    } catch (_) {
      return const MlEncoderBundle(
        familyEnc: _fallbackFamily,
        categoryEnc: _fallbackCategory,
        effortEnc: _fallbackEffort,
        bestTimeSlotEnc: _fallbackBestTimeSlot,
      );
    }
  }

  Map<String, int> _readMap(
    Object? raw,
    Map<String, int> fallback,
  ) {
    if (raw is! Map) {
      return fallback;
    }

    final Map<String, int> parsed = <String, int>{};
    for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
      final String key = entry.key.toString();
      final int? value = (entry.value as num?)?.toInt();
      if (value == null) {
        continue;
      }
      parsed[key] = value;
    }

    return parsed.isEmpty ? fallback : parsed;
  }
}
