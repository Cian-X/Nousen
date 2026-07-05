const List<int> allWeekdays = <int>[1, 2, 3, 4, 5, 6, 7];

String weekdayShortLabel(int weekday, String localeCode) {
  const List<String> id = <String>[
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];
  const List<String> en = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<String> labels = localeCode == 'id' ? id : en;
  if (weekday < 1 || weekday > 7) {
    return labels.first;
  }
  return labels[weekday - 1];
}

String weekdaysCompact(List<int> weekdays, String localeCode) {
  if (weekdays.isEmpty) {
    return '-';
  }
  final List<int> uniqueSorted = weekdays.toSet().toList()..sort();
  return uniqueSorted
      .map((int day) => weekdayShortLabel(day, localeCode))
      .join(', ');
}
