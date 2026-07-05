class UserBusyWindow {
  const UserBusyWindow({
    required this.weekdays,
    required this.startMinutes,
    required this.endMinutes,
    required this.label,
  });

  final Set<int> weekdays;
  final int startMinutes;
  final int endMinutes;
  final String label;
}

class UserAvailabilityNoteParser {
  const UserAvailabilityNoteParser();

  static final RegExp _timePattern = RegExp(
    r'(?<!\d)([01]?\d|2[0-3])(?:[.:]([0-5]?\d))?(?!\d)',
    caseSensitive: false,
  );

  static final List<_WeekdayToken> _weekdayTokens = <_WeekdayToken>[
    _WeekdayToken(1, RegExp(r'\bsenin\b|\bsen\b', caseSensitive: false)),
    _WeekdayToken(2, RegExp(r'\bselasa\b|\bsel\b', caseSensitive: false)),
    _WeekdayToken(3, RegExp(r'\brabu\b|\brab\b', caseSensitive: false)),
    _WeekdayToken(4, RegExp(r'\bkamis\b|\bkam\b', caseSensitive: false)),
    _WeekdayToken(5, RegExp(r"\bjum(?:at|'at)?\b|\bjum\b", caseSensitive: false)),
    _WeekdayToken(6, RegExp(r'\bsabtu\b|\bsab\b', caseSensitive: false)),
    _WeekdayToken(7, RegExp(r'\bminggu\b|\bmin\b', caseSensitive: false)),
    _WeekdayToken(1, RegExp(r'\bmonday\b|\bmon\b', caseSensitive: false)),
    _WeekdayToken(2, RegExp(r'\btuesday\b|\btue\b', caseSensitive: false)),
    _WeekdayToken(3, RegExp(r'\bwednesday\b|\bwed\b', caseSensitive: false)),
    _WeekdayToken(4, RegExp(r'\bthursday\b|\bthu\b', caseSensitive: false)),
    _WeekdayToken(5, RegExp(r'\bfriday\b|\bfri\b', caseSensitive: false)),
    _WeekdayToken(6, RegExp(r'\bsaturday\b|\bsat\b', caseSensitive: false)),
    _WeekdayToken(7, RegExp(r'\bsunday\b|\bsun\b', caseSensitive: false)),
  ];

  List<UserBusyWindow> parse(String? rawNote) {
    return parseWithFallback(rawNote);
  }

  List<UserBusyWindow> parseWithFallback(
    String? rawNote, {
    Set<int>? fallbackWeekdays,
  }) {
    final String note = (rawNote ?? '').trim();
    if (note.isEmpty) {
      return const <UserBusyWindow>[];
    }

    final List<int> timePoints = _extractTimePoints(note);
    if (timePoints.isEmpty) {
      return const <UserBusyWindow>[];
    }

    final Set<int> weekdays = _extractWeekdays(note);
    final Set<int> normalizedWeekdays = weekdays.isEmpty
        ? ((fallbackWeekdays == null || fallbackWeekdays.isEmpty)
              ? const <int>{1, 2, 3, 4, 5, 6, 7}
              : fallbackWeekdays)
        : weekdays;

    final String label = note;
    final List<UserBusyWindow> result = <UserBusyWindow>[];

    for (int index = 0; index < timePoints.length; index += 2) {
      final int start = timePoints[index];
      final int end = index + 1 < timePoints.length
          ? timePoints[index + 1]
          : start + 120;
      if (end <= start) {
        continue;
      }
      result.add(
        UserBusyWindow(
          weekdays: normalizedWeekdays,
          startMinutes: start,
          endMinutes: end > 1439 ? 1439 : end,
          label: label,
        ),
      );
    }

    return result;
  }

  List<int> _extractTimePoints(String note) {
    final List<int> result = <int>[];
    for (final RegExpMatch match in _timePattern.allMatches(note)) {
      final int? hour = int.tryParse(match.group(1) ?? '');
      final int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        continue;
      }
      result.add((hour * 60) + minute);
    }
    return result;
  }

  Set<int> _extractWeekdays(String note) {
    final List<_MatchedWeekday> matches = <_MatchedWeekday>[];
    for (final _WeekdayToken token in _weekdayTokens) {
      for (final RegExpMatch match in token.pattern.allMatches(note)) {
        matches.add(
          _MatchedWeekday(
            weekday: token.weekday,
            start: match.start,
            end: match.end,
          ),
        );
      }
    }

    if (matches.isEmpty) {
      return <int>{};
    }

    matches.sort((_MatchedWeekday a, _MatchedWeekday b) => a.start.compareTo(b.start));

    if (matches.length >= 2) {
      final _MatchedWeekday first = matches.first;
      final _MatchedWeekday last = matches.last;
      final String connector = note.substring(first.end, last.start).toLowerCase();
      if (_looksLikeRangeConnector(connector)) {
        return _expandRange(first.weekday, last.weekday);
      }
    }

    return matches.map((_MatchedWeekday item) => item.weekday).toSet();
  }

  bool _looksLikeRangeConnector(String raw) {
    final String value = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.isEmpty) {
      return false;
    }
    return value.contains('-') ||
        value.contains('sampai') ||
        value.contains('hingga') ||
        value.contains('to');
  }

  Set<int> _expandRange(int start, int end) {
    if (start == end) {
      return <int>{start};
    }
    final Set<int> result = <int>{};
    int current = start;
    for (int i = 0; i < 7; i++) {
      result.add(current);
      if (current == end) {
        break;
      }
      current = current == 7 ? 1 : current + 1;
    }
    return result;
  }
}

class _WeekdayToken {
  const _WeekdayToken(this.weekday, this.pattern);

  final int weekday;
  final RegExp pattern;
}

class _MatchedWeekday {
  const _MatchedWeekday({
    required this.weekday,
    required this.start,
    required this.end,
  });

  final int weekday;
  final int start;
  final int end;
}
