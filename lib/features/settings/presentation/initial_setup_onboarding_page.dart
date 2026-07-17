import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/features/home/presentation/home_shell_page.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';

class InitialSetupOnboardingPage extends ConsumerStatefulWidget {
  const InitialSetupOnboardingPage({
    super.key,
    this.returnToPreviousPage = false,
  });

  final bool returnToPreviousPage;

  @override
  ConsumerState<InitialSetupOnboardingPage> createState() =>
      _InitialSetupOnboardingPageState();
}

class _InitialSetupOnboardingPageState
    extends ConsumerState<InitialSetupOnboardingPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _extraNoteController =
      TextEditingController();

  int _currentPage = 0;
  double _dragDx = 0;
  static const int _totalPages = 4;
  _OnboardingActivityOption _activityOption =
      _OnboardingActivityOption.noFixedSchedule;
  _DayPreset _dayPreset = _DayPreset.weekdays;
  Set<int> _customDays = <int>{1, 2, 3, 4, 5};
  int? _startMinutes;
  int? _endMinutes;
  int? _wakeUpMinutes;
  int? _sleepMinutes;
  int? _breakStartMinutes;
  int? _breakEndMinutes;
  bool _didSeedFromSettings = false;
  bool _isSaving = false;

  bool get _requiresRoutineDetails =>
      _activityOption != _OnboardingActivityOption.noFixedSchedule;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _extraNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSettingsModel settings =
        ref.watch(settingsStreamProvider).value ??
        const AppSettingsModel(
          morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
          endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
          localeCode: AppConstants.localeId,
        );
    final String localeCode = settings.localeCode;
    final bool isId = localeCode == AppConstants.localeId;

    if (!_didSeedFromSettings) {
      _seedFromSettings(settings);
      _didSeedFromSettings = true;
    }

    return Scaffold(
      appBar: _currentPage == 0
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 48,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: _currentPage / (_totalPages - 1)),
                          duration: const Duration(milliseconds: 300),
                          builder: (BuildContext context, double value, Widget? child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 3,
                              backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                              color: Theme.of(context).colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _isSaving ? null : () => _skip(settings, localeCode),
                      child: Text(
                        isId ? 'Lewati' : 'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) {
                    _dragDx = 0;
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    _dragDx += details.delta.dx;
                  },
                  onHorizontalDragEnd: (DragEndDetails details) {
                    final double velocity = details.primaryVelocity ?? 0;
                    final bool enoughDistance = _dragDx.abs() > 28;
                    final bool enoughVelocity = velocity.abs() > 180;
                    if (!enoughDistance && !enoughVelocity) {
                      _dragDx = 0;
                      return;
                    }

                    if (_dragDx < 0 || velocity < 0) {
                      _moveToPage(_currentPage + 1);
                    } else if (_dragDx > 0 || velocity > 0) {
                      _moveToPage(_currentPage - 1);
                    }
                    _dragDx = 0;
                  },
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: <Widget>[
                      _buildWelcomeSlide(context, localeCode: localeCode),
                      _buildUserSlide(context, localeCode: localeCode),
                      _buildRoutineSlide(context, localeCode: localeCode),
                      _buildExtraInfoSlide(context, localeCode: localeCode),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _OnboardingActions(
                isFirst: _currentPage == 0,
                isLast: _currentPage == _totalPages - 1,
                isBusy: _isSaving,
                backLabel: isId ? 'Kembali' : 'Back',
                nextLabel: _currentPage == 0
                    ? (isId ? 'Mulai' : 'Get Started')
                    : (isId ? 'Lanjut' : 'Next'),
                finishLabel: isId ? 'Simpan & mulai' : 'Save & start',
                onBack: () => _moveToPage(_currentPage - 1),
                onNext: () => _moveToPage(_currentPage + 1),
                onFinish: () => _finish(settings),
              ),
              const SizedBox(height: 20),
              _OnboardingDots(
                currentIndex: _currentPage,
                total: _totalPages,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide(
    BuildContext context, {
    required String localeCode,
  }) {
    final bool isId = localeCode == AppConstants.localeId;
    final ThemeData theme = Theme.of(context);
    return _OnboardingSlideShell(
      title: isId ? 'Selamat datang!' : 'Welcome!',
      subtitle: isId
          ? 'Yuk kenalan dulu, biar kami bisa bantu atur jadwal liburanmu.'
          : "Let's get to know you so we can help organize your schedule.",
      centerContent: true,
      centerHeader: true,
      topWidget: Column(
        children: <Widget>[
          const _GengarMascot(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Nousen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildUserSlide(
    BuildContext context, {
    required String localeCode,
  }) {
    final bool isId = localeCode == AppConstants.localeId;
    return _OnboardingSlideShell(
      title: isId ? 'Kamu ingin dipanggil apa?' : 'What should we call you?',
      subtitle: isId
          ? 'Nama ini akan kami pakai untuk menyapa kamu setiap hari.'
          : "We'll use this name to greet you every day.",
      centerContent: true,
      centerHeader: true,
      topWidget: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: _UserAvatarPainter(
            primary: Theme.of(context).colorScheme.primary,
            surface: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 280,
            child: TextField(
              controller: _nameController,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: isId ? 'Nama panggilanmu' : 'Your nickname',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSlide(
    BuildContext context, {
    required String localeCode,
  }) {
    final bool isId = localeCode == AppConstants.localeId;
    final ThemeData theme = Theme.of(context);

    return _OnboardingSlideShell(
      title: isId ? 'Apa aktivitas utama kamu?' : 'What is your main activity?',
      subtitle: isId
          ? 'Ini membantu kami menyesuaikan jadwal dan pengingat untukmu.'
          : 'This helps us tailor your schedule and reminders.',
      centerContent: true,
      topWidget: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: _CalendarIllustrationPainter(
            primary: Theme.of(context).colorScheme.primary,
            surface: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            accent: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _OnboardingActivityOption.values
                .map(
                  (_OnboardingActivityOption option) {
                    final bool isSelected = _activityOption == option;
                    return ChoiceChip(
                      label: Text(option.label(localeCode)),
                      selected: isSelected,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _activityOption = option;
                        });
                      },
                    );
                  },
                )
                .toList(growable: false),
          ),
          if (_requiresRoutineDetails) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              isId ? 'Hari aktif' : 'Active days',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _DayPreset.values
                  .map(
                    (_DayPreset preset) {
                      final bool isSelected = _dayPreset == preset;
                      return ChoiceChip(
                        label: Text(preset.label(localeCode)),
                        selected: isSelected,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        labelStyle: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                        ),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _dayPreset = preset;
                            if (preset != _DayPreset.custom) {
                              _customDays = preset.days.toSet();
                            }
                          });
                        },
                      );
                    },
                  )
                  .toList(growable: false),
            ),
            if (_dayPreset == _DayPreset.custom) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(7, (int index) {
                  final int weekday = index + 1;
                  final bool selected = _customDays.contains(weekday);
                  return FilterChip(
                    label: Text(_weekdayShortLabel(weekday, localeCode)),
                    selected: selected,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Theme.of(context).colorScheme.onPrimary : null,
                    ),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected ? Colors.transparent : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    onSelected: (bool nextValue) {
                      setState(() {
                        if (nextValue) {
                          _customDays.add(weekday);
                        } else {
                          _customDays.remove(weekday);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 20),
            _OnboardingTimeRow(
              title: isId ? 'Jam mulai' : 'Start time',
              value: _timeValue(_startMinutes, localeCode),
              onTap: () async {
                final int? next = await _pickMinutesInputDialog(
                  context: context,
                  currentMinutes: _startMinutes ?? 8 * 60,
                  localeCode: localeCode,
                );
                if (next == null) {
                  return;
                }
                setState(() {
                  _startMinutes = next;
                });
              },
            ),
            const SizedBox(height: 16),
            _OnboardingTimeRow(
              title: isId ? 'Jam selesai' : 'End time',
              value: _timeValue(_endMinutes, localeCode),
              onTap: () async {
                final int? next = await _pickMinutesInputDialog(
                  context: context,
                  currentMinutes: _endMinutes ?? 17 * 60,
                  localeCode: localeCode,
                );
                if (next == null) {
                  return;
                }
                setState(() {
                  _endMinutes = next;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraInfoSlide(
    BuildContext context, {
    required String localeCode,
  }) {
    final bool isId = localeCode == AppConstants.localeId;
    return _OnboardingSlideShell(
      title: isId ? 'Ada aktivitas lain?' : 'Any other activities?',
      subtitle: isId
          ? 'Opsional. Ceritakan aktivitas lainnya agar kami lebih mengenal rutinitasmu.'
          : 'Optional. Tell us about other activities so we understand your routine better.',
      centerContent: true,
      topWidget: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: _NotepadIllustrationPainter(
            primary: Theme.of(context).colorScheme.primary,
            surface: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            accent: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _extraNoteController,
            minLines: 6,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: isId
                  ? 'Contoh:\n- Gym setiap Selasa & Kamis sore\n- Les bahasa Inggris Sabtu pagi\n- Jalan-jalan sore hari Minggu'
                  : 'Example:\n- Gym every Tuesday & Thursday evening\n- English class Saturday morning\n- Sunday afternoon walks',
              hintMaxLines: 6,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _seedFromSettings(AppSettingsModel settings) {
    _nameController.text = (settings.profileName ?? '').trim();
    _extraNoteController.text = (settings.extraActivitiesNote ?? '').trim();
    _wakeUpMinutes = settings.wakeUpMinutes;
    _sleepMinutes = settings.sleepMinutes;
    _breakStartMinutes = settings.usualBreakStartMinutes;
    _breakEndMinutes = settings.usualBreakEndMinutes;

    final List<WeeklyRoutineDayProfile> activeDays = settings.normalizedWeeklyRoutine
        .where((WeeklyRoutineDayProfile item) {
          return item.kind != WeeklyRoutineDayKind.unspecified &&
              item.kind != WeeklyRoutineDayKind.off;
        })
        .toList(growable: false);

    if (activeDays.isNotEmpty) {
      final WeeklyRoutineDayProfile first = activeDays.first;
      _activityOption = _OnboardingActivityOption.fromRoutineKind(first.kind);
      _customDays = activeDays
          .map((WeeklyRoutineDayProfile item) => item.weekday)
          .toSet();
      _dayPreset = _presetFromDays(_customDays);
      _startMinutes = first.startMinutes ?? _startMinutes;
      _endMinutes = first.endMinutes ?? _endMinutes;
    }
  }

  Future<void> _skip(AppSettingsModel settings, String localeCode) async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final String existingName = (settings.profileName ?? '').trim();
    final String fallbackName = existingName.isNotEmpty
        ? existingName
        : (localeCode == AppConstants.localeId ? 'Pengguna' : 'User');
    await ref.read(settingsRepositoryProvider).save(
      settings.copyWith(
        profileName: fallbackName,
        extraActivitiesNote: _normalizedExtraNote(),
        clearExtraActivitiesNote: _normalizedExtraNote().isEmpty,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    _leaveOnboarding();
  }

  Future<void> _finish(AppSettingsModel settings) async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final String normalizedName = _normalizeName(_nameController.text);
    final String extraActivitiesNote = _normalizedExtraNote();
    final List<WeeklyRoutineDayProfile> routine = _buildRoutine();
    final String finalName = normalizedName.isEmpty
        ? ((settings.profileName ?? '').trim().isNotEmpty
              ? settings.profileName!.trim()
              : (settings.localeCode == AppConstants.localeId
                    ? 'Pengguna'
                    : 'User'))
        : normalizedName;

    await ref.read(settingsRepositoryProvider).save(
      settings.copyWith(
        profileName: finalName,
        extraActivitiesNote: extraActivitiesNote,
        clearExtraActivitiesNote: extraActivitiesNote.isEmpty,
        weeklyRoutine: routine,
        wakeUpMinutes: _wakeUpMinutes,
        clearWakeUpMinutes: _wakeUpMinutes == null,
        sleepMinutes: _sleepMinutes,
        clearSleepMinutes: _sleepMinutes == null,
        usualBreakStartMinutes: _breakStartMinutes,
        clearUsualBreakStartMinutes: _breakStartMinutes == null,
        usualBreakEndMinutes: _breakEndMinutes,
        clearUsualBreakEndMinutes: _breakEndMinutes == null,
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    _leaveOnboarding();
  }

  void _leaveOnboarding() {
    if (widget.returnToPreviousPage) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShellPage()),
    );
  }

  List<WeeklyRoutineDayProfile> _buildRoutine() {
    if (!_requiresRoutineDetails) {
      return kDefaultWeeklyRoutine;
    }

    final Set<int> selectedDays = _dayPreset == _DayPreset.custom
        ? _customDays
        : _dayPreset.days.toSet();
    if (selectedDays.isEmpty) {
      return kDefaultWeeklyRoutine;
    }
    final WeeklyRoutineDayKind routineKind = _activityOption.routineKind;

    return List<WeeklyRoutineDayProfile>.generate(7, (int index) {
      final int weekday = index + 1;
      if (!selectedDays.contains(weekday)) {
        return WeeklyRoutineDayProfile(
          weekday: weekday,
          kind: WeeklyRoutineDayKind.off,
        );
      }
      return WeeklyRoutineDayProfile(
        weekday: weekday,
        kind: routineKind,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
      );
    }, growable: false);
  }

  _DayPreset _presetFromDays(Set<int> days) {
    for (final _DayPreset preset in _DayPreset.values) {
      if (preset == _DayPreset.custom) {
        continue;
      }
      if (days.length == preset.days.length &&
          days.containsAll(preset.days)) {
        return preset;
      }
    }
    return _DayPreset.custom;
  }

  String _timeValue(int? minutes, String localeCode) {
    if (minutes == null) {
      return localeCode == AppConstants.localeId
          ? 'Belum diatur'
          : 'Not set';
    }
    return formatMinutesAsTime(minutes);
  }

  String _normalizeName(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  String _normalizedExtraNote() {
    return _extraNoteController.text.trim();
  }

  void _moveToPage(int page) {
    if (page < 0 || page > _totalPages - 1 || page == _currentPage) {
      return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
    );
  }
}

enum _OnboardingActivityOption {
  work,
  college,
  school,
  freelance,
  flexible,
  noFixedSchedule;

  String label(String localeCode) {
    final bool isId = localeCode == AppConstants.localeId;
    switch (this) {
      case _OnboardingActivityOption.work:
        return isId ? 'Bekerja' : 'Working';
      case _OnboardingActivityOption.college:
        return isId ? 'Kuliah' : 'College';
      case _OnboardingActivityOption.school:
        return isId ? 'Sekolah' : 'School';
      case _OnboardingActivityOption.freelance:
        return isId ? 'Usaha / Freelance' : 'Business / Freelance';
      case _OnboardingActivityOption.flexible:
        return isId ? 'Fleksibel' : 'Flexible';
      case _OnboardingActivityOption.noFixedSchedule:
        return isId ? 'Belum ada jadwal tetap' : 'No fixed schedule';
    }
  }

  WeeklyRoutineDayKind get routineKind {
    switch (this) {
      case _OnboardingActivityOption.work:
        return WeeklyRoutineDayKind.work;
      case _OnboardingActivityOption.college:
        return WeeklyRoutineDayKind.college;
      case _OnboardingActivityOption.school:
        return WeeklyRoutineDayKind.school;
      case _OnboardingActivityOption.freelance:
        return WeeklyRoutineDayKind.custom;
      case _OnboardingActivityOption.flexible:
        return WeeklyRoutineDayKind.flexible;
      case _OnboardingActivityOption.noFixedSchedule:
        return WeeklyRoutineDayKind.unspecified;
    }
  }

  static _OnboardingActivityOption fromRoutineKind(WeeklyRoutineDayKind kind) {
    switch (kind) {
      case WeeklyRoutineDayKind.work:
        return _OnboardingActivityOption.work;
      case WeeklyRoutineDayKind.college:
        return _OnboardingActivityOption.college;
      case WeeklyRoutineDayKind.school:
        return _OnboardingActivityOption.school;
      case WeeklyRoutineDayKind.custom:
        return _OnboardingActivityOption.freelance;
      case WeeklyRoutineDayKind.flexible:
        return _OnboardingActivityOption.flexible;
      case WeeklyRoutineDayKind.off:
      case WeeklyRoutineDayKind.unspecified:
        return _OnboardingActivityOption.noFixedSchedule;
    }
  }
}

enum _DayPreset {
  weekdays(<int>[1, 2, 3, 4, 5]),
  weekdaysPlusSaturday(<int>[1, 2, 3, 4, 5, 6]),
  weekend(<int>[6, 7]),
  custom(<int>[]);

  const _DayPreset(this.days);

  final List<int> days;

  String label(String localeCode) {
    final bool isId = localeCode == AppConstants.localeId;
    switch (this) {
      case _DayPreset.weekdays:
        return isId ? 'Senin - Jumat' : 'Monday - Friday';
      case _DayPreset.weekdaysPlusSaturday:
        return isId ? 'Senin - Sabtu' : 'Monday - Saturday';
      case _DayPreset.weekend:
        return isId ? 'Sabtu - Minggu' : 'Saturday - Sunday';
      case _DayPreset.custom:
        return isId ? 'Kustom' : 'Custom';
    }
  }
}

class _OnboardingSlideShell extends StatelessWidget {
  const _OnboardingSlideShell({
    required this.title,
    required this.child,
    this.subtitle,
    this.centerContent = false,
    this.centerHeader = false,
    this.topWidget,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool centerContent;
  final bool centerHeader;
  final Widget? topWidget;

  @override
  Widget build(BuildContext context) {
    if (centerContent) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: centerHeader
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: <Widget>[
                      if (topWidget != null) ...<Widget>[
                        topWidget!,
                        const SizedBox(height: 32),
                      ],
                      Text(
                        title,
                        textAlign:
                            centerHeader ? TextAlign.center : TextAlign.start,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          subtitle!,
                          textAlign:
                              centerHeader ? TextAlign.center : TextAlign.start,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (topWidget != null) ...<Widget>[
          topWidget!,
          const SizedBox(height: 32),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ],
    );
  }
}

class _GengarMascot extends StatelessWidget {
  const _GengarMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 150,
      child: CustomPaint(
        painter: _GengarMascotPainter(
          primary: const Color(0xFF9A7FD1),
          secondary: const Color(0xFF7E63B8),
          eye: const Color(0xFFF47A8D),
          outline: const Color(0xFF2A2140),
          smile: Colors.white,
        ),
      ),
    );
  }
}

class _GengarMascotPainter extends CustomPainter {
  _GengarMascotPainter({
    required this.primary,
    required this.secondary,
    required this.eye,
    required this.outline,
    required this.smile,
  });

  final Color primary;
  final Color secondary;
  final Color eye;
  final Color outline;
  final Color smile;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()..color = primary;
    final Paint detailPaint = Paint()..color = secondary;
    final Paint outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Rect bodyRect = Rect.fromLTWH(
      size.width * 0.17,
      size.height * 0.30,
      size.width * 0.66,
      size.height * 0.54,
    );
    final RRect body = RRect.fromRectAndRadius(
      bodyRect,
      const Radius.circular(34),
    );
    canvas.drawRRect(body, fillPaint);
    canvas.drawRRect(body, outlinePaint);

    final Path leftEar = Path()
      ..moveTo(size.width * 0.24, size.height * 0.38)
      ..lineTo(size.width * 0.10, size.height * 0.08)
      ..lineTo(size.width * 0.36, size.height * 0.20)
      ..close();
    final Path rightEar = Path()
      ..moveTo(size.width * 0.76, size.height * 0.38)
      ..lineTo(size.width * 0.90, size.height * 0.08)
      ..lineTo(size.width * 0.64, size.height * 0.20)
      ..close();
    canvas.drawPath(leftEar, fillPaint);
    canvas.drawPath(rightEar, fillPaint);
    canvas.drawPath(leftEar, outlinePaint);
    canvas.drawPath(rightEar, outlinePaint);

    final Path leftArm = Path()
      ..moveTo(size.width * 0.28, size.height * 0.50)
      ..lineTo(size.width * 0.08, size.height * 0.44)
      ..lineTo(size.width * 0.13, size.height * 0.59)
      ..lineTo(size.width * 0.30, size.height * 0.58)
      ..close();
    final Path rightArm = Path()
      ..moveTo(size.width * 0.72, size.height * 0.50)
      ..lineTo(size.width * 0.92, size.height * 0.44)
      ..lineTo(size.width * 0.87, size.height * 0.59)
      ..lineTo(size.width * 0.70, size.height * 0.58)
      ..close();
    canvas.drawPath(leftArm, fillPaint);
    canvas.drawPath(rightArm, fillPaint);
    canvas.drawPath(leftArm, outlinePaint);
    canvas.drawPath(rightArm, outlinePaint);

    final Path leftEye = Path()
      ..moveTo(size.width * 0.35, size.height * 0.48)
      ..lineTo(size.width * 0.47, size.height * 0.42)
      ..lineTo(size.width * 0.42, size.height * 0.54)
      ..lineTo(size.width * 0.31, size.height * 0.55)
      ..close();
    final Path rightEye = Path()
      ..moveTo(size.width * 0.65, size.height * 0.48)
      ..lineTo(size.width * 0.53, size.height * 0.42)
      ..lineTo(size.width * 0.58, size.height * 0.54)
      ..lineTo(size.width * 0.69, size.height * 0.55)
      ..close();
    canvas.drawPath(leftEye, Paint()..color = eye);
    canvas.drawPath(rightEye, Paint()..color = eye);
    canvas.drawPath(leftEye, outlinePaint);
    canvas.drawPath(rightEye, outlinePaint);

    final RRect mouth = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.60,
        size.width * 0.38,
        size.height * 0.13,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(mouth, Paint()..color = smile);
    canvas.drawRRect(mouth, outlinePaint);

    final Paint toothPaint = Paint()
      ..color = outline.withValues(alpha: 0.42)
      ..strokeWidth = 1.2;
    for (int i = 1; i <= 5; i++) {
      final double x = mouth.left + (mouth.width / 6) * i;
      canvas.drawLine(
        Offset(x, mouth.top + 4),
        Offset(x - 2, mouth.bottom - 4),
        toothPaint,
      );
    }

    final Paint cheekPaint = Paint()
      ..color = detailPaint.color.withValues(alpha: 0.20);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.70,
        size.width * 0.15,
        size.height * 0.08,
      ),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.60,
        size.height * 0.70,
        size.width * 0.15,
        size.height * 0.08,
      ),
      cheekPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OnboardingFieldCard extends StatelessWidget {
  const _OnboardingFieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: child,
    );
  }
}

class _OnboardingTimeRow extends StatelessWidget {
  const _OnboardingTimeRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OnboardingFieldCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.35);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(total, (int index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.isFirst,
    required this.isLast,
    required this.isBusy,
    required this.backLabel,
    required this.nextLabel,
    required this.finishLabel,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
  });

  final bool isFirst;
  final bool isLast;
  final bool isBusy;
  final String backLabel;
  final String nextLabel;
  final String finishLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          if (!isFirst) ...<Widget>[
            SizedBox(
              width: 52,
              height: 52,
              child: IconButton(
                onPressed: isBusy ? null : onBack,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: isBusy ? null : (isLast ? onFinish : onNext),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(isLast ? finishLabel : nextLabel),
                  if (!isLast) ...<Widget>[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatarPainter extends CustomPainter {
  _UserAvatarPainter({
    required this.primary,
    required this.surface,
  });

  final Color primary;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.45;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = surface,
    );

    canvas.drawCircle(
      Offset(cx, cy - r * 0.18),
      r * 0.32,
      Paint()..color = primary,
    );

    final Path bodyPath = Path()
      ..moveTo(cx - r * 0.55, cy + r * 0.72)
      ..quadraticBezierTo(cx - r * 0.55, cy + r * 0.20, cx, cy + r * 0.20)
      ..quadraticBezierTo(cx + r * 0.55, cy + r * 0.20, cx + r * 0.55, cy + r * 0.72);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = primary
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = primary.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CalendarIllustrationPainter extends CustomPainter {
  _CalendarIllustrationPainter({
    required this.primary,
    required this.surface,
    required this.accent,
  });

  final Color primary;
  final Color surface;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final RRect calBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.18, w * 0.80, h * 0.72),
      const Radius.circular(12),
    );
    canvas.drawRRect(calBody, Paint()..color = surface);
    canvas.drawRRect(
      calBody,
      Paint()
        ..color = primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final RRect header = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.10, h * 0.18, w * 0.80, h * 0.18),
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );
    canvas.drawRRect(header, Paint()..color = primary);

    final Paint ringPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final double xFrac in <double>[0.32, 0.50, 0.68]) {
      canvas.drawLine(
        Offset(w * xFrac, h * 0.12),
        Offset(w * xFrac, h * 0.24),
        ringPaint,
      );
    }

    final Paint dotPaint = Paint()..color = primary.withValues(alpha: 0.35);
    final Paint activeDot = Paint()..color = accent;
    final double dotR = w * 0.035;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        final double dx = w * 0.22 + col * (w * 0.14);
        final double dy = h * 0.48 + row * (h * 0.14);
        final bool isHighlight = (row == 1 && col == 2);
        canvas.drawCircle(
          Offset(dx, dy),
          isHighlight ? dotR * 1.8 : dotR,
          isHighlight ? activeDot : dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotepadIllustrationPainter extends CustomPainter {
  _NotepadIllustrationPainter({
    required this.primary,
    required this.surface,
    required this.accent,
  });

  final Color primary;
  final Color surface;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final RRect page = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.08, w * 0.70, h * 0.84),
      const Radius.circular(10),
    );
    canvas.drawRRect(page, Paint()..color = surface);
    canvas.drawRRect(
      page,
      Paint()
        ..color = primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final Paint spiralPaint = Paint()
      ..color = primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final double y = h * 0.18 + i * (h * 0.14);
      canvas.drawCircle(Offset(w * 0.18, y), 3, spiralPaint);
    }

    final Paint linePaint = Paint()
      ..color = primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final List<double> lineLengths = <double>[0.50, 0.42, 0.55, 0.35, 0.48];
    for (int i = 0; i < 5; i++) {
      final double y = h * 0.18 + i * (h * 0.14);
      canvas.drawLine(
        Offset(w * 0.28, y),
        Offset(w * 0.28 + w * lineLengths[i], y),
        linePaint,
      );
    }

    final Paint checkPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path checkPath = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..lineTo(w * 0.32, h * 0.21)
      ..lineTo(w * 0.40, h * 0.14);
    canvas.drawPath(checkPath, checkPaint);

    final Path checkPath2 = Path()
      ..moveTo(w * 0.28, h * 0.32)
      ..lineTo(w * 0.32, h * 0.35)
      ..lineTo(w * 0.40, h * 0.28);
    canvas.drawPath(checkPath2, checkPaint);

    final Path pencilBody = Path()
      ..moveTo(w * 0.72, h * 0.62)
      ..lineTo(w * 0.88, h * 0.78)
      ..lineTo(w * 0.84, h * 0.82)
      ..lineTo(w * 0.68, h * 0.66)
      ..close();
    canvas.drawPath(pencilBody, Paint()..color = primary);

    final Path pencilTip = Path()
      ..moveTo(w * 0.68, h * 0.66)
      ..lineTo(w * 0.84, h * 0.82)
      ..lineTo(w * 0.65, h * 0.72)
      ..close();
    canvas.drawPath(pencilTip, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _weekdayShortLabel(int weekday, String localeCode) {
  const List<String> idDays = <String>[
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];
  const List<String> enDays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final int safeIndex = weekday.clamp(1, 7) - 1;
  return localeCode == AppConstants.localeId
      ? idDays[safeIndex]
      : enDays[safeIndex];
}

Future<int?> _pickMinutesInputDialog({
  required BuildContext context,
  required int currentMinutes,
  required String localeCode,
}) async {
  final TimeOfDay initial = TimeOfDay(
    hour: currentMinutes ~/ 60,
    minute: currentMinutes % 60,
  );
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: initial,
    initialEntryMode: TimePickerEntryMode.inputOnly,
    helpText: localeCode == AppConstants.localeId
        ? 'Masukkan waktu'
        : 'Enter time',
    cancelText: localeCode == AppConstants.localeId ? 'Batal' : 'Cancel',
    confirmText: localeCode == AppConstants.localeId ? 'Oke' : 'OK',
    hourLabelText: localeCode == AppConstants.localeId ? 'Jam' : 'Hour',
    minuteLabelText: localeCode == AppConstants.localeId
        ? 'Menit'
        : 'Minute',
  );
  if (picked == null) {
    return null;
  }
  return timeOfDayToMinutes(picked.hour, picked.minute);
}
