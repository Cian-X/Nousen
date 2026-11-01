import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nousen/app/providers.dart';
import 'package:nousen/app/router.dart';
import 'package:nousen/core/constants/app_constants.dart';
import 'package:nousen/core/theme/app_layout.dart';
import 'package:nousen/core/theme/app_theme.dart';
import 'package:nousen/core/utils/date_utils.dart';
import 'package:nousen/core/utils/time_utils.dart';
import 'package:nousen/core/widgets/checklist_confirm_dialog.dart';
import 'package:nousen/core/widgets/nousen_bottom_nav_bar.dart';
import 'package:nousen/core/widgets/nousen_nav_icon.dart';
import 'package:nousen/features/activity/domain/activity_daily_progress_status.dart';
import 'package:nousen/features/activity/data/activity_sync_failures.dart';
import 'package:nousen/features/activity/presentation/activity_card_sync_badge.dart';
import 'package:nousen/features/activity/presentation/activity_sync_messages.dart';
import 'package:nousen/features/activity/presentation/activity_status_visuals.dart';
import 'package:nousen/features/activity/domain/activity_progress_summary.dart';
import 'package:nousen/features/activity/domain/activity_model.dart';
import 'package:nousen/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:nousen/features/one_time_reminder/presentation/schedule_agenda_page.dart';
import 'package:nousen/features/one_time_reminder/presentation/schedule_form_page.dart';
import 'package:nousen/features/one_time_reminder/data/one_time_reminder_sync_failures.dart';
import 'package:nousen/features/one_time_reminder/presentation/one_time_reminder_sync_messages.dart';
import 'package:nousen/features/progress/data/progress_sync_failures.dart';
import 'package:nousen/features/progress/domain/progress_entry_model.dart';
import 'package:nousen/features/progress/presentation/progress_sync_messages.dart';
import 'package:nousen/features/settings/data/settings_sync_failures.dart';
import 'package:nousen/features/settings/domain/app_settings_model.dart';
import 'package:nousen/features/settings/presentation/settings_sync_messages.dart';
import 'package:nousen/features/settings/presentation/settings_page.dart';
import 'package:nousen/l10n/app_localizations.dart';
import 'package:nousen/services/widget_sync_service.dart';

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();

  /// Whether Navigator can pop above this page (used by [PopScope]).
  static bool canPopAbove(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  Timer? _countdownTimer;
  DateTime? _selectedDate;
  String _activeFilter = 'today';
  StreamSubscription<ActivitySyncFailure>? _activitySyncFailureSub;
  StreamSubscription<ProgressSyncFailure>? _progressSyncFailureSub;
  StreamSubscription<OneTimeReminderSyncFailure>? _reminderSyncFailureSub;
  StreamSubscription<SettingsSyncFailure>? _settingsSyncFailureSub;

  @override
  void initState() {
    super.initState();
    _startMinuteTicker();
    _activitySyncFailureSub = ref
        .read(activitySyncFailuresProvider)
        .events
        .listen(_onActivitySyncFailure);
    _progressSyncFailureSub = ref
        .read(progressSyncFailuresProvider)
        .events
        .listen(_onProgressSyncFailure);
    _reminderSyncFailureSub = ref
        .read(oneTimeReminderSyncFailuresProvider)
        .events
        .listen(_onOneTimeReminderSyncFailure);
    _settingsSyncFailureSub = ref
        .read(settingsSyncFailuresProvider)
        .events
        .listen(_onSettingsSyncFailure);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _activitySyncFailureSub?.cancel();
    _progressSyncFailureSub?.cancel();
    _reminderSyncFailureSub?.cancel();
    _settingsSyncFailureSub?.cancel();
    super.dispose();
  }

  /// Reject server dari tulis cloud-first di-surfacekan (tidak senyap).
  void _onActivitySyncFailure(ActivitySyncFailure failure) {
    if (!mounted) {
      return;
    }
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activitySyncFailureSnackMessage(isId: isId, failure: failure),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Reject server dari tulis progress cloud-first (S2) — non-silent.
  void _onProgressSyncFailure(ProgressSyncFailure failure) {
    if (!mounted) {
      return;
    }
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          progressSyncFailureSnackMessage(isId: isId, failure: failure),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Reject server dari tulis reminder/note cloud-first (S3) — non-silent.
  void _onOneTimeReminderSyncFailure(OneTimeReminderSyncFailure failure) {
    if (!mounted) {
      return;
    }
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          oneTimeReminderSyncFailureSnackMessage(
            isId: isId,
            failure: failure,
          ),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Reject server dari tulis settings cloud-first (S3) — non-silent.
  void _onSettingsSyncFailure(SettingsSyncFailure failure) {
    if (!mounted) {
      return;
    }
    final bool isId = Localizations.localeOf(context).languageCode == 'id';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          settingsSyncFailureSnackMessage(isId: isId, failure: failure),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _startMinuteTicker() {
    _countdownTimer?.cancel();
    final DateTime now = DateTime.now();
    final int msToNextMinute = ((60 - now.second) * 1000) - now.millisecond;
    _countdownTimer = Timer(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  Future<void> _openActivityForm() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.createActivity,
      arguments: const CreateActivityArgs(),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  Future<void> _showAddOptions(DateTime selectedDate, String localeCode) async {
    final bool isId = localeCode == 'id';
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.repeat_rounded, color: Color(0xFF3B7BD6)),
                  title: Text(isId ? 'Aktivitas Rutin' : 'Daily Activity'),
                  subtitle: Text(isId ? 'Aktivitas berulang harian' : 'Recurring daily activity'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openActivityForm();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_note_rounded, color: Color(0xFF3B7BD6)),
                  title: Text(isId ? 'Agenda' : 'One-Time Agenda'),
                  subtitle: Text(isId ? 'Jadwal / pengingat sekali jalan' : 'One-time schedule / reminder'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed(
                      AppRoutes.scheduleForm,
                      arguments: ScheduleFormArgs(initialDate: selectedDate),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSettingsModel settings =
        ref.watch(settingsStreamProvider).value ??
        const AppSettingsModel(
          morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
          endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
          localeCode: AppConstants.localeId,
        );
    final String localeCode = settings.localeCode;

    final DateTime now = DateTime.now();
    final DateTime today = dateOnly(now);
    final DateTime selectedDate = _selectedDate ?? today;
    final int selectedWeekday = selectedDate.weekday;

    final String profileName = _resolvedHomeProfileName(settings.profileName);
    final String contextualGreeting = _contextualGreeting(
      localeCode: localeCode,
      hour: now.hour,
      profileName: profileName,
    );
    final bool selectedIsToday = isSameDay(selectedDate, today);
    final String selectedDateKey = dateKeyFromDate(selectedDate);

    final List<ActivityModel> allActivities =
        ref.watch(activitiesStreamProvider).value ?? const <ActivityModel>[];
    final List<ProgressEntryModel> allProgress =
        ref.watch(progressByDateProvider(selectedDateKey)).value ??
        const <ProgressEntryModel>[];
    final Map<String, ProgressEntryModel> selectedProgressByActivity =
        <String, ProgressEntryModel>{
          for (final ProgressEntryModel entry in allProgress)
            if (entry.dateKey == selectedDateKey) entry.activityId: entry,
        };

    final List<ActivityModel> filteredActivities =
        allActivities.where((ActivityModel activity) {
          return activity.selectedDays.contains(selectedWeekday);
        }).toList()..sort((ActivityModel a, ActivityModel b) {
          return a.timeMinutes.compareTo(b.timeMinutes);
        });

    final List<_ActivityTileData> activityItems = <_ActivityTileData>[];
    bool focusAssigned = false;
    for (final ActivityModel activity in filteredActivities) {
      final ProgressEntryModel? progress =
          selectedProgressByActivity[activity.id];
      final DateTime scheduleUpdatedAt =
          activity.scheduleUpdatedAt ?? activity.createdAt;
      final ActivityDailyProgressStatus status =
          resolveActivityDailyProgressStatus(
            scheduledDate: selectedDate,
            today: now,
            scheduleUpdatedAt: scheduleUpdatedAt,
            subActivities: activity.subActivities,
            scheduledTimeMinutes: activity.timeMinutes,
            entry: progress,
          );
      final bool isFocus =
          !focusAssigned &&
          (!selectedIsToday ||
              (status != ActivityDailyProgressStatus.done &&
                  status != ActivityDailyProgressStatus.skipped));
      if (isFocus) {
        focusAssigned = true;
      }
      activityItems.add(
        _ActivityTileData(
          activity: activity,
          scheduledDate: selectedDate,
          progressEntry: progress,
          status: status,
          isFocus: isFocus,
        ),
      );
    }
    final bool hasActivities = activityItems.isNotEmpty;

    final List<OneTimeReminderModel> allReminders =
        ref.watch(oneTimeRemindersStreamProvider).value ??
            const <OneTimeReminderModel>[];
    final List<OneTimeReminderModel> dayReminders = allReminders
        .where((OneTimeReminderModel r) =>
            dateKeyFromDate(r.scheduledAt) == selectedDateKey)
        .toList();
    final int currentStreak = ref.watch(homeGlobalStreakProvider);

    final String todayDateKey = dateKeyFromDate(today);
    final List<ProgressEntryModel> todayProgress =
        ref.watch(progressByDateProvider(todayDateKey)).value ??
            const <ProgressEntryModel>[];
    final List<OneTimeReminderModel> todayReminders = allReminders
        .where((r) => dateKeyFromDate(r.scheduledAt) == todayDateKey)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetSyncService.updateWidget(
        activities: allActivities,
        todayProgress: todayProgress,
        todayReminders: todayReminders,
      );
    });

    final int daysSinceSunday = today.weekday % 7;
    final DateTime startSunday = today.subtract(Duration(days: daysSinceSunday));
    final List<DateTime> twoWeeksDays = List<DateTime>.generate(
      14,
      (int index) => startSunday.add(Duration(days: index)),
    );

    final Set<String> scheduledDateKeys = <String>{};
    for (final DateTime d in twoWeeksDays) {
      final String dk = dateKeyFromDate(d);
      final bool hasActivity = allActivities.any(
        (ActivityModel a) => a.selectedDays.contains(d.weekday),
      );
      final bool hasReminder = allReminders.any(
        (OneTimeReminderModel r) => dateKeyFromDate(r.scheduledAt) == dk,
      );
      if (hasActivity || hasReminder) {
        scheduledDateKeys.add(dk);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Prevent back gesture from freezing the app when at root route.
        // We intentionally do nothing — the app stays open.
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOptions(selectedDate, localeCode),
          tooltip: localeCode == 'id' ? 'Tambah' : 'Add',
          backgroundColor: const Color(0xFF3B7BD6),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 8,
          child: const Icon(Icons.add, size: 28),
        ),
        bottomNavigationBar: NousenBottomNavBar(
          tabs: <NousenNavTab>[
            NousenNavTab(
              icon: Icons.check_circle_outline_rounded,
              label: localeCode == 'id' ? 'Aktivitas' : 'Activities',
              isSelected: true,
              onTap: () {},
            ),
            NousenNavTab(
              icon: Icons.person_rounded,
              label: localeCode == 'id' ? 'Pengaturan' : 'Profile',
              onTap: _openSettings,
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isWide = constraints.maxWidth >= 700;
              final bool isLarge = constraints.maxWidth >= 1100;
              final double sidePadding = isWide ? 24 : 16;
              final double contentMaxWidth = isLarge ? 980 : 760;
              final double contentWidth = constraints.maxWidth < contentMaxWidth
                  ? constraints.maxWidth
                  : contentMaxWidth;

              final List<Widget> listItems = <Widget>[
                RepaintBoundary(
                  child: _HomeTopContent(
                    profileName: profileName,
                    contextualGreeting: contextualGreeting,
                    todayDate: today,
                    selectedDate: selectedDate,
                    twoWeeksDays: twoWeeksDays,
                    scheduledDateKeys: scheduledDateKeys,
                    activeFilter: _activeFilter,
                    localeCode: localeCode,
                    sidePadding: sidePadding,
                    currentStreak: currentStreak,
                    onDateSelected: (DateTime date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      ref
                          .read(homeSelectedWeekdayProvider.notifier)
                          .state = date.weekday;
                    },
                    onFilterChanged: (String filter) {
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                  ),
                ),
              ];

              if (_activeFilter == 'agenda') {
                if (dayReminders.isNotEmpty) {
                  listItems.add(
                    Padding(
                      padding: EdgeInsets.fromLTRB(sidePadding, 4, sidePadding, 8),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.event_note_rounded,
                            size: 16,
                            color: Color(0xFF3B7BD6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Agenda (${dayReminders.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  for (final OneTimeReminderModel reminder in dayReminders) {
                    listItems.add(
                      Padding(
                        key: ValueKey<String>('agenda-${reminder.id}'),
                        padding: EdgeInsets.only(
                          bottom: 10,
                          left: sidePadding,
                          right: sidePadding,
                        ),
                        child: AgendaCard(
                          item: reminder,
                          localeCode: localeCode,
                          onOpenDetail: (OneTimeReminderModel item) {
                            Navigator.of(context).pushNamed(
                              AppRoutes.oneTimeReminderDetail,
                              arguments:
                                  OneTimeReminderDetailArgs(reminderId: item.id),
                            );
                          },
                        ),
                      ),
                    );
                  }
                } else {
                  listItems.add(
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 32,
                      ),
                      child: Center(
                        child: Text(
                          localeCode == 'id'
                              ? 'Tidak ada agenda untuk tanggal ini.'
                              : 'No agenda for this date.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                if (dayReminders.isNotEmpty) {
                  listItems.add(
                    Padding(
                      padding: EdgeInsets.fromLTRB(sidePadding, 4, sidePadding, 8),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.event_note_rounded,
                            size: 16,
                            color: Color(0xFF3B7BD6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Agenda (${dayReminders.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  for (final OneTimeReminderModel reminder in dayReminders) {
                    listItems.add(
                      Padding(
                        key: ValueKey<String>('agenda-${reminder.id}'),
                        padding: EdgeInsets.only(
                          bottom: 10,
                          left: sidePadding,
                          right: sidePadding,
                        ),
                        child: AgendaCard(
                          item: reminder,
                          localeCode: localeCode,
                          onOpenDetail: (OneTimeReminderModel item) {
                            Navigator.of(context).pushNamed(
                              AppRoutes.oneTimeReminderDetail,
                              arguments:
                                  OneTimeReminderDetailArgs(reminderId: item.id),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }

                if (hasActivities) {
                  if (dayReminders.isNotEmpty) {
                    listItems.add(
                      Padding(
                        padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 8),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.repeat_rounded,
                              size: 16,
                              color: Color(0xFF3B7BD6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localeCode == 'id'
                                  ? 'Aktivitas Harian (${activityItems.length})'
                                  : 'Daily Activities (${activityItems.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  for (int i = 0; i < activityItems.length; i++) {
                    final _ActivityTileData item = activityItems[i];
                    listItems.add(
                      Padding(
                        key: ValueKey<String>(
                          '$selectedDateKey-${item.activity.id}',
                        ),
                        padding: EdgeInsets.only(
                          top: (i == 0 && dayReminders.isEmpty) ? 0 : 10,
                          left: sidePadding,
                          right: sidePadding,
                        ),
                        child: RepaintBoundary(
                          child: _ActivityCard(
                            item: item,
                            canToggleToday: selectedIsToday,
                          ),
                        ),
                      ),
                    );
                  }
                }

                if (!hasActivities && dayReminders.isEmpty) {
                  listItems.add(
                    Padding(
                      key: ValueKey<String>('activity-empty-$selectedWeekday'),
                      padding: EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 24,
                      ),
                      child: RepaintBoundary(
                        child: _EmptyActivitiesPanel(
                          localeCode: localeCode,
                          onAddTap: _openActivityForm,
                        ),
                      ),
                    ),
                  );
                } else {
                  listItems.add(
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 32,
                      ),
                      child: Text(
                        localeCode == 'id'
                            ? 'Tekan + untuk menambah aktivitas atau agenda'
                            : 'Tap + to add an activity or agenda',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
              }

              return Stack(
                children: <Widget>[
                  Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: ListView.builder(
                        cacheExtent: 720,
                        padding: EdgeInsets.only(
                          bottom: AppSpacing.screenPadding,
                        ),
                        itemCount: listItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          return listItems[index];
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _resolvedHomeProfileName(String? rawName) {
    final String trimmed = (rawName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Pengguna';
    }
    return trimmed;
  }

  String _contextualGreeting({
    required String localeCode,
    required int hour,
    required String profileName,
  }) {
    if (localeCode == 'id') {
      if (hour < 11) {
        return 'Selamat pagi, $profileName';
      } else if (hour < 15) {
        return 'Selamat siang, $profileName';
      } else if (hour < 18) {
        return 'Selamat sore, $profileName';
      }
      return 'Selamat malam, $profileName';
    }
    if (hour < 12) {
      return 'Good morning, $profileName';
    } else if (hour < 17) {
      return 'Good afternoon, $profileName';
    }
    return 'Good evening, $profileName';
  }
}

class _HomeTopContent extends StatelessWidget {
  const _HomeTopContent({
    required this.profileName,
    required this.contextualGreeting,
    required this.todayDate,
    required this.selectedDate,
    required this.twoWeeksDays,
    required this.scheduledDateKeys,
    required this.activeFilter,
    required this.localeCode,
    required this.sidePadding,
    required this.currentStreak,
    required this.onDateSelected,
    required this.onFilterChanged,
  });

  final String profileName;
  final String contextualGreeting;
  final DateTime todayDate;
  final DateTime selectedDate;
  final List<DateTime> twoWeeksDays;
  final Set<String> scheduledDateKeys;
  final String activeFilter;
  final String localeCode;
  final double sidePadding;
  final int currentStreak;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String formattedDate = DateFormat(
      'EEEE, d MMMM',
      localeCode,
    ).format(todayDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      contextualGreeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Text(
                          toBeginningOfSentenceCase(formattedDate) ??
                              formattedDate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (currentStreak > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentStreak.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: _HomeCalendarSelector(
            todayDate: todayDate,
            selectedDate: selectedDate,
            twoWeeksDays: twoWeeksDays,
            scheduledDateKeys: scheduledDateKeys,
            activeFilter: activeFilter,
            localeCode: localeCode,
            onDateSelected: onDateSelected,
            onFilterChanged: onFilterChanged,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _HomeCalendarSelector extends StatelessWidget {
  const _HomeCalendarSelector({
    required this.todayDate,
    required this.selectedDate,
    required this.twoWeeksDays,
    required this.scheduledDateKeys,
    required this.activeFilter,
    required this.localeCode,
    required this.onDateSelected,
    required this.onFilterChanged,
  });

  final DateTime todayDate;
  final DateTime selectedDate;
  final List<DateTime> twoWeeksDays;
  final Set<String> scheduledDateKeys;
  final String activeFilter;
  final String localeCode;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String> onFilterChanged;

  static const List<String> _weekdayLabels = <String>[
    'Min',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime startDate = twoWeeksDays.first;
    final DateTime endDate = twoWeeksDays.last;
    final String rangeLabel =
        '${DateFormat('dd MMM', localeCode).format(startDate)} – ${DateFormat('dd MMM', localeCode).format(endDate)}';
    final int quarter = ((startDate.month - 1) ~/ 3) + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header: Calendar Icon + Range + Quarter Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: Color(0xFF3B7BD6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rangeLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Q$quarter',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Labels
          Row(
            children: List<Widget>.generate(7, (int col) {
              final String label = _weekdayLabels[col];
              final bool isSunday = col == 0;
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSunday
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // 14 Days Grid (Row 1 + Row 2)
          Column(
            children: <Widget>[
              Row(
                children: List<Widget>.generate(7, (int col) {
                  final DateTime date = twoWeeksDays[col];
                  return Expanded(
                    child: _CalendarDayCell(
                      date: date,
                      isSelected: isSameDay(date, selectedDate),
                      isToday: isSameDay(date, todayDate),
                      isSunday: col == 0,
                      hasSchedule: scheduledDateKeys.contains(
                        dateKeyFromDate(date),
                      ),
                      onTap: () => onDateSelected(date),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: List<Widget>.generate(7, (int col) {
                  final DateTime date = twoWeeksDays[7 + col];
                  return Expanded(
                    child: _CalendarDayCell(
                      date: date,
                      isSelected: isSameDay(date, selectedDate),
                      isToday: isSameDay(date, todayDate),
                      isSunday: col == 0,
                      hasSchedule: scheduledDateKeys.contains(
                        dateKeyFromDate(date),
                      ),
                      onTap: () => onDateSelected(date),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
            color: Color(0xFFF1F5F9),
            height: 1,
          ),
          const SizedBox(height: 12),

          // Footer: Legend + Segmented Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Legend
              Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B7BD6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    localeCode == 'id' ? 'Ada Jadwal' : 'Scheduled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B7BD6),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    localeCode == 'id' ? 'Hari Ini' : 'Today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // Segmented Switch
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
                    GestureDetector(
                      onTap: () => onFilterChanged('today'),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: activeFilter == 'today'
                            ? BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.06,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              )
                            : null,
                        child: Text(
                          localeCode == 'id' ? 'Hari Ini' : 'Today',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: activeFilter == 'today'
                                ? const Color(0xFF3B7BD6)
                                : const Color(0xFF64748B),
                            fontWeight: activeFilter == 'today'
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onFilterChanged('agenda'),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: activeFilter == 'agenda'
                            ? BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.06,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              )
                            : null,
                        child: Text(
                          'Agenda',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: activeFilter == 'agenda'
                                ? const Color(0xFF3B7BD6)
                                : const Color(0xFF64748B),
                            fontWeight: activeFilter == 'agenda'
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isSunday,
    required this.hasSchedule,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isSunday;
  final bool hasSchedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String dayStr = date.day.toString();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 38,
          height: 44,
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFF3B7BD6),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                dayStr,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isSunday
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0F172A)),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
              else if (hasSchedule)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B7BD6),
                    shape: BoxShape.circle,
                  ),
                )
              else if (isToday)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3B7BD6),
                      width: 1.2,
                    ),
                  ),
                )
              else
                const SizedBox(width: 4, height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTileData {
  const _ActivityTileData({
    required this.activity,
    required this.scheduledDate,
    required this.status,
    required this.isFocus,
    this.progressEntry,
  });

  final ActivityModel activity;
  final DateTime scheduledDate;
  final ProgressEntryModel? progressEntry;
  final ActivityDailyProgressStatus status;
  final bool isFocus;

  bool get isCompleted => status == ActivityDailyProgressStatus.done;
  bool get isSkipped => status == ActivityDailyProgressStatus.skipped;
}

class _ActivityCard extends ConsumerStatefulWidget {
  const _ActivityCard({required this.item, required this.canToggleToday});

  final _ActivityTileData item;
  final bool canToggleToday;

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  bool _isExpanded = false;

  Color _subActivityCompletedColor({
    required ThemeData theme,
    required ActivityDailyProgressStatus activityStatus,
  }) {
    return activityStatusColor(theme: theme, status: activityStatus);
  }

  Color _subActivityIncompleteColor({
    required ThemeData theme,
    required ActivityDailyProgressStatus activityStatus,
  }) {
    return switch (activityStatus) {
      ActivityDailyProgressStatus.partial => theme.habitColors.pending,
      ActivityDailyProgressStatus.missed => theme.habitColors.missed,
      ActivityDailyProgressStatus.skipped ||
      ActivityDailyProgressStatus.future ||
      ActivityDailyProgressStatus.done =>
        theme.colorScheme.onSurface.withValues(alpha: 0.45),
    };
  }

  @override
  Widget build(BuildContext context) {
    final _ActivityTileData item = widget.item;
    final bool canToggleToday = widget.canToggleToday;
    final bool isExpanded = _isExpanded;
    final AppLocalizations t = AppLocalizations.of(context)!;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ThemeData theme = Theme.of(context);
    final ActivityModel activity = item.activity;
    final ProgressEntryModel? entry = item.progressEntry;
    final ActivityDailyProgressStatus dailyStatus = item.status;

    final List<String> completedSubActivities = normalizeCompletedSubActivities(
      completedValues: entry?.completedSubActivities ?? const <String>[],
      subActivities: activity.subActivities,
    );
    final int subTotal = activity.subActivities.length;

    final Color borderColor;
    final Color cardBg;
    switch (dailyStatus) {
      case ActivityDailyProgressStatus.done:
        borderColor = theme.colorScheme.primary;
        cardBg = Colors.white;
        break;
      case ActivityDailyProgressStatus.partial:
        borderColor = theme.habitColors.pending;
        cardBg = Colors.white;
        break;
      case ActivityDailyProgressStatus.missed:
        borderColor = theme.habitColors.missed.withValues(alpha: 0.4);
        cardBg = Colors.white;
        break;
      case ActivityDailyProgressStatus.skipped:
      case ActivityDailyProgressStatus.future:
        borderColor = const Color(0xFFE2E8F0);
        cardBg = Colors.white;
        break;
    }

    return Opacity(
      opacity: item.isCompleted ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: dailyStatus == ActivityDailyProgressStatus.done ||
                      dailyStatus == ActivityDailyProgressStatus.partial
                  ? 1.5
                  : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: dailyStatus == ActivityDailyProgressStatus.done
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : dailyStatus == ActivityDailyProgressStatus.partial
                    ? theme.habitColors.pending.withValues(alpha: 0.12)
                    : const Color(0x141A5BAD), // soft-elevation
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.activityDetail,
                arguments: ActivityDetailArgs(
                  activityId: activity.id,
                  scheduledDate: widget.item.scheduledDate,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Kolom waktu (kiri) mengikuti pola kartu Agenda.
                      SizedBox(
                        width: 56,
                        child: Text(
                          formatMinutesAsTime(activity.timeMinutes),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: dailyStatus ==
                                    ActivityDailyProgressStatus.done
                                ? theme.colorScheme.primary
                                : dailyStatus ==
                                      ActivityDailyProgressStatus.partial
                                ? theme.habitColors.pending
                                : dailyStatus ==
                                      ActivityDailyProgressStatus.missed
                                ? theme.habitColors.missed
                                : theme.habitColors.inactive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Middle: Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    activity.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                          decoration: null,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ActivityCardSyncBadge(
                                  activityId: activity.id,
                                  entryId: entry?.id,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.subActivities.isNotEmpty
                                  ? (localeCode == 'id'
                                        ? '${activity.subActivities.length} sub aktivitas'
                                        : '${activity.subActivities.length} sub-activities')
                                  : (localeCode == 'id'
                                        ? 'Rutinitas harian'
                                        : 'Daily routine'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Kanan: chevron dropdown sub (ala kartu Agenda).
                      if (subTotal > 0)
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: NousenNavIcon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 22,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      // Paling kanan: tombol Selesai (tukar posisi dengan dropdown).
                      // Lingkaran mencerminkan unit induk (entry.status),
                      // sedangkan redup kartu mengikuti selesai keseluruhan.
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: canToggleToday
                            ? () async {
                                await ref
                                    .read(activityActionsProvider)
                                    .toggleTodayCompletion(
                                      activity: activity,
                                      completed:
                                          !(entry?.isCompleted == true),
                                    );
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: NousenNavIcon(
                            entry?.isCompleted == true
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 26,
                            color: entry?.isCompleted == true
                                ? theme.colorScheme.primary
                                : (canToggleToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.3,
                                        )),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Expandable subtasks checklist
                  if (subTotal > 0 && isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 70),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: activity.subActivities.map((
                          String subActivity,
                        ) {
                          final bool checked = completedSubActivities.contains(
                            subActivity,
                          );
                          Future<void> toggleSub(bool next) async {
                            final bool confirmed =
                                await showChecklistConfirmDialog(
                                  context: context,
                                  title: t.checklistConfirmTitle,
                                  message: t.checklistConfirmMessage,
                                  cancelLabel: t.cancel,
                                  confirmLabel: t.checklistConfirmAction,
                                );
                            if (!confirmed) {
                              return;
                            }
                            await ref
                                .read(activityActionsProvider)
                                .toggleTodaySubActivity(
                                  activity: activity,
                                  subActivity: subActivity,
                                  completed: next,
                                );
                          }

                          final Color completedColor =
                              _subActivityCompletedColor(
                                theme: theme,
                                activityStatus: dailyStatus,
                              );
                          final Color incompleteColor =
                              _subActivityIncompleteColor(
                                theme: theme,
                                activityStatus: dailyStatus,
                              );
                          final Color subIndicatorColor = checked
                              ? completedColor
                              : incompleteColor;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: canToggleToday
                                ? () => toggleSub(!checked)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: checked,
                                      checkColor: Colors.transparent,
                                      activeColor: completedColor,
                                      side: BorderSide(
                                        color: subIndicatorColor,
                                        width: 2,
                                      ),
                                      onChanged: canToggleToday
                                          ? (bool? next) =>
                                                toggleSub(next ?? false)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subActivity,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 13,
                                            color: subIndicatorColor,
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
        ),
      ),
    );
  }
}

class _EmptyActivitiesPanel extends StatelessWidget {
  const _EmptyActivitiesPanel({
    required this.localeCode,
    required this.onAddTap,
  });

  final String localeCode;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              localeCode == 'id'
                  ? 'Tidak ada aktivitas hari ini.'
                  : 'No activities today.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localeCode == 'id'
                  ? 'Hari terasa ringan. Mau tambah target kecil?'
                  : 'The day feels light. Add a small target?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddTap,
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
              icon: NousenNavIcon(Icons.add, size: 20),
              label: Text(
                localeCode == 'id' ? 'Tambah aktivitas' : 'Add activity',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
