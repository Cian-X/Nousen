import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:liburan_create/core/constants/ai_demo_config.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';

class GeminiActivityService {
  GeminiActivityService({http.Client? client, String? apiKeyOverride})
    : _client = client ?? http.Client(),
      _apiKeyOverride = apiKeyOverride;

  static const String _modelName = 'gemini-2.5-flash';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;
  final String? _apiKeyOverride;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  String get apiKey => _apiKeyOverride ?? AiDemoConfig.geminiApiKey;

  String? get setupHint {
    if (isConfigured) {
      return null;
    }
    return 'Set GEMINI_API_KEY via --dart-define or --dart-define-from-file before using Gemini demo mode.';
  }

  String friendlyErrorMessage(Object error, {String localeCode = 'id'}) {
    final bool isId = localeCode == 'id';
    final String rawMessage = error.toString().trim();
    final String normalized = rawMessage.toLowerCase();

    if (_looksLikeHighDemand(normalized)) {
      return isId
          ? 'Gemini sedang ramai sekarang. Coba lagi sebentar.'
          : 'Gemini is busy right now. Please try again shortly.';
    }

    if (normalized.contains('timeout') ||
        normalized.contains('terlalu lama')) {
      return isId
          ? 'Gemini sedang lambat merespons. Coba lagi sebentar.'
          : 'Gemini is responding slowly right now. Please try again shortly.';
    }

    if (normalized.contains('gagal menghubungi gemini') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection closed') ||
        normalized.contains('socketexception')) {
      return isId
          ? 'Koneksi ke Gemini sedang bermasalah. Coba lagi saat jaringan lebih stabil.'
          : 'The connection to Gemini is unstable right now. Try again when your network is more stable.';
    }

    if (normalized.contains('api key') || normalized.contains('gemini_api_key')) {
      return isId
          ? 'Gemini belum siap dipakai karena API key belum diatur.'
          : 'Gemini is not ready yet because the API key is missing.';
    }

    return rawMessage;
  }

  bool isRetryableError(Object error) {
    final String normalized = error.toString().trim().toLowerCase();
    return _looksLikeHighDemand(normalized) ||
        normalized.contains('timeout') ||
        normalized.contains('temporar') ||
        normalized.contains('unavailable') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection closed');
  }

  Future<SmartActivitySuggestion> analyzeActivityTitle({
    required String title,
    String localeCode = 'id',
  }) async {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const GeminiActivityException('Judul aktivitas masih kosong.');
    }
    if (!isConfigured) {
      throw GeminiActivityException(
        setupHint ?? 'Gemini API key belum diatur.',
      );
    }

    final Uri uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_modelName:generateContent',
    );

    final Map<String, dynamic> requestBody = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, String>>[
            <String, String>{'text': _buildPrompt(trimmedTitle, localeCode)},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseJsonSchema': _responseSchema,
      },
    };

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const GeminiActivityException(
        'Gemini butuh waktu terlalu lama. Coba lagi sebentar.',
      );
    } on http.ClientException catch (error) {
      throw GeminiActivityException(
        'Gagal menghubungi Gemini: ${error.message}',
      );
    }

    final Map<String, dynamic> responseBody =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic>? errorBody =
          responseBody['error'] as Map<String, dynamic>?;
      final String message =
          errorBody?['message'] as String? ??
          'Gemini mengembalikan error ${response.statusCode}.';
      throw GeminiActivityException(message);
    }

    final Map<String, dynamic> payload = _extractStructuredPayload(
      responseBody,
    );
    return _suggestionFromPayload(payload);
  }

  Map<String, dynamic> _extractStructuredPayload(Map<String, dynamic> body) {
    if (body.containsKey('type') && body.containsKey('category')) {
      return body;
    }

    final List<dynamic>? candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiActivityException(
        'Gemini tidak mengirim kandidat jawaban.',
      );
    }

    final Map<String, dynamic> firstCandidate =
        candidates.first as Map<String, dynamic>;
    final Map<String, dynamic>? content =
        firstCandidate['content'] as Map<String, dynamic>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw const GeminiActivityException('Gemini tidak mengirim isi jawaban.');
    }

    final StringBuffer textBuffer = StringBuffer();
    for (final dynamic rawPart in parts) {
      final Map<String, dynamic> part = rawPart as Map<String, dynamic>;
      final String? text = part['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        textBuffer.write(text);
      }
    }

    final String combinedText = textBuffer.toString().trim();
    if (combinedText.isEmpty) {
      throw const GeminiActivityException('Jawaban Gemini kosong.');
    }

    final dynamic decoded = jsonDecode(combinedText);
    if (decoded is! Map<String, dynamic>) {
      throw const GeminiActivityException(
        'Format jawaban Gemini tidak sesuai.',
      );
    }
    return decoded;
  }

  SmartActivitySuggestion _suggestionFromPayload(Map<String, dynamic> payload) {
    final String typeValue = (payload['type'] as String? ?? '').trim();
    final String categoryValue = (payload['category'] as String? ?? '').trim();
    final String keyword = (payload['keyword'] as String? ?? '').trim();
    final String familyLabel = (payload['family_label'] as String? ?? '')
        .trim();
    final String? recommendedTime = (payload['recommended_time'] as String?)
        ?.trim();

    if (typeValue.isEmpty ||
        categoryValue.isEmpty ||
        keyword.isEmpty ||
        familyLabel.isEmpty) {
      throw const GeminiActivityException(
        'Jawaban Gemini belum lengkap untuk dipakai.',
      );
    }

    return SmartActivitySuggestion(
      type: _parseType(typeValue),
      category: _parseCategory(categoryValue),
      keyword: keyword,
      familyLabel: familyLabel,
      recommendedTimeMinutes: _parseTimeMinutes(recommendedTime),
      reason: _nullIfBlank(payload['reason'] as String?),
      tracking: _nullIfBlank(payload['tracking'] as String?),
      insight: _nullIfBlank(payload['insight'] as String?),
      needsTitleDetail: payload['needs_title_detail'] as bool? ?? false,
      detailPrompt: _nullIfBlank(payload['detail_prompt'] as String?),
      suggestedTitles:
          (payload['suggested_titles'] as List<dynamic>? ?? <dynamic>[])
              .whereType<String>()
              .map((String item) => item.trim())
              .where((String item) => item.isNotEmpty)
              .toList(),
    );
  }

  SmartActivityType _parseType(String value) {
    switch (value) {
      case 'action':
        return SmartActivityType.action;
      case 'avoidance':
        return SmartActivityType.avoidance;
    }
    throw GeminiActivityException('Type Gemini tidak dikenal: $value');
  }

  SmartActivityCategory _parseCategory(String value) {
    switch (value) {
      case 'kesehatan':
        return SmartActivityCategory.kesehatan;
      case 'produktif':
        return SmartActivityCategory.produktif;
      case 'istirahat':
        return SmartActivityCategory.istirahat;
      case 'sosial':
        return SmartActivityCategory.sosial;
      case 'umum':
        return SmartActivityCategory.umum;
    }
    throw GeminiActivityException('Kategori Gemini tidak dikenal: $value');
  }

  int? _parseTimeMinutes(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final Match? match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      throw GeminiActivityException('Format waktu Gemini tidak valid: $value');
    }

    final int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw GeminiActivityException('Nilai waktu Gemini tidak valid: $value');
    }
    return (hour * 60) + minute;
  }

  String? _nullIfBlank(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _looksLikeHighDemand(String normalizedMessage) {
    return normalizedMessage.contains('high demand') ||
        normalizedMessage.contains('resource_exhausted') ||
        normalizedMessage.contains('resource exhausted') ||
        normalizedMessage.contains('429') ||
        normalizedMessage.contains('temporarily') ||
        normalizedMessage.contains('temporari') ||
        normalizedMessage.contains('overloaded') ||
        normalizedMessage.contains('busy');
  }

  String _buildPrompt(String title, String localeCode) {
    final bool isIndonesian = localeCode == 'id';
    return '''
Kamu adalah asisten klasifikasi aktivitas untuk form tambah aktivitas.

Tugasmu:
1. Tentukan type:
- action = aktivitas yang dilakukan
- avoidance = aktivitas yang dihindari
2. Tentukan category, pilih satu dari:
- kesehatan
- produktif
- istirahat
- sosial
- umum
3. Tentukan keyword utama.
4. Tentukan family_label yang alami untuk user, misalnya: Olahraga, Makan, Belajar, Tidur.
5. Jika judul terlalu umum untuk menentukan jam terbaik, set needs_title_detail = true, recommended_time = null, dan isi detail_prompt + suggested_titles.
6. Jika type = action dan judul cukup spesifik, isi recommended_time dalam format HH:MM yang realistis.
7. Jika type = avoidance, recommended_time harus null, lalu isi tracking dan insight singkat.

Aturan penting:
- Aktivitas seperti berenang, wo, gym, lari, jogging, yoga, renang, futsal, badminton masuk ke keluarga Olahraga dan category kesehatan.
- Aktivitas makan harus dibedakan. Jika judul hanya "makan", jangan tebak jam. Minta detail seperti sarapan, makan siang, atau makan malam.
- Jangan kasih waktu yang absurd. Contoh: makan siang jangan jam 08:00.
- Balas hanya JSON sesuai schema.
- Gunakan bahasa ${isIndonesian ? 'Indonesia' : 'English'} untuk family_label, reason, tracking, insight, detail_prompt, dan suggested_titles.

Judul aktivitas user: "$title"
''';
  }

  static const Map<String, dynamic> _responseSchema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'type': <String, dynamic>{
        'type': 'string',
        'enum': <String>['action', 'avoidance'],
        'description': 'Whether the user wants to do or avoid the activity.',
      },
      'category': <String, dynamic>{
        'type': 'string',
        'enum': <String>[
          'kesehatan',
          'produktif',
          'istirahat',
          'sosial',
          'umum',
        ],
        'description': 'Exactly one allowed category.',
      },
      'keyword': <String, dynamic>{
        'type': 'string',
        'description': 'Main user intent, short and specific.',
      },
      'family_label': <String, dynamic>{
        'type': 'string',
        'description':
            'Natural grouping label such as Olahraga, Makan, or Belajar.',
      },
      'recommended_time': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'HH:MM for action when title is specific. Null for avoidance or ambiguous titles.',
      },
      'reason': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description': 'Short reason for the recommendation.',
      },
      'tracking': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description': 'Daily tracking suggestion for avoidance.',
      },
      'insight': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description': 'Short motivational or trigger insight.',
      },
      'needs_title_detail': <String, dynamic>{
        'type': 'boolean',
        'description': 'True when the title is still too generic.',
      },
      'detail_prompt': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description': 'What extra detail the user should add to the title.',
      },
      'suggested_titles': <String, dynamic>{
        'type': 'array',
        'description': 'Suggested clearer titles, preferably up to 3 examples.',
        'items': <String, dynamic>{'type': 'string'},
      },
    },
    'required': <String>[
      'type',
      'category',
      'keyword',
      'family_label',
      'recommended_time',
      'reason',
      'tracking',
      'insight',
      'needs_title_detail',
      'detail_prompt',
      'suggested_titles',
    ],
    'additionalProperties': false,
  };
}

class GeminiActivityException implements Exception {
  const GeminiActivityException(this.message);

  final String message;

  @override
  String toString() => message;
}
