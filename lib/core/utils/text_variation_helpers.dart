import 'dart:math';

/// Helper untuk variatif text berdasarkan konteks
class TextVariationHelpers {
  static final Random _rng = Random();

  static T randomChoice<T>(List<T> choices) {
    if (choices.isEmpty) {
      throw ArgumentError('List cannot be empty');
    }
    return choices[_rng.nextInt(choices.length)];
  }

  static String generateDayHeadlineId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required int streak,
  }) {
    final isToday = scheduledCount > 0 && missedCount == 0;
    final isEmpty = scheduledCount == 0;
    final isComplete = scheduledCount > 0 && completedCount == scheduledCount;
    final isMissed = missedCount > 0;
    final isStreakHigh = streak >= 5;

    if (isEmpty) {
      return randomChoice([
        'Hari ini belum ada aktivitas terjadwal',
        'Hari ini masih kosong dari aktivitas',
        'Tidak ada aktivitas yang dijadwalkan hari ini',
        'Hari ini belum punya aktivitas',
      ]);
    }

    if (isComplete) {
      return randomChoice([
        '$weekday selesai dengan rapi',
        'Semua aktivitas $weekday sudah selesai',
        '$weekday rampung dengan baik',
        'Hari ini tuntas tanpa sisa',
      ]);
    }

    if (isMissed) {
      return randomChoice([
        '$weekday ada $scheduledCount aktivitas, $missedCount belum dikerjakan',
        '$weekday sisa $missedCount aktivitas yang belum selesai',
        '$weekday belum tuntas, ada $missedCount yang tertunda',
        '$weekday ada aktivitas yang belum rampung',
      ]);
    }

    if (isToday) {
      return randomChoice([
        '$weekday ada $scheduledCount aktivitas terjadwal',
        '$weekday punya $scheduledCount aktivitas',
        '$weekday sedang berjalan dengan $scheduledCount aktivitas',
        '$weekday masih ada $scheduledCount aktivitas menanti',
      ]);
    }

    return randomChoice([
      '$weekday berjalan dengan baik',
      'Rutinitas $weekday berjalan lancar',
      '$weekday berlangsung sesuai rencana',
    ]);
  }

  static String generateEmptyInsightId({
    required String weekday,
    required int streak,
    required String? profile,
    required int scheduledCount,
  }) {
    final reasons = <String>[];
    if (streak >= 5) {
      reasons.add('streak kamu masih kuat');
    }
    if (profile != null) {
      reasons.add('kamu sedang $profile');
    }
    if (scheduledCount == 0) {
      reasons.add('tidak ada aktivitas terjadwal');
    }

    final reasonText = reasons.isNotEmpty ? ' karena ${reasons.join(', ')}' : '';

    return randomChoice([
      'Hari ini masih kosong',
      'Belum ada aktivitas hari ini',
      'Waktu luang untuk istirahat',
      'Hari ini belum ada aktivitas terjadwal$reasonText',
    ]);
  }

  static String generateUpcomingInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required List<dynamic> scheduledActivities,
    required int streak,
  }) {
    final nextActivity = scheduledActivities.isNotEmpty
        ? scheduledActivities.first
        : null;

    if (scheduledCount == 0) {
      return randomChoice([
        'Tidak ada aktivitas mendatang',
        'Waktu luang masih tersedia',
        'Belum ada aktivitas terjadwal',
      ]);
    }

    if (missedCount > 0) {
      return randomChoice([
        'Ada $missedCount aktivitas yang tertunda',
        'Cek lagi nanti untuk aktivitas yang missed',
        'Ada sisa aktivitas yang perlu diselesaikan',
      ]);
    }

    if (completedCount == scheduledCount) {
      return randomChoice([
        'Semua aktivitas sudah selesai',
        'Hari ini tuntas',
        'Semua aktivitas $weekday rampung',
      ]);
    }

    final count = scheduledCount - completedCount;
    return randomChoice([
      'Masih ada $count aktivitas mendatang',
      '$count aktivitas belum dikerjakan',
      'Ada aktivitas yang menunggu giliran',
      'Sisa $count aktivitas untuk hari ini',
    ]);
  }

  static String generateCompletedInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int streak,
  }) {
    final rate = scheduledCount > 0 ? completedCount / scheduledCount : 0;

    if (rate == 1) {
      return randomChoice([
        'Hari ini selesai dengan rapi',
        'Semua aktivitas sudah selesai',
        '$weekday rampung sempurna',
        'Hari ini tuntas tanpa sisa',
      ]);
    }

    if (rate >= 0.8) {
      return randomChoice([
        'Hari ini hampir tuntas',
        'Progress hari ini bagus',
        'Hampir semua aktivitas selesai',
        'Hari ini berjalan sangat baik',
      ]);
    }

    if (rate >= 0.5) {
      return randomChoice([
        'Hari ini cukup produktif',
        'Lebih dari separuh aktivitas selesai',
        'Progress hari ini lumayan',
        'Hari ini berjalan dengan baik',
      ]);
    }

    return randomChoice([
      'Hari ini belum selesai semua',
      'Beberapa aktivitas masih tertunda',
      'Ada sisa aktivitas yang belum dikerjakan',
      'Hari ini perlu dituntaskan lagi',
    ]);
  }

  static String generatePastInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required int streak,
  }) {
    if (scheduledCount == 0) {
      return randomChoice([
        'Hari ini tidak punya aktivitas terjadwal',
        'Tidak ada aktivitas yang direncanakan',
        'Hari ini kosong dari aktivitas',
      ]);
    }

    if (missedCount == 0 && completedCount == scheduledCount) {
      return randomChoice([
        '$weekday punya $scheduledCount aktivitas, semuanya selesai',
        'Semua aktivitas $weekday sudah selesai',
        '$weekday tuntas tanpa sisa',
      ]);
    }

    if (missedCount > 0) {
      return randomChoice([
        '$weekday punya $scheduledCount aktivitas, $missedCount belum dikerjakan',
        '$weekday ada aktivitas yang tertunda',
        '$weekday belum tuntas',
        '$weekday sisa $missedCount aktivitas',
      ]);
    }

    return randomChoice([
      '$weekday ada $scheduledCount aktivitas, $completedCount sudah selesai',
      '$weekday berjalan dengan $completedCount/$scheduledCount selesai',
      'Progress $weekday: $completedCount dari $scheduledCount selesai',
    ]);
  }

  static String generateFocusInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required String? focusActivityTitle,
    required int streak,
  }) {
    if (scheduledCount == 0) {
      return randomChoice([
        'Hari ini tidak ada aktivitas terjadwal',
        'Waktu luang masih tersedia',
        'Tidak ada aktivitas yang dijadwalkan',
      ]);
    }

    if (focusActivityTitle != null) {
      return randomChoice([
        '$focusActivityTitle baru dijadwalkan',
        'Ada $focusActivityTitle yang baru ditambahkan',
        '$focusActivityTitle sedang dijadwalkan',
        'Fokus hari ini: $focusActivityTitle',
      ]);
    }

    if (missedCount > 0) {
      return randomChoice([
        'Ada $missedCount aktivitas yang tertunda',
        'Cek lagi nanti untuk aktivitas yang missed',
        'Ada sisa aktivitas yang perlu diselesaikan',
      ]);
    }

    if (completedCount == scheduledCount) {
      return randomChoice([
        'Semua aktivitas sudah selesai',
        'Hari ini tuntas',
        'Semua aktivitas hari ini rampung',
      ]);
    }

    return randomChoice([
      'Masih ada aktivitas yang belum selesai',
      'Ada aktivitas yang menunggu giliran',
      'Sisa aktivitas hari ini belum tuntas',
    ]);
  }

  static String generateLightInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required int streak,
  }) {
    if (scheduledCount == 0) {
      return randomChoice([
        'Hari ini tidak ada aktivitas terjadwal',
        'Waktu luang masih tersedia',
        'Tidak ada aktivitas yang dijadwalkan',
      ]);
    }

    if (scheduledCount <= 3) {
      return randomChoice([
        'Hari ini cukup ringan',
        'Sedikit aktivitas terjadwal',
        'Rencana hari ini belum penuh',
        'Hari ini masih cukup longgar',
      ]);
    }

    if (missedCount > 0) {
      return randomChoice([
        'Ada $missedCount aktivitas yang tertunda',
        'Cek lagi nanti untuk aktivitas yang missed',
        'Ada sisa aktivitas yang perlu diselesaikan',
      ]);
    }

    if (completedCount == scheduledCount) {
      return randomChoice([
        'Semua aktivitas sudah selesai',
        'Hari ini tuntas',
        'Semua aktivitas hari ini rampung',
      ]);
    }

    return randomChoice([
      'Masih ada aktivitas yang belum selesai',
      'Ada aktivitas yang menunggu giliran',
      'Sisa aktivitas hari ini belum tuntas',
    ]);
  }

  static String generateBusyInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required int streak,
  }) {
    if (scheduledCount == 0) {
      return randomChoice([
        'Hari ini tidak ada aktivitas terjadwal',
        'Waktu luang masih tersedia',
        'Tidak ada aktivitas yang dijadwalkan',
      ]);
    }

    if (scheduledCount >= 5) {
      return randomChoice([
        'Hari ini cukup sibuk',
        'Banyak aktivitas terjadwal',
        'Rencana hari ini penuh',
        'Hari ini cukup padat',
      ]);
    }

    if (missedCount > 0) {
      return randomChoice([
        'Ada $missedCount aktivitas yang tertunda',
        'Cek lagi nanti untuk aktivitas yang missed',
        'Ada sisa aktivitas yang perlu diselesaikan',
      ]);
    }

    if (completedCount == scheduledCount) {
      return randomChoice([
        'Semua aktivitas sudah selesai',
        'Hari ini tuntas',
        'Semua aktivitas hari ini rampung',
      ]);
    }

    return randomChoice([
      'Masih ada aktivitas yang belum selesai',
      'Ada aktivitas yang menunggu giliran',
      'Sisa aktivitas hari ini belum tuntas',
    ]);
  }

  static String generateSteadyInsightId({
    required String weekday,
    required int scheduledCount,
    required int completedCount,
    required int missedCount,
    required int streak,
  }) {
    if (scheduledCount == 0) {
      return randomChoice([
        'Hari ini tidak ada aktivitas terjadwal',
        'Waktu luang masih tersedia',
        'Tidak ada aktivitas yang dijadwalkan',
      ]);
    }

    final rate = scheduledCount > 0 ? completedCount / scheduledCount : 0;

    if (rate == 1) {
      return randomChoice([
        'Ritmenya masih rapi',
        'Hari ini berjalan sesuai rencana',
        'Semua aktivitas selesai tepat waktu',
        'Hari ini berjalan lancar',
      ]);
    }

    if (rate >= 0.8) {
      return randomChoice([
        'Rutinitas masih konsisten',
        'Hari ini berjalan dengan baik',
        'Progress hari ini bagus',
        'Hampir semua aktivitas selesai',
      ]);
    }

    if (missedCount > 0) {
      return randomChoice([
        'Ada $missedCount aktivitas yang tertunda',
        'Cek lagi nanti untuk aktivitas yang missed',
        'Ada sisa aktivitas yang perlu diselesaikan',
      ]);
    }

    return randomChoice([
      'Masih ada aktivitas yang belum selesai',
      'Ada aktivitas yang menunggu giliran',
      'Sisa aktivitas hari ini belum tuntas',
    ]);
  }

  // Stats insights
  static String generateStatsEffectiveSlotInsightId({
    required int? bestHourMinutes,
    required int streak,
    required String? profile,
  }) {
    final reasons = <String>[];
    if (streak >= 5) {
      reasons.add('streak kamu masih kuat');
    }
    if (profile != null) {
      reasons.add('kamu sedang $profile');
    }

    if (bestHourMinutes != null) {
      final hour = bestHourMinutes ~/ 60;
      final minute = bestHourMinutes % 60;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      return randomChoice([
        'Waktu paling efektif: $timeStr',
        'Kamu paling produktif jam $timeStr',
        'Jam $timeStr cocok untuk aktivitas',
        'Ritme harianmu optimal di $timeStr',
      ]);
    }

    return randomChoice([
      'Waktu paling efektif belum terdeteksi',
      'Coba catat waktu pengerjaan aktivitas',
      'Belum ada pola waktu yang jelas',
      'Waktu paling efektif masih terdeteksi',
    ]);
  }

  static String generateStatsConsistentActivityInsightId({
    required String? referenceActivityTitle,
    required int streak,
    required String? profile,
  }) {
    final reasons = <String>[];
    if (streak >= 5) {
      reasons.add('streak kamu masih kuat');
    }
    if (profile != null) {
      reasons.add('kamu sedang $profile');
    }

    if (referenceActivityTitle != null) {
      return randomChoice([
        'Aktivitas paling konsisten: $referenceActivityTitle',
        '$referenceActivityTitle paling sering dikerjakan',
        'Kamu paling konsisten dengan $referenceActivityTitle',
        '$referenceActivityTitle jadi andalan harianmu',
      ]);
    }

    return randomChoice([
      'Aktivitas paling konsisten belum terdeteksi',
      'Coba catat lebih banyak aktivitas',
      'Belum ada aktivitas yang konsisten',
      'Aktivitas paling konsisten masih terdeteksi',
    ]);
  }

  static String generateStatsRhythmInsightId({
    required double thisWeekRate,
    required double previousWeekRate,
    required int streak,
    required String? profile,
  }) {
    final reasons = <String>[];
    if (streak >= 5) {
      reasons.add('streak kamu masih kuat');
    }
    if (profile != null) {
      reasons.add('kamu sedang $profile');
    }

    final diff = thisWeekRate - previousWeekRate;
    final isImproving = diff > 0.05;
    final isDeclining = diff < -0.05;
    final isStable = !isImproving && !isDeclining;

    if (thisWeekRate >= 0.9) {
      if (isImproving) {
        return randomChoice([
          'Ritme minggu ini lebih baik',
          'Progress meningkat minggu ini',
          'Kamu makin konsisten minggu ini',
          'Ritme harianmu makin baik',
        ]);
      }
      if (isDeclining) {
        return randomChoice([
          'Ritme minggu ini agak turun',
          'Progress menurun minggu ini',
          'Coba tingkatkan lagi minggu depan',
          'Ritme harianmu perlu diperbaiki',
        ]);
      }
      return randomChoice([
        'Ritme harianmu masih rapi',
        'Konsistensi harianmu stabil',
        'Progress harianmu terjaga',
        'Rutinitas harianmu masih kuat',
      ]);
    }

    if (thisWeekRate >= 0.7) {
      if (isImproving) {
        return randomChoice([
          'Ritme minggu ini membaik',
          'Progress meningkat minggu ini',
          'Kamu makin konsisten minggu ini',
          'Ritme harianmu makin baik',
        ]);
      }
      if (isDeclining) {
        return randomChoice([
          'Ritme minggu ini agak turun',
          'Progress menurun minggu ini',
          'Coba tingkatkan lagi minggu depan',
          'Ritme harianmu perlu diperbaiki',
        ]);
      }
      return randomChoice([
        'Ritme harianmu lumayan',
        'Konsistensi harianmu cukup baik',
        'Progress harianmu cukup terjaga',
        'Rutinitas harianmu masih stabil',
      ]);
    }

    if (isImproving) {
      return randomChoice([
        'Ritme minggu ini membaik',
        'Progress meningkat minggu ini',
        'Kamu makin konsisten minggu ini',
        'Ritme harianmu makin baik',
      ]);
    }
    if (isDeclining) {
      return randomChoice([
        'Ritme minggu ini agak turun',
        'Progress menurun minggu ini',
        'Coba tingkatkan lagi minggu depan',
        'Ritme harianmu perlu diperbaiki',
      ]);
    }

    return randomChoice([
      'Ritme harianmu perlu ditingkatkan',
      'Coba lebih konsisten minggu depan',
      'Progress harianmu masih kurang',
      'Rutinitas harianmu perlu diperbaiki',
    ]);
  }
}
