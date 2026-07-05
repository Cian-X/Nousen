import 'package:flutter_test/flutter_test.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';

void main() {
  const SmartActivityAdvisor advisor = SmartActivityAdvisor();

  group('SmartActivityAdvisor', () {
    test('classifies avoidance health activity', () {
      final SmartActivitySuggestion? result = advisor.analyze('tidak merokok');

      expect(result, isNotNull);
      expect(result!.type, SmartActivityType.avoidance);
      expect(result.category, SmartActivityCategory.kesehatan);
      expect(result.keyword, 'merokok');
      expect(result.recommendedTimeMinutes, isNull);
      expect(result.tracking, contains('merokok'));
      expect(result.insight, contains('malam'));
    });

    test('recommends action time for olahraga', () {
      final SmartActivitySuggestion? result = advisor.analyze('olahraga pagi');

      expect(result, isNotNull);
      expect(result!.type, SmartActivityType.action);
      expect(result.category, SmartActivityCategory.kesehatan);
      expect(result.familyLabel, 'Olahraga');
      expect(result.keyword, 'olahraga');
      expect(result.recommendedTimeMinutes, 390);
      expect(result.reason, contains('pagi'));
    });

    test('classifies social action from family call', () {
      final SmartActivitySuggestion? result = advisor.analyze(
        'telepon orang tua',
      );

      expect(result, isNotNull);
      expect(result!.type, SmartActivityType.action);
      expect(result.category, SmartActivityCategory.sosial);
      expect(result.keyword, 'telepon');
      expect(result.recommendedTimeMinutes, 1110);
    });

    test('gives rest insight for avoiding begadang', () {
      final SmartActivitySuggestion? result = advisor.analyze(
        'jangan begadang',
      );

      expect(result, isNotNull);
      expect(result!.type, SmartActivityType.avoidance);
      expect(result.category, SmartActivityCategory.istirahat);
      expect(result.keyword, 'begadang');
      expect(result.insight, contains('22:00'));
    });

    test('maps swimming to olahraga and health category', () {
      final SmartActivitySuggestion? result = advisor.analyze('berenang');

      expect(result, isNotNull);
      expect(result!.category, SmartActivityCategory.kesehatan);
      expect(result.familyLabel, 'Olahraga');
      expect(result.keyword, 'berenang');
      expect(result.recommendedTimeMinutes, 390);
    });

    test('maps wo to olahraga and health category', () {
      final SmartActivitySuggestion? result = advisor.analyze('wo');

      expect(result, isNotNull);
      expect(result!.category, SmartActivityCategory.kesehatan);
      expect(result.familyLabel, 'Olahraga');
      expect(result.keyword, 'wo');
      expect(result.recommendedTimeMinutes, 390);
    });

    test('uses proper lunch time when title is specific', () {
      final SmartActivitySuggestion? result = advisor.analyze('makan siang');

      expect(result, isNotNull);
      expect(result!.category, SmartActivityCategory.kesehatan);
      expect(result.familyLabel, 'Makan');
      expect(result.keyword, 'makan siang');
      expect(result.recommendedTimeMinutes, 750);
    });

    test('asks for title clarification when activity is makan', () {
      final SmartActivitySuggestion? result = advisor.analyze('makan');

      expect(result, isNotNull);
      expect(result!.type, SmartActivityType.action);
      expect(result.category, SmartActivityCategory.kesehatan);
      expect(result.familyLabel, 'Makan');
      expect(result.keyword, 'makan');
      expect(result.needsTitleDetail, isTrue);
      expect(result.recommendedTimeMinutes, isNull);
      expect(result.detailPrompt, contains('sarapan'));
      expect(result.suggestedTitles, contains('Sarapan'));
      expect(result.suggestedTitles, contains('Makan siang'));
      expect(result.suggestedTitles, contains('Makan malam'));
    });

    test('does not show fallback suggestion for one-letter input', () {
      final SmartActivitySuggestion? result = advisor.analyze('M');

      expect(result, isNull);
    });
  });
}
