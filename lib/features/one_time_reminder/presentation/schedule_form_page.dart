import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liburan_create/app/providers.dart';
import 'package:liburan_create/core/utils/date_utils.dart';
import 'package:liburan_create/core/utils/time_utils.dart';
import 'package:liburan_create/features/activity/application/smart_activity_advisor.dart';
import 'package:liburan_create/features/activity/domain/activity_category.dart';
import 'package:liburan_create/services/gemini_activity_service.dart';
import 'package:liburan_create/features/one_time_reminder/domain/one_time_reminder_model.dart';
import 'package:liburan_create/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

class ScheduleFormArgs {
  const ScheduleFormArgs({this.reminder, this.initialDate});

  final OneTimeReminderModel? reminder;
  final DateTime? initialDate;
}

class ScheduleFormPage extends ConsumerStatefulWidget {
  const ScheduleFormPage({super.key, this.args});

  final ScheduleFormArgs? args;

  @override
  ConsumerState<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends ConsumerState<ScheduleFormPage> {
  static const SmartActivityAdvisor _smartAdvisor = SmartActivityAdvisor();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subController = TextEditingController();
  final Uuid _uuid = const Uuid();

  late DateTime _selectedDate;
  late int _startMinutes;
  String? _selectedCategoryId;
  late List<String> _subActivities;
  late bool _isNotificationEnabled;
  bool _saving = false;
  SmartActivitySuggestion? _geminiSuggestion;
  String? _geminiAnalyzedTitle;
  String? _geminiError;
  bool _isGeminiLoading = false;
  bool _aiSuggestionDismissed = false;

  OneTimeReminderModel? get _existing => widget.args?.reminder;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _selectedCategoryId != null;

  @override
  void initState() {
    super.initState();
    final OneTimeReminderModel? existing = _existing;
    _titleController.text = existing?.title ?? '';
    if (existing != null) {
      _selectedDate = dateOnly(existing.scheduledAt);
      _startMinutes =
          existing.scheduledAt.hour * 60 + existing.scheduledAt.minute;
    } else {
      _selectedDate = dateOnly(
        widget.args?.initialDate ?? DateTime.now(),
      );
      _startMinutes = nextRoundedQuarterMinutes(DateTime.now());
    }
    _selectedCategoryId = ActivityCategory.isValid(existing?.categoryId)
        ? existing!.categoryId
        : null;
    _subActivities = List<String>.from(existing?.subActivities ?? <String>[]);
    _isNotificationEnabled = existing?.isNotificationEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subController.dispose();
    super.dispose();
  }

  void _resetAiState() {
    _geminiSuggestion = null;
    _geminiAnalyzedTitle = null;
    _geminiError = null;
    _isGeminiLoading = false;
    _aiSuggestionDismissed = false;
  }

  Future<void> _analyzeWithGemini() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty || _isGeminiLoading) {
      return;
    }
    final GeminiActivityService geminiService = ref.read(
      geminiActivityServiceProvider,
    );
    if (!geminiService.isConfigured) {
      setState(() {
        _geminiError = geminiService.setupHint;
      });
      return;
    }
    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    setState(() {
      _isGeminiLoading = true;
      _geminiError = null;
    });
    try {
      final SmartActivitySuggestion suggestion = await geminiService
          .analyzeActivityTitle(title: title, localeCode: localeCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _geminiSuggestion = suggestion;
        _geminiAnalyzedTitle = title;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _geminiError = geminiService.setupHint;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeminiLoading = false;
        });
      }
    }
  }

  void _addSubActivity() {
    final String value = _subController.text.trim();
    if (value.isEmpty ||
        value.length > 60 ||
        _subActivities.length >= 15 ||
        _subActivities.contains(value)) {
      return;
    }
    setState(() {
      _subActivities.add(value);
      _subController.clear();
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: dateOnly(DateTime.now()).subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = dateOnly(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _startMinutes ~/ 60,
        minute: _startMinutes % 60,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      helpText: localeCode == 'id' ? 'Masukkan waktu' : 'Enter time',
      hourLabelText: localeCode == 'id' ? 'Jam' : 'Hour',
      minuteLabelText: localeCode == 'id' ? 'Menit' : 'Minute',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _startMinutes = picked.hour * 60 + picked.minute;
    });
  }

  Future<void> _save() async {
    final AppLocalizations t = AppLocalizations.of(context)!;
    if (_saving) {
      return;
    }
    final String title = _titleController.text.trim();
    final String? categoryId = _selectedCategoryId;
    final String localeCode =
        ref.read(settingsStreamProvider).value?.localeCode ?? 'id';
    if (title.isEmpty || categoryId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeCode == 'id'
                ? 'Isi judul dan pilih kategori dulu.'
                : 'Fill in the title and pick a category first.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final OneTimeReminderModel? existing = _existing;
      final DateTime now = DateTime.now();
      final DateTime scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startMinutes ~/ 60,
        _startMinutes % 60,
      );
      final List<String> normalizedSubs = _subActivities
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList();
      final List<String> keptCompleted =
          (existing?.completedSubActivities ?? const <String>[])
              .where((String item) => normalizedSubs.contains(item))
              .toList();
      final OneTimeReminderModel model = OneTimeReminderModel(
        id: existing?.id ?? _uuid.v4(),
        title: title,
        iconKey: existing?.iconKey ?? 'calendar',
        scheduledAt: scheduledAt,
        scheduledEndAt: existing?.scheduledEndAt,
        categoryId: categoryId,
        description: existing?.description ?? '',
        subActivities: normalizedSubs,
        completedSubActivities: keptCompleted,
        preReminderMinutes: 0,
        isNotificationEnabled: _isNotificationEnabled,
        isCompleted: existing?.isCompleted ?? false,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(oneTimeReminderActionsProvider).saveReminder(model);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.formValidationMessage)));
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
    final AppLocalizations t = AppLocalizations.of(context)!;
    final String localeCode =
        ref.watch(settingsStreamProvider).value?.localeCode ?? 'id';
    final bool isId = localeCode == 'id';
    final ThemeData theme = Theme.of(context);
    final GeminiActivityService geminiService = ref.read(
      geminiActivityServiceProvider,
    );
    final String trimmedTitle = _titleController.text.trim();
    final SmartActivitySuggestion? localSuggestion =
        trimmedTitle.isEmpty
        ? null
        : _smartAdvisor.analyze(trimmedTitle, localeCode: localeCode);
    final bool isGeminiActiveForTitle =
        _geminiSuggestion != null && _geminiAnalyzedTitle == trimmedTitle;
    final SmartActivitySuggestion? aiSuggestion =
        isGeminiActiveForTitle ? _geminiSuggestion : localSuggestion;
    final bool showAiSection =
        (aiSuggestion != null && !_aiSuggestionDismissed) ||
        _geminiError != null;

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
        title: Text(
          _existing == null
              ? (isId ? 'Buat Jadwal' : 'Create schedule')
              : (isId ? 'Edit Jadwal' : 'Edit schedule'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(
            t.activityTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              _resetAiState();
              setState(() {});
            },
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.15,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: isId ? 'Contoh: Belajar' : 'Example: Study',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.6,
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon:
                  geminiService.isConfigured && trimmedTitle.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _TitleFieldGeminiButton(
                        label: isGeminiActiveForTitle ? 'Refresh' : 'Gemini',
                        isLoading: _isGeminiLoading,
                        onTap: _isGeminiLoading ? null : _analyzeWithGemini,
                      ),
                    )
                  : null,
            ),
          ),
          if (showAiSection) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              isId ? 'SARAN AI' : 'AI SUGGESTION',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
          if (_geminiError != null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _geminiError!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
              ),
            ),
          ],
          if (aiSuggestion != null && !_aiSuggestionDismissed) ...<Widget>[
            const SizedBox(height: 8),
            _AgendaAiSuggestionCard(
              localeCode: localeCode,
              suggestion: aiSuggestion,
              isGeminiResult: isGeminiActiveForTitle,
              onApplyTitle: (String title) {
                setState(() {
                  _titleController.text = title;
                  _resetAiState();
                });
              },
              onDismiss: () {
                setState(() {
                  _aiSuggestionDismissed = true;
                });
              },
            ),
          ],
          const SizedBox(height: 20),
          Text(
            isId ? 'KATEGORI' : 'CATEGORY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ActivityCategory.values.map((String id) {
              return ChoiceChip(
                label: Text(ActivityCategory.labelOf(id, localeCode)),
                selected: _selectedCategoryId == id,
                onSelected: (_) {
                  setState(() {
                    _selectedCategoryId = id;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            isId ? 'SUB-AKTIVITAS' : 'SUB-ACTIVITIES',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _subController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubActivity(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    hintText: isId
                        ? 'Tambah sub-aktivitas...'
                        : 'Add sub-activity...',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _addSubActivity,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: NousenNavIcon(Icons.add_rounded, size: 20),
                label: Text(
                  isId ? 'Tambah' : 'Add',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_subActivities.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subActivities.map((String sub) {
                return InputChip(
                  label: Text(sub),
                  onDeleted: () {
                    setState(() {
                      _subActivities.remove(sub);
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            isId ? 'JADWAL' : 'SCHEDULE',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isId ? 'Pilih tanggal' : 'Choose date',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 7),
          _AgendaInlineItem(
            icon: Icons.calendar_month_rounded,
            value: formatDateShort(_selectedDate, localeCode),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Text(
            isId ? 'Pilih waktu' : 'Choose time',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 7),
          _AgendaInlineItem(
            icon: Icons.schedule_rounded,
            value: formatMinutesAsTime(_startMinutes),
            onTap: _pickTime,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _isNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                _isNotificationEnabled = value;
              });
            },
            title: Text(isId ? 'Notifikasi' : 'Notification'),
            subtitle: Text(
              isId
                  ? 'Bunyi pada waktu jadwal.'
                  : 'Rings at the scheduled time.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: !_canSubmit || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isId ? 'Simpan Jadwal' : 'Save schedule',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaAiSuggestionCard extends StatelessWidget {
  const _AgendaAiSuggestionCard({
    required this.localeCode,
    required this.suggestion,
    required this.isGeminiResult,
    required this.onApplyTitle,
    required this.onDismiss,
  });

  final String localeCode;
  final SmartActivitySuggestion suggestion;
  final bool isGeminiResult;
  final void Function(String title) onApplyTitle;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isAvoidance =
        suggestion.type == SmartActivityType.avoidance;
    final bool needsTitleDetail = suggestion.needsTitleDetail;
    final String cardTitle = needsTitleDetail
        ? (localeCode == 'id'
              ? 'Gunakan judul yang lebih spesifik?'
              : 'Use a more specific title?')
        : (isAvoidance
              ? (localeCode == 'id' ? 'Fokus pengingat' : 'Tracking focus')
              : (localeCode == 'id' ? 'Saran jadwal' : 'Schedule suggestion'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  cardTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isGeminiResult) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'GEMINI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: onDismiss,
                child: NousenNavIcon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAvoidance) ...<Widget>[
            _AgendaSuggestionLine(
              title: localeCode == 'id' ? 'Pantauan harian' : 'Daily tracking',
              body: suggestion.tracking ?? '',
            ),
            const SizedBox(height: 10),
            _AgendaSuggestionLine(
              title: localeCode == 'id' ? 'Catatan singkat' : 'Quick insight',
              body: suggestion.insight ?? '',
            ),
          ] else if (needsTitleDetail) ...<Widget>[
            if (suggestion.detailPrompt != null)
              Text(
                suggestion.detailPrompt!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.38,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
            if (suggestion.suggestedTitles.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestion.suggestedTitles
                    .map(
                      (String item) => GestureDetector(
                        onTap: () => onApplyTitle(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ] else ...<Widget>[
            Text(
              suggestion.reason ?? suggestion.insight ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.38,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaSuggestionLine extends StatelessWidget {
  const _AgendaSuggestionLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _AgendaInlineItem extends StatelessWidget {
  const _AgendaInlineItem({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              NousenNavIcon(
                icon,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TitleFieldGeminiButton extends StatelessWidget {
  const _TitleFieldGeminiButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              NousenNavIcon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
