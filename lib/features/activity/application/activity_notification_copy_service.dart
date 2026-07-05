import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/features/activity/domain/activity_model.dart';
import 'package:liburan_create/features/progress/domain/progress_entry_model.dart';

class ActivityReminderCopy {
  const ActivityReminderCopy({
    required this.preStartBody,
    required this.mainBody,
    required this.morningBody,
    required this.endOfDayBody,
  });

  final String preStartBody;
  final String mainBody;
  final String morningBody;
  final String endOfDayBody;
}

class ActivityNotificationCopyService {
  const ActivityNotificationCopyService();

  ActivityReminderCopy build({
    required ActivityModel activity,
    required List<ProgressEntryModel> entries,
    required String localeCode,
    required int weekday,
    required int preReminderMinutes,
  }) {
    final bool isId = localeCode == 'id';
    final DateTime today = dateOnly(DateTime.now());
    final DateTime lookbackStart = today.subtract(const Duration(days: 27));
    final List<ProgressEntryModel> relevantEntries = entries
        .where((ProgressEntryModel entry) => !entry.date.isBefore(lookbackStart))
        .toList()
      ..sort((ProgressEntryModel a, ProgressEntryModel b) {
        return b.dateKey.compareTo(a.dateKey);
      });

    final _ActivityPatternSnapshot pattern = _buildPatternSnapshot(
      relevantEntries,
      localeCode,
    );
    final String bestDayLabel = _weekdayLabel(weekday, localeCode);
    final String title = activity.title.trim().isEmpty ? 'Aktivitas' : activity.title;
    final bool isRecoveryNeeded =
        pattern.recentTotal >= 3 && pattern.recentIncompleteRate >= 0.6;
    final bool dayMatchesBest = pattern.bestDayWeekday == weekday;

    final String preStartBody;
    if (isRecoveryNeeded) {
      preStartBody = isId
          ? '$title belakangan ini sering tertunda. Mau mulai dari sesi singkat dulu hari ini?'
          : '$title has been getting delayed lately. Want to start with a short session today?';
    } else if (pattern.bestTimeLabel != null) {
      preStartBody = isId
          ? '$title biasanya lebih enak kamu jalani saat ${pattern.bestTimeLabel}.'
          : '$title usually feels easier for you in the ${pattern.bestTimeLabel}.';
    } else {
      preStartBody = isId
          ? 'Mulai dalam $preReminderMinutes menit'
          : 'Starts in $preReminderMinutes minutes';
    }

    final String mainBody;
    if (dayMatchesBest && pattern.bestDayLabel != null) {
      mainBody = isId
          ? 'Hari ini termasuk hari yang cocok untuk $title.'
          : 'Today is one of the better days for $title.';
    } else if (pattern.bestTimeLabel != null) {
      mainBody = isId
          ? '$title paling sering terasa pas saat ${pattern.bestTimeLabel}.'
          : '$title tends to fit best in the ${pattern.bestTimeLabel}.';
    } else {
      mainBody = isId
          ? 'Waktunya memulai aktivitas'
          : 'It is time to start this activity';
    }

    final String morningBody = isId
        ? 'Cek ritme $title untuk hari $bestDayLabel.'
        : 'Check your $title rhythm for $bestDayLabel.';
    final String endOfDayBody = isRecoveryNeeded
        ? (isId
              ? 'Kalau hari ini padat, tutup dengan langkah kecil untuk $title.'
              : 'If today feels packed, close with one small step for $title.')
        : (isId
              ? 'Penutup hari: cek progres $title.'
              : 'Wrap up the day by checking your $title progress.');

    return ActivityReminderCopy(
      preStartBody: preStartBody,
      mainBody: mainBody,
      morningBody: morningBody,
      endOfDayBody: endOfDayBody,
    );
  }

  _ActivityPatternSnapshot _buildPatternSnapshot(
    List<ProgressEntryModel> entries,
    String localeCode,
  ) {
    final Map<int, int> completedByWeekday = <int, int>{};
    final Map<String, int> completedByBucket = <String, int>{};

    int recentTotal = 0;
    int recentIncomplete = 0;
    for (final ProgressEntryModel entry in entries.take(6)) {
      recentTotal++;
      if (!entry.isCompleted) {
        recentIncomplete++;
      }
    }

    for (final ProgressEntryModel entry in entries) {
      if (!entry.isCompleted) {
        continue;
      }
      completedByWeekday[entry.date.weekday] =
          (completedByWeekday[entry.date.weekday] ?? 0) + 1;

      final DateTime? completionTime = entry.effectiveCompletionTime;
      if (completionTime != null) {
        final String bucket = _timeBucketKey(
          completionTime.hour * 60 + completionTime.minute,
        );
        completedByBucket[bucket] = (completedByBucket[bucket] ?? 0) + 1;
      }
    }

    int? bestDayWeekday;
    if (completedByWeekday.isNotEmpty) {
      bestDayWeekday = ([...completedByWeekday.entries]
            ..sort((MapEntry<int, int> a, MapEntry<int, int> b) {
              final int byCount = b.value.compareTo(a.value);
              if (byCount != 0) {
                return byCount;
              }
              return a.key.compareTo(b.key);
            }))
          .first
          .key;
    }

    String? bestTimeLabel;
    if (completedByBucket.isNotEmpty) {
      final String bestBucket = ([...completedByBucket.entries]
            ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
              final int byCount = b.value.compareTo(a.value);
              if (byCount != 0) {
                return byCount;
              }
              return a.key.compareTo(b.key);
            }))
          .first
          .key;
      bestTimeLabel = _timeBucketLabelFromKey(bestBucket, localeCode);
    }

    return _ActivityPatternSnapshot(
      bestDayWeekday: bestDayWeekday,
      bestDayLabel: bestDayWeekday == null
          ? null
          : _weekdayLabel(bestDayWeekday, localeCode),
      bestTimeLabel: bestTimeLabel,
      recentTotal: recentTotal,
      recentIncompleteRate: recentTotal == 0 ? 0 : recentIncomplete / recentTotal,
    );
  }

  String _timeBucketKey(int minutes) {
    if (minutes >= 5 * 60 && minutes < 12 * 60) {
      return 'morning';
    }
    if (minutes >= 12 * 60 && minutes < 15 * 60) {
      return 'midday';
    }
    if (minutes >= 15 * 60 && minutes < 18 * 60) {
      return 'afternoon';
    }
    return 'night';
  }

  String _timeBucketLabelFromKey(String key, String localeCode) {
    final bool isId = localeCode == 'id';
    return switch (key) {
      'morning' => isId ? 'pagi' : 'morning',
      'midday' => isId ? 'siang' : 'midday',
      'afternoon' => isId ? 'sore' : 'afternoon',
      _ => isId ? 'malam' : 'night',
    };
  }

  String _weekdayLabel(int weekday, String localeCode) {
    const List<String> id = <String>[
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const List<String> en = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final List<String> labels = localeCode == 'id' ? id : en;
    if (weekday < 1 || weekday > 7) {
      return labels.first;
    }
    return labels[weekday - 1];
  }
}

class _ActivityPatternSnapshot {
  const _ActivityPatternSnapshot({
    required this.bestDayWeekday,
    required this.bestDayLabel,
    required this.bestTimeLabel,
    required this.recentTotal,
    required this.recentIncompleteRate,
  });

  final int? bestDayWeekday;
  final String? bestDayLabel;
  final String? bestTimeLabel;
  final int recentTotal;
  final double recentIncompleteRate;
}
