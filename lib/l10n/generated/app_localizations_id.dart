// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Reminder Schedule';

  @override
  String get homeTab => 'Beranda';

  @override
  String get statsTab => 'Statistik';

  @override
  String get settingsTab => 'Pengaturan';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat siang';

  @override
  String get greetingEvening => 'Selamat malam';

  @override
  String get todayActivities => 'Aktivitas hari ini';

  @override
  String get emptyActivities =>
      'Belum ada aktivitas. Tambahkan aktivitas pertama kamu.';

  @override
  String get photoTracking => 'Tracking foto aktif';

  @override
  String get notScheduledToday => 'Tidak dijadwalkan hari ini';

  @override
  String todaySummary(int taskCount, int completedCount) {
    return '$completedCount/$taskCount aktivitas selesai hari ini';
  }

  @override
  String globalStreakValue(int days) {
    return 'Streak global: $days hari';
  }

  @override
  String get createActivity => 'Buat aktivitas';

  @override
  String get editActivity => 'Edit aktivitas';

  @override
  String get activityTitle => 'Judul aktivitas';

  @override
  String get activityTitleHint => 'Contoh: Olahraga pagi';

  @override
  String get selectedDays => 'Hari terpilih';

  @override
  String get scheduledTime => 'Jam aktivitas';

  @override
  String get enableNotifications => 'Aktifkan notifikasi';

  @override
  String get enableMorningReminder => 'Aktifkan reminder pagi';

  @override
  String get enableEndOfDayReminder => 'Aktifkan reminder akhir hari';

  @override
  String get enablePhotoProgress => 'Aktifkan progres foto';

  @override
  String get formValidationMessage => 'Isi judul dan pilih minimal satu hari.';

  @override
  String get save => 'Simpan';

  @override
  String get saving => 'Menyimpan...';

  @override
  String get activityDetail => 'Detail aktivitas';

  @override
  String get activityNotFound => 'Aktivitas tidak ditemukan.';

  @override
  String get deleteActivity => 'Hapus aktivitas';

  @override
  String deleteActivityConfirm(String title) {
    return 'Hapus \"$title\"?';
  }

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get completionRate => 'Persentase selesai';

  @override
  String get currentStreak => 'Streak saat ini';

  @override
  String daysCount(int count) {
    return '$count hari';
  }

  @override
  String get weeklyProgress => 'Progres mingguan';

  @override
  String get completeToday => 'Selesaikan hari ini';

  @override
  String get oneTapComplete => 'Satu tap untuk selesai';

  @override
  String get progressPhotos => 'Foto progres';

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String get historyLog => 'Riwayat';

  @override
  String get noHistoryYet => 'Belum ada riwayat.';

  @override
  String get completed => 'Selesai';

  @override
  String get notCompleted => 'Belum selesai';

  @override
  String get noPhotoYet => 'Belum ada foto.';

  @override
  String get overallCompletion => 'Penyelesaian keseluruhan';

  @override
  String get last7DaysChart => '7 hari terakhir';

  @override
  String get breakdownPerActivity => 'Rincian per aktivitas';

  @override
  String get reminderSettings => 'Pengaturan reminder';

  @override
  String get morningReminderTime => 'Jam reminder pagi';

  @override
  String get endOfDayReminderTime => 'Jam reminder akhir hari';

  @override
  String get language => 'Bahasa';

  @override
  String get languageId => 'Bahasa Indonesia';

  @override
  String get languageEn => 'English';
}
