import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/services/gemini_activity_service.dart';

void main() {
  group('GeminiActivityService', () {
    test('parses structured Gemini response for action', () async {
      final GeminiActivityService service = GeminiActivityService(
        apiKeyOverride: 'demo-key',
        client: MockClient((http.Request request) async {
          expect(
            request.url.toString(),
            contains('models/gemini-2.5-flash:generateContent'),
          );
          expect(request.headers['x-goog-api-key'], 'demo-key');

          return http.Response(
            jsonEncode(<String, dynamic>{
              'candidates': <Map<String, dynamic>>[
                <String, dynamic>{
                  'content': <String, dynamic>{
                    'parts': <Map<String, String>>[
                      <String, String>{
                        'text': jsonEncode(<String, dynamic>{
                          'type': 'action',
                          'category': 'kesehatan',
                          'keyword': 'berenang',
                          'family_label': 'Olahraga',
                          'recommended_time': '06:30',
                          'reason': 'Pagi cocok untuk olahraga.',
                          'tracking': null,
                          'insight': null,
                          'needs_title_detail': false,
                          'detail_prompt': null,
                          'suggested_titles': <String>[],
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final SmartActivitySuggestion result = await service.analyzeActivityTitle(
        title: 'berenang',
      );

      expect(result.type, SmartActivityType.action);
      expect(result.category, SmartActivityCategory.kesehatan);
      expect(result.keyword, 'berenang');
      expect(result.familyLabel, 'Olahraga');
      expect(result.recommendedTimeMinutes, 390);
    });

    test('parses ambiguous title response from Gemini', () async {
      final GeminiActivityService service = GeminiActivityService(
        apiKeyOverride: 'demo-key',
        client: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'candidates': <Map<String, dynamic>>[
                <String, dynamic>{
                  'content': <String, dynamic>{
                    'parts': <Map<String, String>>[
                      <String, String>{
                        'text': jsonEncode(<String, dynamic>{
                          'type': 'action',
                          'category': 'kesehatan',
                          'keyword': 'makan',
                          'family_label': 'Makan',
                          'recommended_time': null,
                          'reason': 'Butuh konteks tambahan.',
                          'tracking': null,
                          'insight': null,
                          'needs_title_detail': true,
                          'detail_prompt':
                              'Perjelas apakah ini sarapan, makan siang, atau makan malam.',
                          'suggested_titles': <String>[
                            'Sarapan',
                            'Makan siang',
                            'Makan malam',
                          ],
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final SmartActivitySuggestion result = await service.analyzeActivityTitle(
        title: 'makan',
      );

      expect(result.needsTitleDetail, isTrue);
      expect(result.recommendedTimeMinutes, isNull);
      expect(result.suggestedTitles, contains('Makan siang'));
    });
  });
}
