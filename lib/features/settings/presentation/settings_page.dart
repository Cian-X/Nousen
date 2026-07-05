import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/core/constants/app_constants.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/l10n/app_localizations.dart';
import 'package:liburan_create/features/settings/domain/app_settings_model.dart';
import 'package:liburan_create/features/settings/domain/weekly_routine_models.dart';
import 'package:liburan_create/features/settings/presentation/initial_setup_onboarding_page.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kFeedbackUrl = 'https://www.instagram.com/muzaky7_/';

void _disposeTextControllerSafely(TextEditingController controller) {
  Future<void>.delayed(const Duration(milliseconds: 1200), () {
    try {
      controller.dispose();
    } catch (_) {
      // Controller may already be detached/disposed during dialog teardown.
    }
  });
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({
    super.key,
    this.forceUserSetup = false,
    this.onInitialSetupComplete,
  });

  final bool forceUserSetup;
  final VoidCallback? onInitialSetupComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final AppSettingsModel settings =
        ref.watch(settingsStreamProvider).value ??
        const AppSettingsModel(
          morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
          endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
          localeCode: AppConstants.localeId,
        );
    final String localeCode = settings.localeCode;
    final bool isId = localeCode == AppConstants.localeId;
    final String userInfoSummary = _userInfoSummary(
      settings,
      localeCode: localeCode,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !forceUserSetup,
        title: Text(isId ? 'Pengaturan' : 'Settings'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          final bool isLarge = constraints.maxWidth >= 1100;
          final double sidePadding = isWide ? 24 : 16;
          final double contentMaxWidth = isLarge ? 760 : 680;
          final double contentWidth = constraints.maxWidth < contentMaxWidth
              ? constraints.maxWidth
              : contentMaxWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  AppSpacing.screenPadding,
                  sidePadding,
                  AppSpacing.screenPadding,
                ),
                children: <Widget>[
                  if (forceUserSetup) ...<Widget>[
                    _InitialSetupNotice(
                      localeCode: localeCode,
                      isReady: !settings.needsInitialUserSetup,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _SectionLabel(title: isId ? 'Pengguna' : 'User'),
                  const SizedBox(height: 12),
                  _SectionList(
                    children: <Widget>[
                      _SettingsActionItem(
                        icon: Icons.person_outline_rounded,
                        title: isId ? 'Info pengguna' : 'User info',
                        value: userInfoSummary,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => UserInfoPage(
                                initialSetup: forceUserSetup,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (!forceUserSetup) ...<Widget>[
                    const SizedBox(height: 24),
                    _SectionLabel(title: isId ? 'Reminder' : 'Reminder'),
                    const SizedBox(height: 12),
                    _SectionList(
                      children: <Widget>[
                        _SettingsSwitchItem(
                          icon: Icons.notifications_active_outlined,
                          title: isId
                              ? 'Aktifkan notifikasi'
                              : 'Enable notifications',
                          value: settings.notificationsEnabled,
                          onChanged: (bool nextValue) async {
                            await _updateNotificationsEnabled(
                              context: context,
                              ref: ref,
                              settings: settings,
                              enabled: nextValue,
                            );
                          },
                        ),
                        _SettingsActionItem(
                          icon: Icons.wb_sunny_rounded,
                          title: t.morningReminderTime,
                          value: formatMinutesAsTime(
                            settings.morningReminderMinutes,
                          ),
                          enabled: settings.notificationsEnabled,
                          onTap: () async {
                            final int? next = await _pickMinutes(
                              context,
                              settings.morningReminderMinutes,
                            );
                            if (next == null) {
                              return;
                            }
                            await ref.read(settingsRepositoryProvider).save(
                              settings.copyWith(morningReminderMinutes: next),
                            );
                            await ref
                                .read(activityActionsProvider)
                                .bootstrapRescheduleAndEvaluate();
                            await ref
                                .read(oneTimeReminderActionsProvider)
                                .bootstrapReschedule();
                          },
                        ),
                        _SettingsActionItem(
                          icon: Icons.nightlight_round,
                          title: t.endOfDayReminderTime,
                          value: formatMinutesAsTime(
                            settings.endOfDayReminderMinutes,
                          ),
                          enabled: settings.notificationsEnabled,
                          onTap: () async {
                            final int? next = await _pickMinutes(
                              context,
                              settings.endOfDayReminderMinutes,
                            );
                            if (next == null) {
                              return;
                            }
                            await ref.read(settingsRepositoryProvider).save(
                              settings.copyWith(
                                endOfDayReminderMinutes: next,
                              ),
                            );
                            await ref
                                .read(activityActionsProvider)
                                .bootstrapRescheduleAndEvaluate();
                            await ref
                                .read(oneTimeReminderActionsProvider)
                                .bootstrapReschedule();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(title: t.language),
                    const SizedBox(height: 12),
                    _SectionList(
                      children: <Widget>[
                        _SettingsActionItem(
                          icon: Icons.language_rounded,
                          title: isId ? 'Bahasa aplikasi' : 'App language',
                          value: _languageLabel(settings.localeCode),
                          onTap: () async {
                            await _pickLanguage(
                              context: context,
                              ref: ref,
                              settings: settings,
                              localeCode: localeCode,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(title: isId ? 'Tentang' : 'About'),
                    const SizedBox(height: 12),
                    _SectionList(
                      children: <Widget>[
                        _SettingsActionItem(
                          icon: Icons.feedback_outlined,
                          title: isId ? 'Kirim feedback' : 'Send feedback',
                          onTap: () async {
                            await _openFeedback(
                              context: context,
                              localeCode: localeCode,
                            );
                          },
                        ),
                        _SettingsInfoItem(
                          icon: Icons.info_outline_rounded,
                          title: isId ? 'Versi aplikasi' : 'App version',
                          value: '1.0',
                        ),
                      ],
                    ),
                    if (kDebugMode) ...<Widget>[
                      const SizedBox(height: 24),
                      _SectionLabel(
                        title: isId ? 'Mode developer' : 'Developer mode',
                      ),
                      const SizedBox(height: 12),
                      _SectionList(
                        children: <Widget>[
                          _SettingsActionItem(
                            icon: Icons.developer_mode_rounded,
                            title: isId
                                ? 'Buka ulang onboarding'
                                : 'Open onboarding again',
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const InitialSetupOnboardingPage(
                                        returnToPreviousPage: true,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (forceUserSetup) ...<Widget>[
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: settings.needsInitialUserSetup
                          ? null
                          : (onInitialSetupComplete ??
                                () {
                                  Navigator.of(context).pushReplacementNamed('/');
                                }),
                      child: Text(
                        isId ? 'Lanjut ke aplikasi' : 'Continue to app',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _languageLabel(String localeCode) {
    return localeCode == AppConstants.localeId ? 'Indonesia' : 'English';
  }

  Future<void> _updateNotificationsEnabled({
    required BuildContext context,
    required WidgetRef ref,
    required AppSettingsModel settings,
    required bool enabled,
  }) async {
    await ref
        .read(settingsRepositoryProvider)
        .save(settings.copyWith(notificationsEnabled: enabled));
    await ref.read(activityActionsProvider).bootstrapRescheduleAndEvaluate();
    await ref.read(oneTimeReminderActionsProvider).bootstrapReschedule();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Notifikasi diaktifkan.' : 'Notifikasi dinonaktifkan.',
        ),
      ),
    );
  }

  Future<void> _pickLanguage({
    required BuildContext context,
    required WidgetRef ref,
    required AppSettingsModel settings,
    required String localeCode,
  }) async {
    final bool isId = localeCode == AppConstants.localeId;
    final String? nextLocale = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isId ? 'Pilih bahasa' : 'Choose language',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                _LanguageOptionTile(
                  label: 'Bahasa Indonesia',
                  selected: settings.localeCode == AppConstants.localeId,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(AppConstants.localeId),
                ),
                _LanguageOptionTile(
                  label: 'English',
                  selected: settings.localeCode == AppConstants.localeEn,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(AppConstants.localeEn),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (nextLocale == null || nextLocale == settings.localeCode) {
      return;
    }

    await ref
        .read(settingsRepositoryProvider)
        .save(settings.copyWith(localeCode: nextLocale));
  }

  Future<void> _openFeedback({
    required BuildContext context,
    required String localeCode,
  }) async {
    final Uri feedbackUri = Uri.parse(_kFeedbackUrl);
    final bool launched = await launchUrl(
      feedbackUri,
      mode: LaunchMode.externalApplication,
    );
    if (launched || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localeCode == AppConstants.localeId
              ? 'Link feedback belum tersedia.'
              : 'Feedback link is not available.',
        ),
      ),
    );
  }

  Future<int?> _pickMinutes(BuildContext context, int currentMinutes) async {
    return _pickMinutesInputDialog(
      context: context,
      currentMinutes: currentMinutes,
      localeCode: Localizations.localeOf(context).languageCode,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = <Widget>[];
    for (int index = 0; index < children.length; index++) {
      content.add(children[index]);
      if (index < children.length - 1) {
        content.add(
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.12),
          ),
        );
      }
    }

    return Column(children: content);
  }
}


class _SettingsActionItem extends StatelessWidget {
  const _SettingsActionItem({
    this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.enabled = true,
    required this.onTap,
  });

  final IconData? icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    final Color leadingColor = theme.colorScheme.onSurface.withValues(
      alpha: enabled ? 0.68 : 0.32,
    );
    final Widget trailingWidget = trailing ?? const _Chevron();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: leadingColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: enabled ? 0.92 : 0.42,
                        ),
                      ),
                    ),
                    if (hasValue) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        value!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: enabled ? 0.66 : 0.38,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchItem extends StatelessWidget {
  const _SettingsSwitchItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsInfoItem extends StatelessWidget {
  const _SettingsInfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.check_rounded : Icons.language_rounded,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.42),
    );
  }
}

class _InitialSetupNotice extends StatelessWidget {
  const _InitialSetupNotice({
    required this.localeCode,
    required this.isReady,
  });

  final String localeCode;
  final bool isReady;

  bool get _isId => localeCode == AppConstants.localeId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _isId ? 'Mulai dari info pengguna' : 'Start with user info',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isId
                ? 'Isi nama, rutinitas mingguan, dan kebiasaan waktumu agar AI bisa memberi saran hari serta jam yang lebih realistis.'
                : 'Fill in your name, weekly routine, and time habits so the AI can suggest more realistic days and times.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
          if (isReady) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _isId
                  ? 'Data dasar sudah siap. Kamu bisa lanjut ke aplikasi.'
                  : 'Your basic info is ready. You can continue to the app.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserInfoPage extends ConsumerWidget {
  const UserInfoPage({
    super.key,
    this.initialSetup = false,
  });

  final bool initialSetup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettingsModel settings =
        ref.watch(settingsStreamProvider).value ??
        const AppSettingsModel(
          morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
          endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
          localeCode: AppConstants.localeId,
        );
    final String localeCode = settings.localeCode;
    final bool isId = localeCode == AppConstants.localeId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isId ? 'Info pengguna' : 'User info'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          final double sidePadding = isWide ? 24 : 16;
          final double contentMaxWidth = 720;
          final double contentWidth = constraints.maxWidth < contentMaxWidth
              ? constraints.maxWidth
              : contentMaxWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  AppSpacing.screenPadding,
                  sidePadding,
                  AppSpacing.screenPadding,
                ),
                children: <Widget>[
                  if (initialSetup) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isId
                                ? 'Bantu app memahami keseharianmu'
                                : 'Help the app understand your daily life',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isId
                                ? 'Semakin lengkap data ini, semakin personal rekomendasi hari dan jam yang bisa diberikan.'
                                : 'The more complete this data is, the more personal the day and time recommendations will be.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.45,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.76),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _SectionLabel(title: isId ? 'Identitas' : 'Identity'),
                  const SizedBox(height: 12),
                  _SectionList(
                    children: <Widget>[
                      _SettingsActionItem(
                        icon: Icons.badge_outlined,
                        title: isId ? 'Nama' : 'Name',
                        value: _profileFieldValue(
                          settings.profileName,
                          localeCode: localeCode,
                        ),
                        onTap: () async {
                          await _editProfileName(
                            context: context,
                            ref: ref,
                            settings: settings,
                            localeCode: localeCode,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(
                    title: isId ? 'Rutinitas mingguan' : 'Weekly routine',
                  ),
                  const SizedBox(height: 12),
                  _SectionList(
                    children: <Widget>[
                      _SettingsActionItem(
                        icon: Icons.calendar_month_rounded,
                        title: isId
                            ? 'Kegiatan Senin - Minggu'
                            : 'Monday - Sunday routine',
                        value: _weeklyRoutineSummary(
                          settings.weeklyRoutine,
                          localeCode: localeCode,
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _WeeklyRoutinePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(
                    title: isId ? 'Aktivitas lain' : 'Other activities',
                  ),
                  const SizedBox(height: 12),
                  _SectionList(
                    children: <Widget>[
                      _SettingsActionItem(
                        icon: Icons.event_note_rounded,
                        title: isId ? 'Aktivitas lain' : 'Other activities',
                        value: _extraActivitiesValue(
                          settings.extraActivitiesNote,
                          localeCode: localeCode,
                        ),
                        onTap: () async {
                          await _editExtraActivities(
                            context: context,
                            ref: ref,
                            settings: settings,
                            localeCode: localeCode,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildTimePreferenceItem({
  required BuildContext context,
  required String title,
  required IconData icon,
  required String value,
  required Future<void> Function() onTap,
  Future<void> Function()? onClear,
}) {
  return _SettingsActionItem(
    icon: icon,
    title: title,
    value: value,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (onClear != null)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        const SizedBox(width: 6),
        const _Chevron(),
      ],
    ),
    onTap: () {
      onTap();
    },
  );
}

class _WeeklyRoutinePage extends ConsumerWidget {
  const _WeeklyRoutinePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettingsModel settings =
        ref.watch(settingsStreamProvider).value ??
        const AppSettingsModel(
          morningReminderMinutes: AppConstants.defaultMorningReminderMinutes,
          endOfDayReminderMinutes: AppConstants.defaultEndOfDayReminderMinutes,
          localeCode: AppConstants.localeId,
        );
    final String localeCode = settings.localeCode;
    final bool isId = localeCode == AppConstants.localeId;
    final List<WeeklyRoutineDayProfile> routine = settings.normalizedWeeklyRoutine;

    return Scaffold(
      appBar: AppBar(
        title: Text(isId ? 'Rutinitas mingguan' : 'Weekly routine'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isId ? 'Bantu AI memahami keseharianmu' : 'Help AI understand your weekly life',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isId
                      ? 'Atur hari kerja, kuliah, jam berangkat, pulang, dan waktu istirahat agar rekomendasi hari serta jam jadi lebih akurat.'
                      : 'Set work, college, commute, and rest times so day and time recommendations become more accurate.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final WeeklyRoutineDayProfile day in routine) ...<Widget>[
            _RoutineDayTile(
              localeCode: localeCode,
              profile: day,
              onTap: () async {
                final WeeklyRoutineDayProfile? next = await showModalBottomSheet<WeeklyRoutineDayProfile>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (BuildContext sheetContext) {
                    return _RoutineDayEditorSheet(
                      localeCode: localeCode,
                      initialProfile: day,
                    );
                  },
                );
                if (next == null) {
                  return;
                }

                final List<WeeklyRoutineDayProfile> nextRoutine =
                    settings.normalizedWeeklyRoutine
                        .map(
                          (WeeklyRoutineDayProfile item) =>
                              item.weekday == next.weekday ? next : item,
                        )
                        .toList(growable: false);

                await ref
                    .read(settingsRepositoryProvider)
                    .save(settings.copyWith(weeklyRoutine: nextRoutine));
              },
            ),
            if (day.weekday < 7)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoutineDayTile extends StatelessWidget {
  const _RoutineDayTile({
    required this.localeCode,
    required this.profile,
    required this.onTap,
  });

  final String localeCode;
  final WeeklyRoutineDayProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(
                _routineKindIcon(profile.kind),
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _weekdayFullLabel(profile.weekday, localeCode),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weeklyRoutineDaySummary(profile, localeCode: localeCode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _Chevron(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineDayEditorSheet extends StatefulWidget {
  const _RoutineDayEditorSheet({
    required this.localeCode,
    required this.initialProfile,
  });

  final String localeCode;
  final WeeklyRoutineDayProfile initialProfile;

  @override
  State<_RoutineDayEditorSheet> createState() => _RoutineDayEditorSheetState();
}

class _RoutineDayEditorSheetState extends State<_RoutineDayEditorSheet> {
  late WeeklyRoutineDayKind _kind;
  late int? _startMinutes;
  late int? _endMinutes;
  late int? _departureMinutes;
  late int? _returnMinutes;
  late int? _restStartMinutes;
  late int? _restEndMinutes;

  bool get _isId => widget.localeCode == AppConstants.localeId;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialProfile.kind;
    _startMinutes = widget.initialProfile.startMinutes;
    _endMinutes = widget.initialProfile.endMinutes;
    _departureMinutes = widget.initialProfile.departureMinutes;
    _returnMinutes = widget.initialProfile.returnMinutes;
    _restStartMinutes = widget.initialProfile.restStartMinutes;
    _restEndMinutes = widget.initialProfile.restEndMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool showMainWindow = _kind != WeeklyRoutineDayKind.off &&
        _kind != WeeklyRoutineDayKind.unspecified;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _weekdayFullLabel(widget.initialProfile.weekday, widget.localeCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isId
                    ? 'Cukup pilih jenis harinya, lalu isi mulai dan selesai aktivitas utamanya.'
                    : 'Just choose the day type, then set the main start and end time.',
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WeeklyRoutineDayKind.values
                    .map(
                      (WeeklyRoutineDayKind kind) => ChoiceChip(
                        label: Text(_routineKindLabel(kind, widget.localeCode)),
                        selected: _kind == kind,
                        onSelected: (_) {
                          setState(() {
                            _kind = kind;
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              if (showMainWindow) ...<Widget>[
                const SizedBox(height: 20),
                _RoutineTimeRow(
                  title: _isId ? 'Mulai aktivitas utama' : 'Main start',
                  value: _timeValueOrPlaceholder(_startMinutes, widget.localeCode),
                  onTap: () async {
                    final int? next = await _pickMinutesInputDialog(
                      context: context,
                      currentMinutes: _startMinutes ?? 8 * 60,
                      localeCode: widget.localeCode,
                    );
                    if (next == null) {
                      return;
                    }
                    setState(() => _startMinutes = next);
                  },
                  onClear: _startMinutes == null
                      ? null
                      : () => setState(() => _startMinutes = null),
                ),
                _RoutineTimeRow(
                  title: _isId ? 'Selesai aktivitas utama' : 'Main end',
                  value: _timeValueOrPlaceholder(_endMinutes, widget.localeCode),
                  onTap: () async {
                    final int? next = await _pickMinutesInputDialog(
                      context: context,
                      currentMinutes: _endMinutes ?? 17 * 60,
                      localeCode: widget.localeCode,
                    );
                    if (next == null) {
                      return;
                    }
                    setState(() => _endMinutes = next);
                  },
                  onClear: _endMinutes == null
                      ? null
                      : () => setState(() => _endMinutes = null),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(
                        WeeklyRoutineDayProfile(weekday: widget.initialProfile.weekday),
                      ),
                      child: Text(_isId ? 'Reset hari ini' : 'Reset this day'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_buildResult()),
                      child: Text(_isId ? 'Simpan' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  WeeklyRoutineDayProfile _buildResult() {
    final bool clearAll = _kind == WeeklyRoutineDayKind.off ||
        _kind == WeeklyRoutineDayKind.unspecified;

    return WeeklyRoutineDayProfile(
      weekday: widget.initialProfile.weekday,
      kind: _kind,
      startMinutes: clearAll ? null : _startMinutes,
      endMinutes: clearAll ? null : _endMinutes,
      departureMinutes: null,
      returnMinutes: null,
      restStartMinutes: null,
      restEndMinutes: null,
    );
  }
}

class _RoutineTimeRow extends StatelessWidget {
  const _RoutineTimeRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              const _Chevron(),
            ],
          ),
        ),
      ),
    );
  }
}

String _weeklyRoutineSummary(
  List<WeeklyRoutineDayProfile> routine, {
  required String localeCode,
}) {
  final List<WeeklyRoutineDayProfile> normalized = normalizeWeeklyRoutine(routine);
  final int configuredCount = normalized
      .where((WeeklyRoutineDayProfile item) => item.kind != WeeklyRoutineDayKind.unspecified)
      .length;
  final int offCount = normalized
      .where((WeeklyRoutineDayProfile item) => item.kind == WeeklyRoutineDayKind.off)
      .length;

  if (configuredCount == 0) {
    return localeCode == AppConstants.localeId ? 'Belum diatur' : 'Not set yet';
  }
  if (offCount == 7) {
    return localeCode == AppConstants.localeId ? 'Semua hari libur' : 'Every day is off';
  }
  if (offCount > 0) {
    return localeCode == AppConstants.localeId
        ? '$configuredCount hari diatur, $offCount hari libur'
        : '$configuredCount days set, $offCount days off';
  }
  return localeCode == AppConstants.localeId
      ? '$configuredCount hari sudah diatur'
      : '$configuredCount days already set';
}

String _userInfoSummary(
  AppSettingsModel settings, {
  required String localeCode,
}) {
  final bool hasName = (settings.profileName ?? '').trim().isNotEmpty;
  final List<String> readyParts = <String>[
    if (hasName) localeCode == AppConstants.localeId ? 'Nama' : 'Name',
    if (settings.hasConfiguredWeeklyRoutine)
      localeCode == AppConstants.localeId ? 'Rutinitas' : 'Routine',
    if (settings.hasExtraActivitiesNote)
      localeCode == AppConstants.localeId ? 'Aktivitas lain' : 'Other activities',
  ];

  if (readyParts.isEmpty) {
    return localeCode == AppConstants.localeId
        ? 'Belum diisi'
        : 'Not set yet';
  }

  return readyParts.join(' | ');
}

String _profileFieldValue(
  String? rawName, {
  required String localeCode,
}) {
  final String trimmed = (rawName ?? '').trim();
  if (trimmed.isEmpty) {
    return localeCode == AppConstants.localeId
        ? 'Belum diatur'
        : 'Not set yet';
  }
  return trimmed;
}

String _extraActivitiesValue(
  String? rawValue, {
  required String localeCode,
}) {
  final String trimmed = (rawValue ?? '').trim();
  if (trimmed.isEmpty) {
    return localeCode == AppConstants.localeId
        ? 'Belum diatur'
        : 'Not set yet';
  }
  return trimmed;
}

String _normalizeProfileNameInput(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}

Future<void> _editProfileName({
  required BuildContext context,
  required WidgetRef ref,
  required AppSettingsModel settings,
  required String localeCode,
}) async {
  final bool isId = localeCode == AppConstants.localeId;
  final TextEditingController controller = TextEditingController(
    text: (settings.profileName ?? '').trim(),
  );

  final String? nextName = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      String? errorText;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          Future<void> submit() async {
            final String normalized = _normalizeProfileNameInput(
              controller.text,
            );
            if (normalized.isEmpty) {
              setState(() {
                errorText = isId
                    ? 'Nama tidak boleh kosong.'
                    : 'Name cannot be empty.';
              });
              return;
            }
            Navigator.of(dialogContext).pop(normalized);
          }

          return AlertDialog(
            title: Text(isId ? 'Ubah nama' : 'Edit name'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: isId ? 'Nama pengguna' : 'User name',
                errorText: errorText,
              ),
              onChanged: (_) {
                if (errorText == null) {
                  return;
                }
                setState(() => errorText = null);
              },
              onSubmitted: (_) {
                submit();
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(isId ? 'Batal' : 'Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: Text(isId ? 'Simpan' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );
  _disposeTextControllerSafely(controller);

  if (nextName == null) {
    return;
  }

  await ref
      .read(settingsRepositoryProvider)
      .save(settings.copyWith(profileName: nextName));
}

Future<void> _editExtraActivities({
  required BuildContext context,
  required WidgetRef ref,
  required AppSettingsModel settings,
  required String localeCode,
}) async {
  final bool isId = localeCode == AppConstants.localeId;
  final TextEditingController controller = TextEditingController(
    text: (settings.extraActivitiesNote ?? '').trim(),
  );

  final String? nextValue = await showDialog<String?>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(isId ? 'Aktivitas lain' : 'Other activities'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: isId
                ? 'Tuliskan aktivitas lainmu'
                : 'Write your other activities',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isId ? 'Batal' : 'Cancel'),
          ),
          if ((settings.extraActivitiesNote ?? '').trim().isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: Text(isId ? 'Hapus' : 'Clear'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim(),
            ),
            child: Text(isId ? 'Simpan' : 'Save'),
          ),
        ],
      );
    },
  );
  _disposeTextControllerSafely(controller);

  if (nextValue == null) {
    return;
  }

  await ref.read(settingsRepositoryProvider).save(
    settings.copyWith(
      extraActivitiesNote: nextValue,
      clearExtraActivitiesNote: nextValue.trim().isEmpty,
    ),
  );
}

String _weeklyRoutineDaySummary(
  WeeklyRoutineDayProfile profile, {
  required String localeCode,
}) {
  final String kindLabel = _routineKindLabel(profile.kind, localeCode);
  if (profile.kind == WeeklyRoutineDayKind.unspecified) {
    return kindLabel;
  }

  final List<String> parts = <String>[kindLabel];
  if (profile.startMinutes != null && profile.endMinutes != null) {
    parts.add(
      '${formatMinutesAsTime(profile.startMinutes!)} - ${formatMinutesAsTime(profile.endMinutes!)}',
    );
  } else if (profile.startMinutes != null) {
    parts.add(
      localeCode == AppConstants.localeId
          ? 'Mulai ${formatMinutesAsTime(profile.startMinutes!)}'
          : 'Starts ${formatMinutesAsTime(profile.startMinutes!)}',
    );
  }
  if (profile.departureMinutes != null) {
    parts.add(
      localeCode == AppConstants.localeId
          ? 'Berangkat ${formatMinutesAsTime(profile.departureMinutes!)}'
          : 'Leave ${formatMinutesAsTime(profile.departureMinutes!)}',
    );
  }
  if (profile.restStartMinutes != null && profile.restEndMinutes != null) {
    parts.add(
      localeCode == AppConstants.localeId
          ? 'Istirahat ${formatMinutesAsTime(profile.restStartMinutes!)}-${formatMinutesAsTime(profile.restEndMinutes!)}'
          : 'Rest ${formatMinutesAsTime(profile.restStartMinutes!)}-${formatMinutesAsTime(profile.restEndMinutes!)}',
    );
  }
  return parts.join(' | ');
}

String _weekdayFullLabel(int weekday, String localeCode) {
  const List<String> idDays = <String>[
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const List<String> enDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final int safeIndex = weekday.clamp(1, 7) - 1;
  return localeCode == AppConstants.localeId ? idDays[safeIndex] : enDays[safeIndex];
}

String _routineKindLabel(WeeklyRoutineDayKind kind, String localeCode) {
  final bool isId = localeCode == AppConstants.localeId;
  switch (kind) {
    case WeeklyRoutineDayKind.unspecified:
      return isId ? 'Belum diatur' : 'Not set';
    case WeeklyRoutineDayKind.work:
      return isId ? 'Kerja' : 'Work';
    case WeeklyRoutineDayKind.college:
      return isId ? 'Kuliah' : 'College';
    case WeeklyRoutineDayKind.school:
      return isId ? 'Sekolah' : 'School';
    case WeeklyRoutineDayKind.off:
      return isId ? 'Libur' : 'Off';
    case WeeklyRoutineDayKind.flexible:
      return isId ? 'Fleksibel' : 'Flexible';
    case WeeklyRoutineDayKind.custom:
      return isId ? 'Lainnya' : 'Custom';
  }
}

IconData _routineKindIcon(WeeklyRoutineDayKind kind) {
  switch (kind) {
    case WeeklyRoutineDayKind.work:
      return Icons.work_outline_rounded;
    case WeeklyRoutineDayKind.college:
    case WeeklyRoutineDayKind.school:
      return Icons.school_outlined;
    case WeeklyRoutineDayKind.off:
      return Icons.beach_access_rounded;
    case WeeklyRoutineDayKind.flexible:
      return Icons.auto_awesome_motion_rounded;
    case WeeklyRoutineDayKind.custom:
      return Icons.tune_rounded;
    case WeeklyRoutineDayKind.unspecified:
      return Icons.event_note_rounded;
  }
}

String _timeValueOrPlaceholder(int? minutes, String localeCode) {
  if (minutes == null) {
    return localeCode == AppConstants.localeId ? 'Belum diatur' : 'Not set';
  }
  return formatMinutesAsTime(minutes);
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
    helpText: localeCode == AppConstants.localeId ? 'Masukkan waktu' : 'Enter time',
    cancelText: localeCode == AppConstants.localeId ? 'Batal' : 'Cancel',
    confirmText: localeCode == AppConstants.localeId ? 'Oke' : 'OK',
    hourLabelText: localeCode == AppConstants.localeId ? 'Jam' : 'Hour',
    minuteLabelText: localeCode == AppConstants.localeId ? 'Menit' : 'Minute',
  );
  if (picked == null) {
    return null;
  }
  return timeOfDayToMinutes(picked.hour, picked.minute);
}
