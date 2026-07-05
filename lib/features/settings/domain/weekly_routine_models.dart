enum WeeklyRoutineDayKind {
  unspecified,
  work,
  college,
  school,
  off,
  flexible,
  custom,
}

extension WeeklyRoutineDayKindX on WeeklyRoutineDayKind {
  String get key {
    switch (this) {
      case WeeklyRoutineDayKind.unspecified:
        return 'unspecified';
      case WeeklyRoutineDayKind.work:
        return 'work';
      case WeeklyRoutineDayKind.college:
        return 'college';
      case WeeklyRoutineDayKind.school:
        return 'school';
      case WeeklyRoutineDayKind.off:
        return 'off';
      case WeeklyRoutineDayKind.flexible:
        return 'flexible';
      case WeeklyRoutineDayKind.custom:
        return 'custom';
    }
  }
}

WeeklyRoutineDayKind weeklyRoutineDayKindFromKey(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'work':
      return WeeklyRoutineDayKind.work;
    case 'college':
      return WeeklyRoutineDayKind.college;
    case 'school':
      return WeeklyRoutineDayKind.school;
    case 'off':
      return WeeklyRoutineDayKind.off;
    case 'flexible':
      return WeeklyRoutineDayKind.flexible;
    case 'custom':
      return WeeklyRoutineDayKind.custom;
    default:
      return WeeklyRoutineDayKind.unspecified;
  }
}

class WeeklyRoutineDayProfile {
  const WeeklyRoutineDayProfile({
    required this.weekday,
    this.kind = WeeklyRoutineDayKind.unspecified,
    this.startMinutes,
    this.endMinutes,
    this.departureMinutes,
    this.returnMinutes,
    this.restStartMinutes,
    this.restEndMinutes,
  });

  final int weekday;
  final WeeklyRoutineDayKind kind;
  final int? startMinutes;
  final int? endMinutes;
  final int? departureMinutes;
  final int? returnMinutes;
  final int? restStartMinutes;
  final int? restEndMinutes;

  WeeklyRoutineDayProfile copyWith({
    WeeklyRoutineDayKind? kind,
    int? startMinutes,
    bool clearStartMinutes = false,
    int? endMinutes,
    bool clearEndMinutes = false,
    int? departureMinutes,
    bool clearDepartureMinutes = false,
    int? returnMinutes,
    bool clearReturnMinutes = false,
    int? restStartMinutes,
    bool clearRestStartMinutes = false,
    int? restEndMinutes,
    bool clearRestEndMinutes = false,
  }) {
    return WeeklyRoutineDayProfile(
      weekday: weekday,
      kind: kind ?? this.kind,
      startMinutes: clearStartMinutes ? null : (startMinutes ?? this.startMinutes),
      endMinutes: clearEndMinutes ? null : (endMinutes ?? this.endMinutes),
      departureMinutes: clearDepartureMinutes
          ? null
          : (departureMinutes ?? this.departureMinutes),
      returnMinutes: clearReturnMinutes ? null : (returnMinutes ?? this.returnMinutes),
      restStartMinutes: clearRestStartMinutes
          ? null
          : (restStartMinutes ?? this.restStartMinutes),
      restEndMinutes: clearRestEndMinutes ? null : (restEndMinutes ?? this.restEndMinutes),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'weekday': weekday,
      'kind': kind.key,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'departureMinutes': departureMinutes,
      'returnMinutes': returnMinutes,
      'restStartMinutes': restStartMinutes,
      'restEndMinutes': restEndMinutes,
    };
  }

  factory WeeklyRoutineDayProfile.fromJson(Map<String, dynamic> raw) {
    return WeeklyRoutineDayProfile(
      weekday: _normalizeWeekday(raw['weekday']),
      kind: weeklyRoutineDayKindFromKey('${raw['kind'] ?? ''}'),
      startMinutes: _normalizeMinutes(raw['startMinutes']),
      endMinutes: _normalizeMinutes(raw['endMinutes']),
      departureMinutes: _normalizeMinutes(raw['departureMinutes']),
      returnMinutes: _normalizeMinutes(raw['returnMinutes']),
      restStartMinutes: _normalizeMinutes(raw['restStartMinutes']),
      restEndMinutes: _normalizeMinutes(raw['restEndMinutes']),
    );
  }
}

const List<WeeklyRoutineDayProfile> kDefaultWeeklyRoutine =
    <WeeklyRoutineDayProfile>[
      WeeklyRoutineDayProfile(weekday: 1),
      WeeklyRoutineDayProfile(weekday: 2),
      WeeklyRoutineDayProfile(weekday: 3),
      WeeklyRoutineDayProfile(weekday: 4),
      WeeklyRoutineDayProfile(weekday: 5),
      WeeklyRoutineDayProfile(weekday: 6),
      WeeklyRoutineDayProfile(weekday: 7),
    ];

List<WeeklyRoutineDayProfile> normalizeWeeklyRoutine(
  List<WeeklyRoutineDayProfile> raw,
) {
  final Map<int, WeeklyRoutineDayProfile> byWeekday = <int, WeeklyRoutineDayProfile>{};
  for (final WeeklyRoutineDayProfile day in raw) {
    byWeekday[_normalizeWeekday(day.weekday)] = WeeklyRoutineDayProfile(
      weekday: _normalizeWeekday(day.weekday),
      kind: day.kind,
      startMinutes: _normalizeMinutes(day.startMinutes),
      endMinutes: _normalizeMinutes(day.endMinutes),
      departureMinutes: _normalizeMinutes(day.departureMinutes),
      returnMinutes: _normalizeMinutes(day.returnMinutes),
      restStartMinutes: _normalizeMinutes(day.restStartMinutes),
      restEndMinutes: _normalizeMinutes(day.restEndMinutes),
    );
  }

  return List<WeeklyRoutineDayProfile>.generate(7, (int index) {
    final int weekday = index + 1;
    return byWeekday[weekday] ?? WeeklyRoutineDayProfile(weekday: weekday);
  }, growable: false);
}

int _normalizeWeekday(Object? raw) {
  final int parsed = switch (raw) {
    int value => value,
    String value => int.tryParse(value.trim()) ?? 1,
    _ => 1,
  };
  if (parsed < 1) {
    return 1;
  }
  if (parsed > 7) {
    return 7;
  }
  return parsed;
}

int? _normalizeMinutes(Object? raw) {
  final int? parsed = switch (raw) {
    int value => value,
    String value => int.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null) {
    return null;
  }
  if (parsed < 0 || parsed > 1439) {
    return null;
  }
  return parsed;
}
