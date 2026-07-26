import 'package:intl/intl.dart';

DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}


String dateKeyFromDate(DateTime dateTime) {
  final DateTime date = dateOnly(dateTime);
  final String mm = date.month.toString().padLeft(2, '0');
  final String dd = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mm-$dd';
}

DateTime dateFromKey(String key) {
  return DateTime.parse(key);
}

String formatDateShort(DateTime dateTime, String locale) {
  return DateFormat('dd MMM', locale).format(dateTime);
}

String formatDateLong(DateTime dateTime, String locale) {
  return DateFormat('EEEE, d MMM yyyy', locale).format(dateTime);
}

/// Returns the Monday–Sunday range for the week containing [reference].
/// Uses the device's local timezone (typically WIB/Asia/Jakarta in this app).
/// Weekday: Monday = 1, Sunday = 7 (Dart convention).
({DateTime start, DateTime end}) currentWeekRange([DateTime? reference]) {
  final DateTime today = dateOnly(reference ?? DateTime.now());
  // today.weekday: Mon=1 … Sun=7
  final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
  final DateTime sunday = monday.add(const Duration(days: 6));
  return (start: monday, end: sunday);
}
