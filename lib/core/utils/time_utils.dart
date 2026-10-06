String formatMinutesAsTime(int minutes) {
  final int normalized = ((minutes % 1440) + 1440) % 1440;
  final int hour = normalized ~/ 60;
  final int minute = normalized % 60;
  final String hh = hour.toString().padLeft(2, '0');
  final String mm = minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

int timeOfDayToMinutes(int hour, int minute) {
  return (hour * 60) + minute;
}

/// Jam awal default: waktu sekarang dibulatkan naik ke kelipatan
/// 15 menit berikutnya (00/15/30/45). Sama untuk Aktivitas dan Agenda.
int nextRoundedQuarterMinutes(DateTime now) {
  int minute = ((now.minute + 14) ~/ 15) * 15;
  int hour = now.hour;
  if (minute == 60) {
    minute = 0;
    hour = (hour + 1) % 24;
  }
  return timeOfDayToMinutes(hour, minute);
}
