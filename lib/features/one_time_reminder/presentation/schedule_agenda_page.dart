import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/core/utils/weekday_utils.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_visual_state.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/schedule_form_page.dart';
import 'package:liburan_create/core/widgets/nousen_bottom_nav_bar.dart';
import 'package:liburan_create/features/settings/presentation/settings_page.dart';

class ScheduleAgendaPage extends ConsumerStatefulWidget {
  const ScheduleAgendaPage({super.key});

  @override
  ConsumerState<ScheduleAgendaPage> createState() => _ScheduleAgendaPageState();
}

class _ScheduleAgendaPageState extends ConsumerState<ScheduleAgendaPage> {
  int _weekOffset = 0;
  late DateTime _selectedDate;
  bool _upcomingOnly = false;
  DateTime? _dateOverride;

  @override
  void initState() {
    super.initState();
    _selectedDate = dateOnly(DateTime.now());
  }

  DateTime get _windowStart {
    final DateTime today = dateOnly(DateTime.now());
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    return monday.add(Duration(days: _weekOffset * 14));
  }

  List<DateTime> get _windowDays =>
      List<DateTime>.generate(14, (i) => _windowStart.add(Duration(days: i)));

  bool _inWindow(DateTime date) {
    final DateTime end = _windowStart.add(const Duration(days: 13));
    return !date.isBefore(_windowStart) && !date.isAfter(end);
  }

  void _shiftWindow(int delta) {
    setState(() {
      _weekOffset += delta;
      if (!_inWindow(_selectedDate)) {
        final DateTime today = dateOnly(DateTime.now());
        _selectedDate = _inWindow(today) ? today : _windowStart;

        _dateOverride = null;
      }
    });
  }

  void _resetToCurrentFortnight() {
    setState(() {
      _weekOffset = 0;
      _selectedDate = dateOnly(DateTime.now());

      _dateOverride = null;
    });
  }

  void _selectDate(DateTime date) {
    final DateTime today = dateOnly(DateTime.now());
    setState(() {
      _selectedDate = date;

      _dateOverride = date == today ? null : date;
    });
  }

  Map<String, List<OneTimeReminderModel>> _groupByDate(
    List<OneTimeReminderModel> items,
  ) {
    final Map<String, List<OneTimeReminderModel>> map =
        <String, List<OneTimeReminderModel>>{};
    for (final OneTimeReminderModel item in items) {
      final String key = dateKeyFromDate(dateOnly(item.scheduledAt));
      map.putIfAbsent(key, () => <OneTimeReminderModel>[]).add(item);
    }
    for (final List<OneTimeReminderModel> list in map.values) {
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    return map;
  }

  void _openDetail(OneTimeReminderModel item) {
    Navigator.of(context).pushNamed(
      AppRoutes.oneTimeReminderDetail,
      arguments: OneTimeReminderDetailArgs(reminderId: item.id),
    );
  }

  void _openCtaTarget(List<OneTimeReminderModel> items, DateTime date) {
    if (items.length == 1) {
      _openDetail(items.first);
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.scheduleDay,
      arguments: ScheduleDayArgs(date: dateOnly(date)),
    );
  }

  void _openForm({OneTimeReminderModel? reminder, DateTime? initialDate}) {
    Navigator.of(context).pushNamed(
      AppRoutes.scheduleForm,
      arguments: ScheduleFormArgs(reminder: reminder, initialDate: initialDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final bool isId = localeCode == 'id';
    final List<OneTimeReminderModel> all =
        ref.watch(oneTimeRemindersStreamProvider).value ??
        const <OneTimeReminderModel>[];
    final Map<String, List<OneTimeReminderModel>> byDate = _groupByDate(all);
    final List<DateTime> days = _windowDays;
    final DateTime today = dateOnly(DateTime.now());
    final List<OneTimeReminderModel> upcomingAll = all
        .where(
          (item) =>
              !dateOnly(item.scheduledAt).isBefore(today),
        )
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final List<DateTime> upcomingDates = <DateTime>[];
    for (final OneTimeReminderModel item in upcomingAll) {
      final DateTime date = dateOnly(item.scheduledAt);
      if (upcomingDates.isEmpty || upcomingDates.last != date) {
        upcomingDates.add(date);
      }
    }
    final DateTime? overrideDate = _dateOverride;
    final List<OneTimeReminderModel> overrideItems = overrideDate == null
        ? const <OneTimeReminderModel>[]
        : byDate[dateKeyFromDate(overrideDate)] ??
              const <OneTimeReminderModel>[];
    final List<OneTimeReminderModel> shownFlat = overrideDate != null
        ? overrideItems
        : (_upcomingOnly
              ? upcomingAll
              : byDate[dateKeyFromDate(today)] ??
                    const <OneTimeReminderModel>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        tooltip: isId ? 'Buat Jadwal' : 'Create schedule',
        onPressed: () => _openForm(initialDate: _selectedDate),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: NousenBottomNavBar(
        tabs: <NousenNavTab>[
          NousenNavTab(
            icon: Icons.home_rounded,
            label: isId ? 'Harian' : 'Daily',
            onTap: () => Navigator.of(context).pop(),
          ),
          NousenNavTab(
            icon: Icons.calendar_today_rounded,
            label: isId ? 'Agenda' : 'Agenda',
            isSelected: true,
            onTap: () {},
          ),
          NousenNavTab(
            icon: Icons.insights_rounded,
            label: isId ? 'Statistik' : 'Analytics',
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.activitySummary),
          ),
          NousenNavTab(
            icon: Icons.person_rounded,
            label: isId ? 'Pengaturan' : 'Profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsPage(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: <Widget>[
          Text(
            isId ? 'Atur waktu, jalani harimu.' : 'Plan your time, make the most of your day.',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isId
                ? 'Lihat agenda dan rencanakan hari-hari ke depan.'
                : 'Review your agenda and plan the days ahead.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: _weekOffset == 0
                                  ? null
                                  : _resetToCurrentFortnight,
                              child: Text(
                                '${formatDateShort(days.first, localeCode)} \u2013 ${formatDateShort(days.last, localeCode)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Q${((days.last.month - 1) ~/ 3) + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => _shiftWindow(-1),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => _shiftWindow(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    for (int w = 1; w <= 7; w++)
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: Center(
                            child: Text(
                              weekdayShortLabel(w, localeCode),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: w == DateTime.sunday
                                    ? const Color(0xFFEF4444)
                                    : (w == today.weekday &&
                                              _inWindow(today) &&
                                              _weekOffset == 0
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 38 / 48,
                  ),
                  itemCount: days.length,
                  itemBuilder: (BuildContext context, int index) {
                    final DateTime date = days[index];
                    final bool hasItems =
                        (byDate[dateKeyFromDate(date)]?.isNotEmpty ?? false);
                    final bool isToday = date == today;
                    final bool isSelected = date == _selectedDate;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectDate(date),
                      child: _DateCell(
                        date: date,
                        hasItems: hasItems,
                        isToday: isToday,
                        isSelected: isSelected,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _MatrixLegend(
                      color: const Color(0xFF1D4ED8),
                      filled: true,
                      label: isId ? 'Ada Jadwal' : 'Scheduled',
                    ),
                    const SizedBox(width: 12),
                    _MatrixLegend(
                      color: const Color(0xFF1D4ED8),
                      filled: false,
                      label: isId ? 'Hari Ini' : 'Today',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _AgendaFilterPill(
                            label: isId ? 'Hari Ini' : 'Today',
                            selected:
                                !_upcomingOnly && _dateOverride == null,
                            onTap: () => setState(() {
                              _upcomingOnly = false;
                              _dateOverride = null;
                              _selectedDate = today;

                            }),
                          ),
                          _AgendaFilterPill(
                            label: isId ? 'Agenda' : 'Agenda',
                            selected: _upcomingOnly && _dateOverride == null,
                            onTap: () => setState(() {
                              _upcomingOnly = true;
                              _dateOverride = null;

                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (all.isEmpty) ...<Widget>[
            _EmptySchedulePanel(
              localeCode: localeCode,
              onAddSchedule: () => _openForm(initialDate: _selectedDate),
            ),
          ] else if (overrideDate != null) ...<Widget>[
            _DayAgendaSection(
              date: overrideDate,
              items: overrideItems,
              isToday: overrideDate == today,
              localeCode: localeCode,
              onOpenDetail: _openDetail,
            ),
          ] else if (!_upcomingOnly) ...<Widget>[
            _DayAgendaSection(
              date: today,
              items:
                  byDate[dateKeyFromDate(today)] ??
                  const <OneTimeReminderModel>[],
              isToday: true,
              localeCode: localeCode,
              onOpenDetail: _openDetail,
            ),
          ] else ...<Widget>[
            ...upcomingDates.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DayAgendaGroupCard(
                  date: d,
                  items: byDate[dateKeyFromDate(d)]!,
                  isToday: d == today,
                  localeCode: localeCode,
                      onOpenDetail: _openDetail,
                ),
              ),
            ),
            if (upcomingDates.isEmpty)
              Text(
                isId
                    ? 'Belum ada jadwal mendatang.'
                    : 'No upcoming schedules yet.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
          ],
          if (all.isNotEmpty &&
              shownFlat.isNotEmpty &&
              (_dateOverride != null || !_upcomingOnly)) ...<Widget>[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                  elevation: 4,
                ),
                onPressed: () => _openCtaTarget(
                  shownFlat,
                  _dateOverride ?? today,
                ),
                icon: const Icon(Icons.description_outlined, size: 19),
                label: Text(
                  isId ? 'Detail Jadwal' : 'Schedule details',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _AgendaFilterPill extends StatelessWidget {
  const _AgendaFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySchedulePanel extends StatelessWidget {
  const _EmptySchedulePanel({
    required this.localeCode,
    required this.onAddSchedule,
  });

  final String localeCode;
  final VoidCallback onAddSchedule;

  @override
  Widget build(BuildContext context) {
    final bool isId = localeCode == 'id';
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              isId
                  ? 'Tidak ada jadwal pada tanggal ini.'
                  : 'No schedules on this date.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isId
                  ? 'Hari terasa ringan. Mau tambah jadwal?'
                  : 'The day feels light. Add a schedule?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: onAddSchedule,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  isId ? 'Tambah jadwal' : 'Add schedule',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.hasItems,
    required this.isToday,
    required this.isSelected,
  });

  final DateTime date;
  final bool hasItems;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bool isSunday = date.weekday == DateTime.sunday;
    if (isSelected) {
      return Container(
        width: 38,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1D4ED8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${date.day}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                if (hasItems) ...<Widget>[
                  const SizedBox(width: 3),
                  Container(
                    width: 4.5,
                    height: 4.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
    if (isToday) {
      return Container(
        width: 38,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1D4ED8), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hari Ini',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
            Text(
              '${date.day}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF1D4ED8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: hasItems ? FontWeight.w700 : FontWeight.w500,
            color: isSunday
                ? const Color(0xFFEF4444)
                : hasItems
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: hasItems ? const Color(0xFF1D4ED8) : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}


class _MatrixLegend extends StatelessWidget {  const _MatrixLegend({
    required this.color,
    required this.filled,
    required this.label,
  });

  final Color color;
  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: filled ? null : Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _DayAgendaSection extends StatelessWidget {
  const _DayAgendaSection({
    required this.date,
    required this.items,
    required this.isToday,
    required this.localeCode,
    required this.onOpenDetail,
  });

  final DateTime date;
  final List<OneTimeReminderModel> items;
  final bool isToday;
  final String localeCode;
  final void Function(OneTimeReminderModel) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final bool isId = localeCode == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1D4ED8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatDateLong(date, localeCode),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isId ? 'Hari Ini' : 'Today',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              isId ? '${items.length} Aktivitas' : '${items.length} items',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            isId
                ? 'Belum ada jadwal pada tanggal ini.'
                : 'No schedules on this date yet.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AgendaCard(
                key: ValueKey<String>('agenda-${item.id}'),
                item: item,
                localeCode: localeCode,
                onOpenDetail: onOpenDetail,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayAgendaGroupCard extends StatelessWidget {
  const _DayAgendaGroupCard({
    required this.date,
    required this.items,
    required this.isToday,
    required this.localeCode,
    required this.onOpenDetail,
  });

  final DateTime date;
  final List<OneTimeReminderModel> items;
  final bool isToday;
  final String localeCode;
  final void Function(OneTimeReminderModel) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final bool isId = localeCode == 'id';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  formatDateLong(date, localeCode),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isId ? 'Hari Ini' : 'Today',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isId
                    ? '${items.length} Aktivitas'
                    : '${items.length} items',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final bool last = entry.key == items.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onOpenDetail(entry.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _AgendaTile(
                      item: entry.value,
                      localeCode: localeCode,
                      onOpenDetail: onOpenDetail,
                    ),
                  ),
                ),
                if (!last)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AgendaCard extends ConsumerStatefulWidget {
  const _AgendaCard({
    super.key,
    required this.item,
    required this.localeCode,
    required this.onOpenDetail,
  });

  final OneTimeReminderModel item;
  final String localeCode;
  final void Function(OneTimeReminderModel) onOpenDetail;

  @override
  ConsumerState<_AgendaCard> createState() => _AgendaCardState();
}

class _AgendaCardState extends ConsumerState<_AgendaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final OneTimeReminderModel item = widget.item;
    final String localeCode = widget.localeCode;
    final ThemeData theme = Theme.of(context);
    final AgendaVisualState state =
        resolveAgendaVisualState(item, DateTime.now());
    final bool ongoing = state == AgendaVisualState.ongoing;
    final Color stateColor = switch (state) {
      AgendaVisualState.done => theme.colorScheme.primary,
      AgendaVisualState.ongoing => theme.habitColors.pending,
      AgendaVisualState.missed => theme.habitColors.missed,
      AgendaVisualState.upcoming => theme.habitColors.inactive,
      AgendaVisualState.skipped => theme.habitColors.inactive,
    };
    final bool hasSubs = item.subActivities.isNotEmpty;

    return Opacity(
      // Redup mengikuti selesai keseluruhan (induk + semua sub),
      // lingkaran mencerminkan unit induk (item.isCompleted).
      opacity: state == AgendaVisualState.done ? 0.5 : 1.0,
      child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onOpenDetail(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state == AgendaVisualState.done
                ? theme.colorScheme.primary
                : state == AgendaVisualState.upcoming
                ? const Color(0xFFE2E8F0)
                : stateColor,
            width: ongoing || state == AgendaVisualState.done ? 1.5 : 1.0,
          ),
          boxShadow: ongoing || state == AgendaVisualState.done
              ? <BoxShadow>[
                  BoxShadow(
                    color: stateColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: _AgendaTile(
                    item: item,
                    localeCode: localeCode,
                    onOpenDetail: widget.onOpenDetail,
                  ),
                ),
                if (hasSubs)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 22,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                // Paling kanan: tombol Selesai (tukar posisi dengan dropdown).
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    await ref
                        .read(oneTimeReminderActionsProvider)
                        .toggleCompletion(
                          reminder: item,
                          completed: !item.isCompleted,
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      item.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 26,
                      color: item.isCompleted
                          ? theme.colorScheme.primary
                          : stateColor,
                    ),
                  ),
                ),
              ],
            ),
            if (hasSubs && _expanded)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.subActivities.map((String sub) {
                    final bool checked =
                        item.completedSubActivities.contains(sub);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        await ref
                            .read(oneTimeReminderActionsProvider)
                            .toggleSubActivity(
                              reminder: item,
                              subActivity: sub,
                              completed: !checked,
                            );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: checked,
                                checkColor: Colors.transparent,
                                activeColor: stateColor,
                                side: BorderSide(
                                  color: stateColor,
                                  width: 2,
                                ),
                                onChanged: (bool? value) async {
                                  await ref
                                      .read(
                                        oneTimeReminderActionsProvider,
                                      )
                                      .toggleSubActivity(
                                        reminder: item,
                                        subActivity: sub,
                                        completed: value ?? false,
                                      );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sub,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: stateColor,
                                  fontWeight: checked
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({
    required this.item,
    required this.localeCode,
    required this.onOpenDetail,
  });

  final OneTimeReminderModel item;
  final String localeCode;
  final void Function(OneTimeReminderModel) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isId = localeCode == 'id';
    final AgendaVisualState state =
        resolveAgendaVisualState(item, DateTime.now());
    final Color stateColor = switch (state) {
      AgendaVisualState.done => theme.colorScheme.primary,
      AgendaVisualState.ongoing => theme.habitColors.pending,
      AgendaVisualState.missed => theme.habitColors.missed,
      AgendaVisualState.upcoming => theme.habitColors.inactive,
      AgendaVisualState.skipped => theme.habitColors.inactive,
    };
    final String startText = formatMinutesAsTime(
      item.scheduledAt.hour * 60 + item.scheduledAt.minute,
    );
    final DateTime? end = item.scheduledEndAt;
    final String endText = end == null
        ? ''
        : formatMinutesAsTime(end.hour * 60 + end.minute);
    final int subTotal = item.subActivities.length;

    return Row(
          children: <Widget>[
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    startText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: state == AgendaVisualState.done
                          ? stateColor
                          : state == AgendaVisualState.upcoming
                          ? theme.habitColors.inactive
                          : state == AgendaVisualState.missed
                          ? theme.habitColors.missed
                          : stateColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (endText.isNotEmpty)
                    Text(
                      endText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (subTotal > 0) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      isId
                          ? '$subTotal sub aktivitas'
                          : '$subTotal sub-activities',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ] else
                    Text(
                      isId ? 'Agenda terjadwal' : 'Scheduled agenda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
  }
}

class ScheduleDayArgs {
  const ScheduleDayArgs({required this.date});

  final DateTime date;
}

class ScheduleDayPage extends ConsumerWidget {
  const ScheduleDayPage({super.key, required this.args});

  final ScheduleDayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final bool isId = localeCode == 'id';
    final DateTime date = dateOnly(args.date);
    final List<OneTimeReminderModel> all =
        ref.watch(oneTimeRemindersStreamProvider).value ??
        const <OneTimeReminderModel>[];
    final List<OneTimeReminderModel> items = all
        .where((item) => dateOnly(item.scheduledAt) == date)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leadingWidth: 64,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Text(
          isId ? 'Jadwal tanggal ini' : 'This date\u2019s schedules',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          if (items.isEmpty)
            Text(
              isId
                  ? 'Belum ada jadwal pada tanggal ini.'
                  : 'No schedules on this date yet.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            )
          else
            _DayAgendaGroupCard(
              date: date,
              items: items,
              isToday: date == dateOnly(DateTime.now()),
              localeCode: localeCode,
              onOpenDetail: (item) => Navigator.of(context).pushNamed(
                AppRoutes.oneTimeReminderDetail,
                arguments: OneTimeReminderDetailArgs(reminderId: item.id),
              ),
            ),
        ],
      ),
    );
  }
}
