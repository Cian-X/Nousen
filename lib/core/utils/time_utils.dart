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
