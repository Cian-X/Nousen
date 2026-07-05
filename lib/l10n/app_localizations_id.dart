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
  String get homeSegmentActivities => 'Aktivitas';

  @override
  String get homeSegmentSchedules => 'Jadwal';

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
  String get weeklyGoalLabel => 'Target mingguan';

  @override
  String get weeklyGoalHint => 'Mau selesai berapa kali per minggu?';

  @override
  String weeklyGoalValue(int count) {
    return '$count kali / minggu';
  }

  @override
  String get preReminderLabel => 'Pengingat sebelum mulai';

  @override
  String get preReminderHint => 'Pilih jeda pengingat';

  @override
  String get preReminderOff => 'Tidak aktif';

  @override
  String preReminderMinutesValue(int minutes) {
    return '$minutes menit sebelum mulai';
  }

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
  String get subActivitiesLabel => 'Sub-aktivitas';

  @override
  String get subActivityHint => 'Contoh: Leg day';

  @override
  String get addSubActivity => 'Tambah sub';

  @override
  String subActivitiesProgress(int completed, int total) {
    return 'Sub selesai: $completed/$total';
  }

  @override
  String get checklistConfirmTitle => 'Konfirmasi checklist';

  @override
  String get checklistConfirmMessage =>
      'Yakin status ini sudah benar dan ingin diubah?';

  @override
  String get checklistConfirmAction => 'Ya, ubah';

  @override
  String get journalNotesTitle => 'Catatan harian';

  @override
  String get journalAddNote => 'Tambah catatan';

  @override
  String get journalEditNote => 'Edit catatan';

  @override
  String get journalDeleteNote => 'Hapus catatan';

  @override
  String journalDeleteConfirm(String date) {
    return 'Hapus catatan tanggal $date?';
  }

  @override
  String get journalNoteSaved => 'Catatan tersimpan.';

  @override
  String get journalNoteLockedDeleteFirst =>
      'Catatan tanggal itu sudah ada. Hapus dulu kalau ingin ganti.';

  @override
  String get journalNoteDeleted => 'Catatan dihapus.';

  @override
  String get journalEmpty => 'Belum ada catatan.';

  @override
  String journalNotesCount(int count) {
    return '$count catatan tersimpan';
  }

  @override
  String get noteDateLabel => 'Tanggal catatan';

  @override
  String get noteInputHint => 'Tulis catatanmu...';

  @override
  String get comparisonTimelineTitle => 'Timeline progres';

  @override
  String get comparisonFilter7d => '7 hari';

  @override
  String get comparisonFilter30d => '30 hari';

  @override
  String get comparisonFilterAll => 'Semua';

  @override
  String get comparisonEmpty => 'Belum ada data untuk dibandingkan.';

  @override
  String get comparisonTapPhotoCompare =>
      'Tap foto untuk pilih 2 foto pembanding';

  @override
  String get comparisonNoPreviousPhoto =>
      'Belum ada foto sebelumnya untuk dibandingkan.';

  @override
  String get comparisonPhotoDialogTitle => 'Perbandingan foto';

  @override
  String get comparisonCurrentPhoto => 'Foto saat ini';

  @override
  String get comparisonPreviousPhoto => 'Foto sebelumnya';

  @override
  String get comparisonFirstSelection => 'Pilihan 1';

  @override
  String get comparisonSecondSelection => 'Pilihan 2';

  @override
  String get comparisonNeedTwoPhotos =>
      'Tambahkan minimal 2 foto untuk dibandingkan.';

  @override
  String get comparisonPhotoSwipeHint =>
      'Geser thumbnail untuk lihat foto lain, tap untuk layar penuh.';

  @override
  String get photoUploadCommentTitle => 'Komentar upload foto';

  @override
  String get comparisonTargetLabel => 'Bandingkan dengan';

  @override
  String get comparisonTargetPrevious => 'Foto sebelumnya';

  @override
  String get comparisonTarget1Week => '1 minggu';

  @override
  String get comparisonTarget2Weeks => '2 minggu';

  @override
  String get comparisonTarget1Month => '1 bulan';

  @override
  String get comparisonTargetCustomDate => 'Pilih tanggal';

  @override
  String get comparisonDatePickerHelp => 'Pilih tanggal pembanding';

  @override
  String get closeDialogAction => 'Tutup';

  @override
  String get photoDatePickerHelp => 'Pilih tanggal foto';

  @override
  String get viewAllPhotoAction => 'Lihat';

  @override
  String get photoUploadOptionsTitle => 'Pengaturan upload foto';

  @override
  String get photoCommentLabel => 'Komentar foto (opsional)';

  @override
  String get photoCommentHint => 'Tulis ulasan singkat untuk foto ini...';

  @override
  String get photoCommentApplyAll =>
      'Komentar ini akan dipakai untuk semua foto yang dipilih.';

  @override
  String get deletePhotoComment => 'Hapus komentar foto';

  @override
  String deletePhotoCommentConfirm(String date) {
    return 'Hapus komentar upload foto tanggal $date?';
  }

  @override
  String get photoCommentDeleted => 'Komentar upload foto dihapus.';

  @override
  String photoBatchImported(int count, String startDate) {
    return '$count foto disimpan pada $startDate.';
  }

  @override
  String get testerModeTitle => 'Mode tester';

  @override
  String get testerModeDescription =>
      'Isi data simulasi cepat supaya fitur timeline/statistik bisa langsung dites tanpa menunggu hari berganti.';

  @override
  String get testerSeed14Days => 'Isi 14 hari';

  @override
  String get testerSeed30Days => 'Isi 30 hari';

  @override
  String testerSeedConfirm(int days) {
    return 'Buat data simulasi $days hari terakhir untuk aktivitas ini?';
  }

  @override
  String testerSeedResult(int count) {
    return '$count entri simulasi ditambahkan.';
  }

  @override
  String get progressPhotos => 'Foto progres';

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String get deletePhoto => 'Hapus foto';

  @override
  String deletePhotoConfirm(String date) {
    return 'Hapus foto progres tanggal $date?';
  }

  @override
  String get photoDeleted => 'Foto berhasil dihapus.';

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
  String get dataImmutableWarningTitle => 'Konfirmasi simpan';

  @override
  String get noteSaveWarningMessage =>
      'Catatan hanya bisa disimpan sekali per tanggal. Setelah tersimpan, tidak bisa diedit (hanya bisa dihapus). Lanjut?';

  @override
  String get photoSaveWarningMessage =>
      'Foto dan komentar upload tidak bisa diedit setelah disimpan (hanya bisa dihapus). Lanjut?';

  @override
  String get overallCompletion => 'Penyelesaian keseluruhan';

  @override
  String get last7DaysChart => '7 hari terakhir';

  @override
  String get last28DaysHeatmap => 'Heatmap 28 hari';

  @override
  String get insightsTitle => 'Insight otomatis';

  @override
  String get insightBestTimeEmpty =>
      'Belum cukup data untuk melihat jam terbaik.';

  @override
  String insightBestTimeValue(String time) {
    return 'Jam paling konsisten: $time';
  }

  @override
  String get insightMostMissedEmpty =>
      'Belum ada aktivitas yang sering terlewat.';

  @override
  String insightMostMissedValue(String title, int count) {
    return 'Paling sering terlewat: $title (${count}x)';
  }

  @override
  String insightTrendValue(String sign, String percent) {
    return 'Tren mingguan: $sign$percent%';
  }

  @override
  String weeklyGoalProgressLabel(int completed, int goal) {
    return 'Goal minggu ini: $completed/$goal';
  }

  @override
  String get breakdownPerActivity => 'Rincian per aktivitas';

  @override
  String get reminderSettings => 'Pengaturan reminder';

  @override
  String get morningReminderTime => 'Jam reminder pagi';

  @override
  String get endOfDayReminderTime => 'Jam reminder akhir hari';

  @override
  String get testNotificationNow => 'Kirim notifikasi test sekarang';

  @override
  String get testNotificationSent => 'Notifikasi test sudah dikirim.';

  @override
  String get notificationHealthTitle => 'Kesehatan notifikasi';

  @override
  String get healthStatusUnavailable => 'Status device tidak tersedia.';

  @override
  String get timezoneLabel => 'Timezone aktif';

  @override
  String get scheduleModeLabel => 'Mode scheduling';

  @override
  String get notificationsPermissionLabel => 'Izin notifikasi';

  @override
  String get exactAlarmLabel => 'Exact alarm';

  @override
  String get batteryOptimizationLabel => 'Lolos optimasi baterai';

  @override
  String get statusOn => 'Aktif';

  @override
  String get statusOff => 'Nonaktif';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get openNotificationSettings => 'Buka setelan notif';

  @override
  String get openExactAlarmSettings => 'Buka setelan exact alarm';

  @override
  String get openBatterySettings => 'Buka setelan baterai';

  @override
  String get openAutoStartSettings => 'Buka setelan auto-start';

  @override
  String get refreshHealthStatus => 'Refresh status';

  @override
  String get openedNotificationSettings => 'Membuka setelan notifikasi.';

  @override
  String get openedExactAlarmSettings => 'Membuka setelan exact alarm.';

  @override
  String get openedBatterySettings => 'Membuka setelan baterai.';

  @override
  String get openedAutoStartSettings =>
      'Membuka setelan auto-start / app info.';

  @override
  String get cannotOpenSettings => 'Tidak bisa membuka setelan di device ini.';

  @override
  String get backupRestoreTitle => 'Backup & restore';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get chooseBackupFile => 'Pilih file backup';

  @override
  String get noBackupFilesFound => 'Belum ada file backup.';

  @override
  String get importBackupConfirm =>
      'Import akan menimpa data saat ini. Lanjut?';

  @override
  String get backupShareText => 'Backup Reminder Schedule';

  @override
  String backupExported(String path) {
    return 'Backup berhasil dibuat: $path';
  }

  @override
  String get backupImported => 'Backup berhasil di-import.';

  @override
  String get language => 'Bahasa';

  @override
  String get languageId => 'Bahasa Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String get addRecurringActivity => 'Aktivitas berulang';

  @override
  String get addRecurringActivitySubtitle => 'Jadwal harian/mingguan';

  @override
  String get addOneTimeReminder => 'Jadwal tertentu';

  @override
  String get addOneTimeReminderSubtitle =>
      'Satu kali di tanggal & jam tertentu';

  @override
  String get oneTimeRemindersSection => 'Jadwal tertentu';

  @override
  String get oneTimeRemindersEmpty => 'Belum ada jadwal tertentu.';

  @override
  String get notificationsDisabled => 'Notifikasi nonaktif';

  @override
  String get createOneTimeReminder => 'Buat jadwal tertentu';

  @override
  String get editOneTimeReminder => 'Edit jadwal tertentu';

  @override
  String get oneTimeReminderDetail => 'Detail jadwal tertentu';

  @override
  String get oneTimeReminderNotFound => 'Jadwal tertentu tidak ditemukan.';

  @override
  String get deleteOneTimeReminder => 'Hapus jadwal tertentu';

  @override
  String deleteOneTimeReminderConfirm(String title) {
    return 'Hapus \"$title\"?';
  }

  @override
  String get oneTimeTitleLabel => 'Judul pengingat';

  @override
  String get oneTimeTitleHint => 'Contoh: Bayar tagihan listrik';

  @override
  String get oneTimeDateLabel => 'Tanggal';

  @override
  String get oneTimeTimeLabel => 'Waktu';

  @override
  String get oneTimeValidationMessage => 'Isi judul pengingat terlebih dahulu.';

  @override
  String get oneTimeStatusDone => 'Selesai';

  @override
  String get oneTimeStatusPending => 'Belum selesai';

  @override
  String get oneTimeStatusMissed => 'Sudah lewat jadwal';

  @override
  String get oneTimeMarkDone => 'Tandai selesai';

  @override
  String get oneTimeDoneSubtitle => 'Jadwal ini sudah selesai.';

  @override
  String get oneTimePendingSubtitle => 'Tandai saat sudah diselesaikan.';
}
