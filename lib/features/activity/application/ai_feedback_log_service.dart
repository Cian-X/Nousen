import 'dart:convert';
import 'dart:io';

import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AiFeedbackLogService {
  const AiFeedbackLogService();

  Future<void> logRecommendationSave({
    required String title,
    required SmartActivitySuggestion suggestion,
    required String source,
    required int finalTimeMinutes,
    required List<int> finalSelectedDays,
    required AppSettingsModel settings,
  }) async {
    final File file = await _ensureLogFile();
    final Set<int> finalDays = finalSelectedDays.toSet();
    final Set<int> recommendedDays = suggestion.recommendedDays.toSet();

    final Map<String, dynamic> payload = <String, dynamic>{
      'eventType': 'activity_recommendation_saved',
      'recordedAt': DateTime.now().toIso8601String(),
      'title': title,
      'source': source,
      'category': suggestion.category.name,
      'familyLabel': suggestion.familyLabel,
      'keyword': suggestion.keyword,
      'recommendedTimeMinutes': suggestion.recommendedTimeMinutes,
      'recommendedDays': suggestion.recommendedDays,
      'finalTimeMinutes': finalTimeMinutes,
      'finalSelectedDays': finalSelectedDays,
      'usedRecommendedTime':
          suggestion.recommendedTimeMinutes != null &&
          suggestion.recommendedTimeMinutes == finalTimeMinutes,
      'usedRecommendedDays':
          recommendedDays.isNotEmpty &&
          recommendedDays.length == finalDays.length &&
          recommendedDays.containsAll(finalDays),
      'extraActivitiesNote': settings.extraActivitiesNote,
      'weeklyRoutine': settings.normalizedWeeklyRoutine
          .map(
            (day) => <String, dynamic>{
              'weekday': day.weekday,
              'kind': day.kind.key,
              'startMinutes': day.startMinutes,
              'endMinutes': day.endMinutes,
              'departureMinutes': day.departureMinutes,
              'returnMinutes': day.returnMinutes,
            },
          )
          .toList(growable: false),
    };

    await file.writeAsString(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<File> _ensureLogFile() async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory logDir = Directory(p.join(root.path, 'ai_feedback'));
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }
    final File file = File(p.join(logDir.path, 'recommendation_events.jsonl'));
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }
}
