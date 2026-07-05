import 'package:intl/intl.dart';

DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
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
