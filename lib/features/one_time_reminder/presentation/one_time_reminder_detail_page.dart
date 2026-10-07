import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/app/router.dart';
import 'package:liburan_create/core/theme/app_layout.dart';
import 'package:liburan_create/core/theme/app_theme.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/core/widgets/optimized_file_image.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_note_model.dart';
import 'package:liburan_create/features/one_time_reminder/domain/agenda_visual_state.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/features/one_time_reminder/presentation/schedule_form_page.dart';
import 'package:liburan_create/l10n/app_localizations.dart';
import 'package:liburan_create/services/photo_access_service.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

class OneTimeReminderDetailPage extends ConsumerWidget {
  const OneTimeReminderDetailPage({super.key, required this.args});

  final OneTimeReminderDetailArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final bool isId = localeCode == 'id';
    final List<OneTimeReminderModel> reminders =
        ref.watch(oneTimeRemindersStreamProvider).value ??
        const <OneTimeReminderModel>[];
    final OneTimeReminderModel? reminder = _findById(
      reminders,
      args.reminderId,
    );
    final ThemeData theme = Theme.of(context);

    if (reminder == null) {
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
                        icon: NousenNavIcon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          title: Text(t.oneTimeReminderDetail),
        ),
        body: Center(child: Text(t.oneTimeReminderNotFound)),
      );
    }

    final AgendaVisualState visualState =
        resolveAgendaVisualState(reminder, DateTime.now());
    final Color statusColor = switch (visualState) {
      AgendaVisualState.done => theme.colorScheme.primary,
      AgendaVisualState.ongoing => theme.habitColors.pending,
      AgendaVisualState.missed => theme.habitColors.missed,
      AgendaVisualState.upcoming => theme.habitColors.inactive,
      AgendaVisualState.skipped => theme.habitColors.inactive,
    };
    final String statusLabel = switch (visualState) {
      AgendaVisualState.done => isId ? 'Selesai' : 'Done',
      AgendaVisualState.ongoing => isId ? 'Berlangsung' : 'Ongoing',
      AgendaVisualState.missed => isId ? 'Terlewat' : 'Missed',
      AgendaVisualState.upcoming => isId ? 'Belum mulai' : 'Upcoming',
      AgendaVisualState.skipped => isId ? 'Dilewati' : 'Skipped',
    };
    final int subTotal = reminder.subActivities.length;
    final int subDone = reminder.completedSubActivities
        .where((String sub) => reminder.subActivities.contains(sub))
        .length;
    // Model induk-sebagai-unit: induk 1 unit + tiap sub 1 unit.
    final int percent = resolveAgendaProgressPercent(reminder);
    final String scheduleText =
        '${DateFormat('EEE, d MMM', localeCode).format(reminder.scheduledAt)} • ${formatMinutesAsTime(reminder.scheduledAt.hour * 60 + reminder.scheduledAt.minute)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                icon: NousenNavIcon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          isId ? 'Detail jadwal' : 'Schedule detail',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: isId ? 'Opsi jadwal' : 'Schedule options',
            icon: NousenNavIcon(
              Icons.more_horiz_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (String action) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) {
                  return;
                }
                if (action == 'edit') {
                  Navigator.of(context).pushNamed(
                    AppRoutes.scheduleForm,
                    arguments: ScheduleFormArgs(reminder: reminder),
                  );
                  return;
                }
                if (action == 'skip') {
                  await ref
                      .read(oneTimeReminderActionsProvider)
                      .skipReminder(reminder: reminder);
                  return;
                }
                if (action != 'delete') {
                  return;
                }
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(t.deleteOneTimeReminder),
                      content: Text(
                        t.deleteOneTimeReminderConfirm(reminder.title),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(t.cancel),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(t.delete),
                        ),
                      ],
                    );
                  },
                );
                if (confirm != true) {
                  return;
                }
                await ref
                    .read(oneTimeReminderActionsProvider)
                    .deleteReminder(reminder);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(isId ? 'Edit agenda' : 'Edit schedule'),
              ),
              PopupMenuItem<String>(
                value: 'skip',
                enabled: !reminder.isCompleted && !reminder.isSkipped,
                child: Text(isId ? 'Lewati agenda' : 'Skip schedule'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(isId ? 'Hapus agenda' : 'Delete schedule'),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;
          final bool isLarge = constraints.maxWidth >= 1100;
          final double sidePadding = isWide ? 24 : 16;
          final double contentMaxWidth = isLarge ? 980 : 760;
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
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scheduleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reminder.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.02,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      NousenNavIcon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subTotal > 0
                            ? (isId
                                  ? '$subDone dari $subTotal sub selesai'
                                  : '$subDone of $subTotal subs done')
                            : statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 112,
                          height: 112,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 112,
                                height: 112,
                              child: CircularProgressIndicator(
                                value: percent / 100,
                                strokeWidth: 10,
                                backgroundColor:
                                    statusColor.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  statusColor,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      height: 1.0,
                                    ),
                                  ),
                                  const Text(
                                    'TARGET',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                isId
                                    ? 'Progres Jadwal'
                                    : 'Schedule Progress',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subTotal > 0
                                    ? (isId
                                          ? '$subDone dari $subTotal sub-aktivitas selesai'
                                          : '$subDone of $subTotal sub-activities done')
                                    : (reminder.isCompleted
                                          ? (isId
                                                ? 'Jadwal selesai dikerjakan.'
                                                : 'Schedule completed.')
                                          : (isId
                                                ? 'Progres sesi berjalan'
                                                : 'Session progress')),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (subTotal > 0) ...<Widget>[
                                const SizedBox(height: 8),
                                Row(
                                  children: List<Widget>.generate(
                                    subTotal,
                                    (int i) => Expanded(
                                      child: Container(
                                        height: 4,
                                        margin: EdgeInsets.only(
                                          right: i == subTotal - 1 ? 0 : 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: i < subDone
                                              ? statusColor
                                              : const Color(0xFFE2E8F0),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                    ),
                                    growable: false,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (reminder.subActivities.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    Text(
                      isId ? 'Sub-aktivitas' : 'Sub-activities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isId
                                ? 'Sub selesai: $subDone/$subTotal'
                                : 'Subs done: $subDone/$subTotal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 8,
                            runSpacing: 8,
                            children: reminder.subActivities.map((
                              String sub,
                            ) {
                              final bool checked = reminder
                                  .completedSubActivities
                                  .contains(sub);
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await ref
                                      .read(oneTimeReminderActionsProvider)
                                      .toggleSubActivity(
                                        reminder: reminder,
                                        subActivity: sub,
                                        completed: !checked,
                                      );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: checked
                                        ? statusColor.withValues(alpha: 0.12)
                                        : theme
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: checked
                                          ? statusColor.withValues(alpha: 0.4)
                                          : theme.colorScheme.primary
                                                .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Text(
                                    sub,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: checked
                                          ? statusColor
                                          : theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _AgendaTimelinePage(
                              reminderId: reminder.id,
                              reminderTitle: reminder.title,
                              localeCode: localeCode,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: NousenNavIcon(
                                Icons.bar_chart_rounded,
                                color: Color(0xFF475569),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    isId
                                        ? 'Timeline progres'
                                        : 'Progress timeline',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    isId
                                        ? 'Lihat riwayat & catatan lalu'
                                        : 'View history & past notes',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      fontSize: 11,
                                      color:
                                          const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            NousenNavIcon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AgendaNoteComposer(
                    localeCode: localeCode,
                    onPickPhotos: () => _pickAgendaPhotoPaths(
                      context: context,
                      ref: ref,
                    ),
                    onSave: (String note, List<String> photoPaths) async {
                      await ref
                          .read(oneTimeReminderActionsProvider)
                          .saveNote(
                            reminderId: reminder.id,
                            text: note,
                            photoPaths: photoPaths,
                          );
                      return true;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  OneTimeReminderModel? _findById(
    List<OneTimeReminderModel> reminders,
    String id,
  ) {
    for (final OneTimeReminderModel reminder in reminders) {
      if (reminder.id == id) {
        return reminder;
      }
    }
    return null;
  }
}

Future<List<String>> _pickAgendaPhotoPaths({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final bool? fromCamera = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: NousenNavIcon(Icons.photo_camera_outlined),
                title: const Text('Ambil foto dari kamera'),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: NousenNavIcon(Icons.photo_library_outlined),
                title: const Text('Pilih foto dari galeri'),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (fromCamera == null || !context.mounted) {
    return const <String>[];
  }
  final bool allowed = await ref.read(photoAccessServiceProvider).ensureAccess(
        context: context,
        localeCode:
            ref.read(settingsStreamProvider).value?.localeCode ?? 'id',
        source: fromCamera
            ? PhotoAccessSource.camera
            : PhotoAccessSource.gallery,
      );
  if (!allowed) {
    return const <String>[];
  }
  final imageStorage = ref.read(imageStorageServiceProvider);
  if (fromCamera) {
    final String? path = await imageStorage.pickAndSaveImageFromCamera();
    return path == null ? const <String>[] : <String>[path];
  }
  return imageStorage.pickAndSaveImagesFromGallery();
}

class _AgendaNoteComposer extends ConsumerStatefulWidget {
  const _AgendaNoteComposer({
    required this.localeCode,
    required this.onPickPhotos,
    required this.onSave,
  });

  final String localeCode;
  final Future<List<String>> Function() onPickPhotos;
  final Future<bool> Function(String note, List<String> photoPaths) onSave;

  @override
  ConsumerState<_AgendaNoteComposer> createState() =>
      _AgendaNoteComposerState();
}

class _AgendaNoteComposerState extends ConsumerState<_AgendaNoteComposer> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _photoPaths = <String>[];
  bool _pickingPhoto = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      (_controller.text.trim().isNotEmpty || _photoPaths.isNotEmpty);

  Future<void> _pickPhoto() async {
    if (_pickingPhoto) {
      return;
    }
    setState(() {
      _pickingPhoto = true;
    });
    try {
      final List<String> picked = await widget.onPickPhotos();
      if (!mounted) {
        return;
      }
      setState(() {
        for (final String path in picked) {
          final String cleanPath = path.trim();
          if (cleanPath.isEmpty || _photoPaths.contains(cleanPath)) {
            continue;
          }
          _photoPaths.add(cleanPath);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _pickingPhoto = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_canSave) {
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final bool saved = await widget.onSave(
        _controller.text.trim(),
        List<String>.from(_photoPaths),
      );
      if (!mounted || !saved) {
        return;
      }
      setState(() {
        _controller.clear();
        _photoPaths.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isId = widget.localeCode == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              isId ? 'Catatan Sesi' : 'Session Notes',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              isId ? 'Opsional' : 'Optional',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: isId
                      ? 'Tulis refleksi ringkas atau kendala hari ini...'
                      : 'Write a brief reflection or blocker today...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B7BD6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_photoPaths.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoPaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String path = _photoPaths[index];
                      return Stack(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: OptimizedFileImage(
                              path: path,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 54,
                                  height: 54,
                                  color: const Color(0xFFF1F5F9),
                                  alignment: Alignment.center,
                                  child: NousenNavIcon(
                                    Icons.broken_image_rounded,
                                    size: 16,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                setState(() {
                                  _photoPaths.removeAt(index);
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: NousenNavIcon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _pickingPhoto ? null : _pickPhoto,
                      icon: NousenNavIcon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B7BD6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _canSave ? _submit : null,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isId ? 'Simpan' : 'Save',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgendaTimelinePage extends StatelessWidget {
  const _AgendaTimelinePage({
    required this.reminderId,
    required this.reminderTitle,
    required this.localeCode,
  });

  final String reminderId;
  final String reminderTitle;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final bool isId = localeCode == 'id';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                icon: NousenNavIcon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
        title: Text(
          isId ? 'Timeline progres' : 'Progress timeline',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: _AgendaTimelineSection(reminderId: reminderId),
    );
  }
}

class _AgendaTimelineSection extends ConsumerWidget {
  const _AgendaTimelineSection({required this.reminderId});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final bool isId = localeCode == 'id';
    final List<OneTimeReminderModel> reminders =
        ref.watch(oneTimeRemindersStreamProvider).value ??
        const <OneTimeReminderModel>[];
    OneTimeReminderModel? reminder;
    for (final OneTimeReminderModel item in reminders) {
      if (item.id == reminderId) {
        reminder = item;
        break;
      }
    }
    final List<AgendaNoteModel> notes =
        ref.watch(agendaNotesStreamProvider(reminderId)).value ??
        const <AgendaNoteModel>[];
    if (reminder == null) {
      return Center(
        child: Text(
          isId ? 'Jadwal tidak ditemukan.' : 'Schedule not found.',
        ),
      );
    }
    final List<AgendaMilestone> milestones = buildAgendaMilestones(
      reminder,
      now: DateTime.now(),
      idLabel: isId,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              isId ? 'Catatan Sesi' : 'Session Notes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              isId ? '${notes.length} sesi' : '${notes.length} sessions',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B7BD6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...milestones.map(
          (AgendaMilestone m) => _AgendaTimelineMilestoneRow(
            label: m.label,
            date: m.date,
            done: m.done,
            localeCode: localeCode,
            showConnector: m != milestones.last || notes.isNotEmpty,
          ),
        ),
        ...notes.asMap().entries.map((entry) {
          final int index = entry.key;
          final AgendaNoteModel note = entry.value;
          return _AgendaNoteCard(
            note: note,
            reminderId: reminderId,
            localeCode: localeCode,
            showConnector: index < notes.length - 1,
          );
        }),
      ],
    );
  }
}

class _AgendaTimelineMilestoneRow extends StatelessWidget {
  const _AgendaTimelineMilestoneRow({
    required this.label,
    required this.date,
    required this.done,
    required this.localeCode,
    required this.showConnector,
  });

  final String label;
  final DateTime date;
  final bool done;
  final String localeCode;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 4),
                NousenNavIcon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: done
                      ? const Color(0xFF3B7BD6)
                      : const Color(0xFF94A3B8),
                ),
                if (showConnector)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 1,
                    height: 44,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'EEEE, d MMM yyyy • HH:mm',
                    localeCode,
                  ).format(date),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaNoteCard extends ConsumerWidget {
  const _AgendaNoteCard({
    required this.note,
    required this.reminderId,
    required this.localeCode,
    required this.showConnector,
  });

  final AgendaNoteModel note;
  final String reminderId;
  final String localeCode;
  final bool showConnector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isId = localeCode == 'id';
    final bool hasText = note.text.trim().isNotEmpty;
    final bool hasPhoto = note.photoPaths.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 4),
                NousenNavIcon(
                  Icons.sticky_note_2_rounded,
                  size: 14,
                  color: Color(0xFF3B7BD6),
                ),
                if (showConnector)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 1,
                    height: (hasPhoto ? 150 : 56) + (hasText ? 90 : 0),
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            DateFormat(
                              'EEEE, d MMM yyyy • HH:mm',
                              localeCode,
                            ).format(note.updatedAt),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: isId ? 'Opsi log' : 'Log options',
                      icon: NousenNavIcon(Icons.more_horiz_rounded),
                      onSelected: (String action) async {
                        if (action == 'edit') {
                          await _showEditAgendaNoteDialog(
                            context: context,
                            ref: ref,
                            note: note,
                            reminderId: reminderId,
                            localeCode: localeCode,
                          );
                        } else if (action == 'delete') {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: Text(
                                  isId ? 'Hapus catatan?' : 'Delete note?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(false),
                                    child: Text(
                                      isId ? 'Batal' : 'Cancel',
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(
                                      dialogContext,
                                    ).pop(true),
                                    child: Text(
                                      isId ? 'Hapus' : 'Delete',
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            await ref
                                .read(oneTimeReminderActionsProvider)
                                .deleteNote(noteId: note.id);
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(isId ? 'Edit' : 'Edit'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(isId ? 'Hapus' : 'Delete'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                if (hasPhoto) ...<Widget>[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: note.photoPaths.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String path = note.photoPaths[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: OptimizedFileImage(
                            path: path,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: const Color(0xFFF1F5F9),
                                alignment: Alignment.center,
                                child: NousenNavIcon(
                                  Icons.broken_image_rounded,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (hasText) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    note.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.88,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showEditAgendaNoteDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AgendaNoteModel note,
  required String reminderId,
  required String localeCode,
}) async {
  final bool isId = localeCode == 'id';
  final TextEditingController controller = TextEditingController(
    text: note.text,
  );
  final List<String> photoPaths = List<String>.from(note.photoPaths);
  bool picking = false;

  Future<void> pickPhotos(StateSetter setSheetState) async {
    if (picking) {
      return;
    }
    picking = true;
    try {
      final List<String> picked = await _pickAgendaPhotoPaths(
        context: context,
        ref: ref,
      );
      setSheetState(() {
        for (final String path in picked) {
          final String clean = path.trim();
          if (clean.isEmpty || photoPaths.contains(clean)) {
            continue;
          }
          photoPaths.add(clean);
        }
      });
    } finally {
      picking = false;
    }
  }

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return AlertDialog(
            title: Text(isId ? 'Edit catatan' : 'Edit note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: isId
                          ? 'Tulis catatan sesi...'
                          : 'Write a session note...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (photoPaths.isNotEmpty)
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photoPaths.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (BuildContext context, int index) {
                          return Stack(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: OptimizedFileImage(
                                  path: photoPaths[index],
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                        return Container(
                                          width: 64,
                                          height: 64,
                                          color: const Color(0xFFF1F5F9),
                                          alignment: Alignment.center,
                                          child: NousenNavIcon(
                                            Icons.broken_image_rounded,
                                            size: 16,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      photoPaths.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: NousenNavIcon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => pickPhotos(setSheetState),
                    icon: NousenNavIcon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: Text(
                      isId ? 'Tambah foto' : 'Add photos',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(isId ? 'Batal' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final String text = controller.text.trim();
                  if (text.isEmpty && photoPaths.isEmpty) {
                    return;
                  }
                  await ref
                      .read(oneTimeReminderActionsProvider)
                      .saveNote(
                        reminderId: reminderId,
                        text: text,
                        photoPaths: List<String>.from(photoPaths),
                        noteId: note.id,
                      );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(isId ? 'Simpan' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
}
