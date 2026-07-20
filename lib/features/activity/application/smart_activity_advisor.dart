import 'dart:convert';

import 'package:flutter/services.dart';

enum SmartActivityType { action, avoidance }

enum SmartActivityCategory { kesehatan, produktif, istirahat, sosial, umum }

enum SmartActivityDayStrategy {
  daily,
  spaced,
  workdayFriendly,
  weekendFriendly,
  flexible,
}

enum SmartActivityTimeWindow {
  earlyMorning,
  morning,
  midday,
  afternoon,
  evening,
  night,
}

enum SmartActivityEffortLevel { low, medium, high }

enum SmartActivityRoutinePlacement {
  none,
  beforeStart,
  duringRoutine,
  afterEnd,
  outsideRoutine,
  anytime,
}

class SmartActivityLocalPlan {
  const SmartActivityLocalPlan({
    required this.minSessionsPerWeek,
    required this.maxSessionsPerWeek,
    required this.minGapDays,
    required this.dayStrategy,
    this.preferredTimeWindows = const <SmartActivityTimeWindow>[],
    this.effortLevel = SmartActivityEffortLevel.medium,
    this.routineCompatible = false,
    this.routinePlacement = SmartActivityRoutinePlacement.none,
  });

  final int minSessionsPerWeek;
  final int maxSessionsPerWeek;
  final int minGapDays;
  final SmartActivityDayStrategy dayStrategy;
  final List<SmartActivityTimeWindow> preferredTimeWindows;
  final SmartActivityEffortLevel effortLevel;
  final bool routineCompatible;
  final SmartActivityRoutinePlacement routinePlacement;
}

class SmartActivitySuggestion {
  const SmartActivitySuggestion({
    required this.type,
    required this.category,
    required this.keyword,
    required this.familyLabel,
    this.localPlan,
    this.recommendedDays = const <int>[],
    this.dayReason,
    this.recommendedTimeMinutes,
    this.reason,
    this.tracking,
    this.insight,
    this.needsTitleDetail = false,
    this.detailPrompt,
    this.suggestedTitles = const <String>[],
  });

  final SmartActivityType type;
  final SmartActivityCategory category;
  final String keyword;
  final String familyLabel;
  final SmartActivityLocalPlan? localPlan;
  final List<int> recommendedDays;
  final String? dayReason;
  final int? recommendedTimeMinutes;
  final String? reason;
  final String? tracking;
  final String? insight;
  final bool needsTitleDetail;
  final String? detailPrompt;
  final List<String> suggestedTitles;

  SmartActivitySuggestion copyWith({
    SmartActivityType? type,
    SmartActivityCategory? category,
    String? keyword,
    String? familyLabel,
    SmartActivityLocalPlan? localPlan,
    List<int>? recommendedDays,
    String? dayReason,
    bool clearDayReason = false,
    int? recommendedTimeMinutes,
    bool clearRecommendedTime = false,
    String? reason,
    bool clearReason = false,
    String? tracking,
    bool clearTracking = false,
    String? insight,
    bool clearInsight = false,
    bool? needsTitleDetail,
    String? detailPrompt,
    bool clearDetailPrompt = false,
    List<String>? suggestedTitles,
  }) {
    return SmartActivitySuggestion(
      type: type ?? this.type,
      category: category ?? this.category,
      keyword: keyword ?? this.keyword,
      familyLabel: familyLabel ?? this.familyLabel,
      localPlan: localPlan ?? this.localPlan,
      recommendedDays: recommendedDays ?? this.recommendedDays,
      dayReason: clearDayReason ? null : (dayReason ?? this.dayReason),
      recommendedTimeMinutes: clearRecommendedTime
          ? null
          : (recommendedTimeMinutes ?? this.recommendedTimeMinutes),
      reason: clearReason ? null : (reason ?? this.reason),
      tracking: clearTracking ? null : (tracking ?? this.tracking),
      insight: clearInsight ? null : (insight ?? this.insight),
      needsTitleDetail: needsTitleDetail ?? this.needsTitleDetail,
      detailPrompt: clearDetailPrompt
          ? null
          : (detailPrompt ?? this.detailPrompt),
      suggestedTitles: suggestedTitles ?? this.suggestedTitles,
    );
  }
}

class SmartActivityMlProfile {
  const SmartActivityMlProfile({
    required this.familyKey,
    required this.categoryKey,
    required this.effortLevelKey,
    required this.preferredTimeWindows,
    required this.routineCompatible,
    required this.routinePlacement,
    this.defaultTimeMinutes,
  });

  final String familyKey;
  final String categoryKey;
  final String effortLevelKey;
  final List<SmartActivityTimeWindow> preferredTimeWindows;
  final bool routineCompatible;
  final SmartActivityRoutinePlacement routinePlacement;
  final int? defaultTimeMinutes;
}

class SmartActivityAdvisor {
  const SmartActivityAdvisor();

  static const String profilesAssetPath = 'assets/ai/activity_profiles.json';
  static List<_ActivityProfile> _profiles = <_ActivityProfile>[];
  static bool _profilesLoaded = false;

  static Future<void> initializeProfiles() async {
    if (_profilesLoaded) {
      return;
    }

    final String rawJson = await rootBundle.loadString(profilesAssetPath);
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw StateError('Activity AI profiles JSON must be a list.');
    }

    _profiles = decoded
        .whereType<Map>()
        .map(
          (Map item) => _ActivityProfile.fromJson(
            item.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
    _profilesLoaded = true;
  }

  SmartActivityLocalPlan? localPlanFor(
    String input, {
    String localeCode = 'id',
  }) {
    return analyze(input, localeCode: localeCode)?.localPlan;
  }

  List<int> recommendedWeekdaysFor(
    String input, {
    String localeCode = 'id',
  }) {
    final SmartActivityLocalPlan? plan = localPlanFor(
      input,
      localeCode: localeCode,
    );
    if (plan == null) {
      return const <int>[];
    }
    return _fallbackWeekdaysForPlan(plan);
  }

  SmartActivityMlProfile? mlProfileFor(String input) {
    final String normalized = _normalize(input);
    if (normalized.isEmpty) {
      return null;
    }

    final _ActivityMatch? match = _findBestProfile(normalized);
    final _ActivityProfile? profile = match?.profile;
    final SmartActivityCategory? fallbackCategory = _detectCategoryFallback(
      normalized,
    );
    if (profile == null && fallbackCategory == null) {
      return null;
    }

    final SmartActivityCategory category =
        profile?.category ?? fallbackCategory!;
    final SmartActivityLocalPlan localPlan =
        profile?.localPlan ?? _defaultLocalPlanForCategory(category);
    final _ActivityFamily family = profile?.family ?? _familyFromCategory(category);

    return SmartActivityMlProfile(
      familyKey: _familyKey(family),
      categoryKey: _categoryKey(category),
      effortLevelKey: _effortLevelKey(localPlan.effortLevel),
      preferredTimeWindows: List<SmartActivityTimeWindow>.from(
        localPlan.preferredTimeWindows,
      ),
      routineCompatible: localPlan.routineCompatible,
      routinePlacement: localPlan.routinePlacement,
      defaultTimeMinutes: profile?.defaultTimeMinutes,
    );
  }

  static const Set<String> _avoidanceTerms = <String>{
    'tidak',
    'jangan',
    'stop',
    'hindari',
    'kurangi',
    'berhenti',
    'tanpa',
    'no',
  };

  static const Set<String> _ignoredWords = <String>{
    'aku',
    'saya',
    'ingin',
    'mau',
    'untuk',
    'setiap',
    'tiap',
    'hari',
    'harian',
    'rutin',
    'lebih',
    'dan',
    'atau',
    'yang',
    'biar',
    'supaya',
    'mulai',
    'biasa',
    'banget',
    'aja',
    'di',
    'ke',
    'dengan',
    'agar',
  };


  SmartActivitySuggestion? analyze(String input, {String localeCode = 'id'}) {
    final String normalized = _normalize(input);
    if (normalized.isEmpty) {
      return null;
    }

    final SmartActivityType type = _detectType(normalized);
    final _ActivityMatch? match = _findBestProfile(normalized);
    if (match == null && _meaningfulCharacterCount(normalized) < 3) {
      return null;
    }
    final _ActivityProfile? profile = match?.profile;
    final SmartActivityCategory? fallbackCategory = _detectCategoryFallback(
      normalized,
    );
    if (profile == null && fallbackCategory == null) {
      return null;
    }
    final SmartActivityCategory category =
        profile?.category ?? fallbackCategory!;
    final SmartActivityLocalPlan localPlan =
        profile?.localPlan ?? _defaultLocalPlanForCategory(category);
    final String keyword =
        profile?.canonicalKeyword ??
        match?.matchedAlias ??
        _extractKeyword(normalized, type);
    final String familyLabel = _familyLabel(
      profile?.family ?? _familyFromCategory(category),
      localeCode: localeCode,
    );

    if (type == SmartActivityType.action) {
      if (profile?.needsTitleDetail ?? false) {
        return SmartActivitySuggestion(
          type: type,
          category: category,
          keyword: keyword,
          familyLabel: familyLabel,
          localPlan: localPlan,
          needsTitleDetail: true,
          detailPrompt: _buildDetailPrompt(
            profile!.detailPromptKey!,
            localeCode: localeCode,
          ),
          suggestedTitles: _buildSuggestedTitles(
            profile,
            localeCode: localeCode,
          ),
          reason: localeCode == 'id'
              ? 'Tambahkan konteks di judul dulu supaya rekomendasi jam lebih akurat.'
              : 'Add more context in the title first so the time recommendation is more accurate.',
        );
      }

      final _ActionRecommendation recommendation = _recommendAction(
        category: category,
        profile: profile,
        localeCode: localeCode,
      );

      return SmartActivitySuggestion(
        type: type,
        category: category,
        keyword: keyword,
        familyLabel: familyLabel,
        localPlan: localPlan,
        recommendedTimeMinutes: recommendation.timeMinutes,
        reason: recommendation.reason,
      );
    }

    return SmartActivitySuggestion(
      type: type,
      category: category,
      keyword: keyword,
      familyLabel: familyLabel,
      localPlan: localPlan,
      tracking: _buildTracking(keyword, localeCode: localeCode),
      insight: _buildAvoidanceInsight(
        normalized,
        profile: profile,
        localeCode: localeCode,
      ),
    );
  }

  String _normalize(String input) {
    final String lowercase = input.toLowerCase().trim();
    final String alphanumericOnly = lowercase.replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      ' ',
    );
    return alphanumericOnly.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  SmartActivityType _detectType(String normalized) {
    final List<String> words = normalized.split(' ');
    for (final String word in words) {
      if (_avoidanceTerms.contains(word)) {
        return SmartActivityType.avoidance;
      }
    }
    return SmartActivityType.action;
  }

  _ActivityMatch? _findBestProfile(String normalized) {
    _ActivityMatch? bestMatch;
    for (final _ActivityProfile profile in _profiles) {
      for (final String alias in profile.aliases) {
        if (!normalized.contains(alias)) {
          continue;
        }
        if (bestMatch == null || alias.length > bestMatch.matchedAlias.length) {
          bestMatch = _ActivityMatch(profile: profile, matchedAlias: alias);
        }
      }
    }
    return bestMatch;
  }

  SmartActivityCategory? _detectCategoryFallback(String normalized) {
    if (_containsAny(normalized, <String>[
      'olahraga',
      'lari',
      'jogging',
      'berenang',
      'renang',
      'gym',
      'sarapan',
      'makan',
      'minum air',
      'mandi',
      'skincare',
      'obat',
      'vitamin',
      'rokok',
      'merokok',
      'diet',
      'gula',
    ])) {
      return SmartActivityCategory.kesehatan;
    }

    if (_containsAny(normalized, <String>[
      'belajar',
      'kerja',
      'coding',
      'rapat',
      'meeting',
      'beberes',
      'bersih',
      'tugas',
      'kelas',
      'kuliah',
      'sekolah',
    ])) {
      return SmartActivityCategory.produktif;
    }

    if (_containsAny(normalized, <String>[
      'tidur',
      'begadang',
      'istirahat',
      'break',
      'meditasi',
      'nonton',
      'game',
      'healing',
    ])) {
      return SmartActivityCategory.istirahat;
    }

    if (_containsAny(normalized, <String>[
      'telepon',
      'nelpon',
      'chat',
      'ngobrol',
      'teman',
      'keluarga',
      'nongkrong',
      'pasangan',
    ])) {
      return SmartActivityCategory.sosial;
    }

    return null;
  }

  String _extractKeyword(String normalized, SmartActivityType type) {
    final String? matchedPhrase = _matchKeywordPhrase(normalized);
    if (matchedPhrase != null) {
      return matchedPhrase;
    }

    final List<String> words = normalized.split(' ');
    if (type == SmartActivityType.avoidance) {
      final int avoidanceIndex = words.indexWhere(_avoidanceTerms.contains);
      if (avoidanceIndex >= 0) {
        for (int index = avoidanceIndex + 1; index < words.length; index++) {
          final String word = words[index];
          if (_ignoredWords.contains(word)) {
            continue;
          }
          return word;
        }
      }
    }

    for (final String word in words) {
      if (_avoidanceTerms.contains(word) || _ignoredWords.contains(word)) {
        continue;
      }
      return word;
    }

    return words.isEmpty ? '' : words.last;
  }

  String? _matchKeywordPhrase(String normalized) {
    const List<String> phrases = <String>[
      'minum air',
      'tidur siang',
      'jalan pagi',
      'jalan kaki',
      'makan sehat',
      'makan siang',
      'makan malam',
      'junk food',
      'media sosial',
      'main game',
      'baca buku',
      'membaca buku',
      'quality time',
      'latihan soal',
      'cuci muka',
      'sikat gigi',
      'cuci piring',
      'cuci baju',
    ];

    for (final String phrase in phrases) {
      if (normalized.contains(phrase)) {
        return phrase;
      }
    }
    return null;
  }

  _ActionRecommendation _recommendAction({
    required SmartActivityCategory category,
    _ActivityProfile? profile,
    required String localeCode,
  }) {
    final _ActionReason? reasonKey = profile?.actionReasonKey;
    if (profile != null &&
        profile.defaultTimeMinutes != null &&
        reasonKey != null) {
      return _ActionRecommendation(
        timeMinutes: profile.defaultTimeMinutes!,
        reason: _actionReason(reasonKey, localeCode: localeCode),
      );
    }

    switch (category) {
      case SmartActivityCategory.kesehatan:
        return _ActionRecommendation(
          timeMinutes: 7 * 60,
          reason: localeCode == 'id'
              ? 'Pagi membantu aktivitas kesehatan terasa lebih ringan dijalankan.'
              : 'Morning makes health routines easier to keep up.',
        );
      case SmartActivityCategory.produktif:
        return _ActionRecommendation(
          timeMinutes: 19 * 60,
          reason: localeCode == 'id'
              ? 'Setelah aktivitas utama selesai, waktu ini lebih realistis untuk rutinitas produktif.'
              : 'After the main day is done, this time is more realistic for productive routines.',
        );
      case SmartActivityCategory.istirahat:
        return _ActionRecommendation(
          timeMinutes: 21 * 60 + 30,
          reason: localeCode == 'id'
              ? 'Menjelang malam membantu tubuh masuk ke mode istirahat.'
              : 'Late evening helps your body shift into rest mode.',
        );
      case SmartActivityCategory.sosial:
        return _ActionRecommendation(
          timeMinutes: 18 * 60,
          reason: localeCode == 'id'
              ? 'Sore biasanya lebih mudah dipakai untuk menyapa orang lain.'
              : 'Late afternoon is often easier for reaching out to people.',
        );
      case SmartActivityCategory.umum:
        return _ActionRecommendation(
          timeMinutes: 8 * 60,
          reason: localeCode == 'id'
              ? 'Pagi cukup netral untuk memulai kebiasaan baru.'
              : 'Morning is a neutral starting point for a new habit.',
        );
    }
  }

  String _actionReason(_ActionReason reason, {required String localeCode}) {
    switch (reason) {
      case _ActionReason.olahragaPagi:
        return localeCode == 'id'
            ? 'Aktivitas olahraga umumnya lebih ideal dijadwalkan pada pagi hari agar lebih konsisten dan tidak mudah bertabrakan dengan agenda lain.'
            : 'Exercise is usually safest in the morning so it stays consistent and avoids clashes with other plans.';
      case _ActionReason.hidrasiPagi:
        return localeCode == 'id'
            ? 'Pengingat awal hari membantu kebiasaan minum air mulai lebih cepat.'
            : 'An early-day reminder helps your hydration habit start sooner.';
      case _ActionReason.sarapanPagi:
        return localeCode == 'id'
            ? 'Sarapan paling ideal dijadwalkan pada pagi hari sebelum aktivitas utama dimulai.'
            : 'Breakfast makes the most sense in the morning before the main day starts.';
      case _ActionReason.makanSiang:
        return localeCode == 'id'
            ? 'Makan siang lebih tepat dijadwalkan di tengah hari agar energi tetap stabil.'
            : 'Lunch fits best around midday to keep your energy stable.';
      case _ActionReason.makanMalam:
        return localeCode == 'id'
            ? 'Makan malam lebih nyaman dijadwalkan setelah aktivitas utama selesai.'
            : 'Dinner is more realistic after your main activities are done.';
      case _ActionReason.perawatanPagi:
        return localeCode == 'id'
            ? 'Rutinitas perawatan diri biasanya lebih mudah konsisten jika dijadwalkan pada awal hari.'
            : 'Personal care routines are usually easiest to keep at the start of the day.';
      case _ActionReason.kesehatanPagi:
        return localeCode == 'id'
            ? 'Aktivitas kesehatan ringan cocok dijadwalkan pada pagi hari agar tidak mudah terlewat.'
            : 'Light health routines fit well in the morning so they are harder to forget.';
      case _ActionReason.tidurSiang:
        return localeCode == 'id'
            ? 'Awal siang pas untuk rehat singkat tanpa terlalu mengganggu tidur malam.'
            : 'Early afternoon works well for a short rest without hurting night sleep too much.';
      case _ActionReason.tidurMalam:
        return localeCode == 'id'
            ? 'Malam lebih cocok untuk menutup hari dan menjaga ritme istirahat.'
            : 'Night time fits better for winding down and protecting your rest rhythm.';
      case _ActionReason.rehatRingan:
        return localeCode == 'id'
            ? 'Jeda singkat di tengah hari biasanya lebih realistis untuk memulihkan energi tanpa mengganggu ritme utama.'
            : 'A short midday break is usually more realistic for restoring energy without disturbing your main routine.';
      case _ActionReason.rehatMalam:
        return localeCode == 'id'
            ? 'Menjelang malam cocok untuk membantu transisi dari aktivitas yang sibuk menuju waktu istirahat.'
            : 'Late evening is good for easing out of busy mode into rest mode.';
      case _ActionReason.meditasiMalam:
        return localeCode == 'id'
            ? 'Meditasi malam membantu tubuh lebih tenang sebelum tidur.'
            : 'Evening meditation can calm your body before sleep.';
      case _ActionReason.belajarSore:
        return localeCode == 'id'
            ? 'Sore ke malam cukup realistis untuk belajar setelah sekolah atau kerja.'
            : 'Late afternoon to evening is realistic for studying after school or work.';
      case _ActionReason.kerjaPagi:
        return localeCode == 'id'
            ? 'Pagi hari umumnya menjadi waktu yang paling baik untuk blok fokus utama.'
            : 'Morning work hours are usually best for your main focus block.';
      case _ActionReason.rumahSore:
        return localeCode == 'id'
            ? 'Sore hari cukup ideal untuk urusan rumah karena aktivitas utama biasanya sudah mulai mereda.'
            : 'Late afternoon fits household tasks because the main day is usually winding down.';
      case _ActionReason.sosialSore:
        return localeCode == 'id'
            ? 'Menjelang malam biasanya menjadi waktu yang lebih leluasa untuk aktivitas sosial.'
            : 'Early evening is usually the easiest window for social time.';
      case _ActionReason.hiburanMalam:
        return localeCode == 'id'
            ? 'Waktu santai biasanya lebih nyaman dijadwalkan setelah tanggung jawab utama selesai.'
            : 'Leisure time is usually best after your main responsibilities are done.';
    }
  }

  String _buildTracking(String keyword, {required String localeCode}) {
    if (localeCode == 'id') {
      return 'Pantau setiap hari apakah berhasil menghindari $keyword.';
    }
    return 'Track each day whether you successfully avoided $keyword.';
  }

  String _buildAvoidanceInsight(
    String normalized, {
    _ActivityProfile? profile,
    required String localeCode,
  }) {
    if (_containsAny(normalized, <String>['merokok', 'rokok'])) {
      return localeCode == 'id'
          ? 'Godaan sering naik saat stres, setelah makan, atau malam hari.'
          : 'Cravings often rise during stress, after meals, or late at night.';
    }

    if (_containsAny(normalized, <String>['begadang', 'tidur larut'])) {
      return localeCode == 'id'
          ? 'Risiko tertinggi biasanya muncul setelah pukul 22:00.'
          : 'The highest-risk window usually starts after 22:00.';
    }

    if (_containsAny(normalized, <String>['gula', 'junk food', 'snack'])) {
      return localeCode == 'id'
          ? 'Lapar sore dan stok camilan di dekatmu sering jadi pemicu utama.'
          : 'Late-afternoon hunger and nearby snacks are often the main triggers.';
    }

    if (_containsAny(normalized, <String>[
      'media sosial',
      'scroll',
      'scrolling',
      'main game',
      'game',
    ])) {
      return localeCode == 'id'
          ? 'Godaan biasanya muncul saat jeda singkat atau sebelum tidur.'
          : 'The urge usually shows up during short breaks or before sleep.';
    }

    if (profile?.family == _ActivityFamily.makan) {
      return localeCode == 'id'
          ? 'Pemicu paling sering muncul saat lapar, terburu-buru, atau stok makanan tidak teratur.'
          : 'The biggest triggers usually show up when you are hungry, rushed, or your food options are unplanned.';
    }

    return localeCode == 'id'
        ? 'Pemicu paling sering muncul saat capek atau tidak punya rencana pengganti.'
        : 'Triggers usually appear when you are tired or have no replacement plan.';
  }

  _ActivityFamily _familyFromCategory(SmartActivityCategory category) {
    switch (category) {
      case SmartActivityCategory.kesehatan:
        return _ActivityFamily.kesehatan;
      case SmartActivityCategory.produktif:
        return _ActivityFamily.produktif;
      case SmartActivityCategory.istirahat:
        return _ActivityFamily.rehat;
      case SmartActivityCategory.sosial:
        return _ActivityFamily.sosial;
      case SmartActivityCategory.umum:
        return _ActivityFamily.umum;
    }
  }

  SmartActivityLocalPlan _defaultLocalPlanForCategory(
    SmartActivityCategory category,
  ) {
    switch (category) {
      case SmartActivityCategory.kesehatan:
        return const SmartActivityLocalPlan(
          minSessionsPerWeek: 3,
          maxSessionsPerWeek: 7,
          minGapDays: 0,
          dayStrategy: SmartActivityDayStrategy.flexible,
          preferredTimeWindows: <SmartActivityTimeWindow>[
            SmartActivityTimeWindow.morning,
            SmartActivityTimeWindow.evening,
          ],
          effortLevel: SmartActivityEffortLevel.medium,
        );
      case SmartActivityCategory.produktif:
        return const SmartActivityLocalPlan(
          minSessionsPerWeek: 4,
          maxSessionsPerWeek: 6,
          minGapDays: 0,
          dayStrategy: SmartActivityDayStrategy.workdayFriendly,
          preferredTimeWindows: <SmartActivityTimeWindow>[
            SmartActivityTimeWindow.morning,
            SmartActivityTimeWindow.evening,
          ],
          effortLevel: SmartActivityEffortLevel.medium,
        );
      case SmartActivityCategory.istirahat:
        return const SmartActivityLocalPlan(
          minSessionsPerWeek: 4,
          maxSessionsPerWeek: 7,
          minGapDays: 0,
          dayStrategy: SmartActivityDayStrategy.flexible,
          preferredTimeWindows: <SmartActivityTimeWindow>[
            SmartActivityTimeWindow.afternoon,
            SmartActivityTimeWindow.night,
          ],
          effortLevel: SmartActivityEffortLevel.low,
        );
      case SmartActivityCategory.sosial:
        return const SmartActivityLocalPlan(
          minSessionsPerWeek: 1,
          maxSessionsPerWeek: 3,
          minGapDays: 1,
          dayStrategy: SmartActivityDayStrategy.weekendFriendly,
          preferredTimeWindows: <SmartActivityTimeWindow>[
            SmartActivityTimeWindow.evening,
            SmartActivityTimeWindow.night,
          ],
          effortLevel: SmartActivityEffortLevel.medium,
        );
      case SmartActivityCategory.umum:
        return const SmartActivityLocalPlan(
          minSessionsPerWeek: 2,
          maxSessionsPerWeek: 4,
          minGapDays: 1,
          dayStrategy: SmartActivityDayStrategy.flexible,
          preferredTimeWindows: <SmartActivityTimeWindow>[
            SmartActivityTimeWindow.morning,
          ],
          effortLevel: SmartActivityEffortLevel.medium,
        );
    }
  }

  String _familyLabel(_ActivityFamily family, {required String localeCode}) {
    switch (family) {
      case _ActivityFamily.olahraga:
        return localeCode == 'id' ? 'Olahraga' : 'Exercise';
      case _ActivityFamily.hidrasi:
        return localeCode == 'id' ? 'Hidrasi' : 'Hydration';
      case _ActivityFamily.makan:
        return localeCode == 'id' ? 'Makan' : 'Meals';
      case _ActivityFamily.perawatanDiri:
        return localeCode == 'id' ? 'Perawatan diri' : 'Self care';
      case _ActivityFamily.kesehatan:
        return localeCode == 'id' ? 'Kesehatan' : 'Health';
      case _ActivityFamily.tidur:
        return localeCode == 'id' ? 'Tidur' : 'Sleep';
      case _ActivityFamily.rehat:
        return localeCode == 'id' ? 'Rehat' : 'Rest';
      case _ActivityFamily.belajar:
        return localeCode == 'id' ? 'Belajar' : 'Study';
      case _ActivityFamily.kerja:
        return localeCode == 'id' ? 'Kerja' : 'Work';
      case _ActivityFamily.rumah:
        return localeCode == 'id' ? 'Urusan rumah' : 'Home tasks';
      case _ActivityFamily.produktif:
        return localeCode == 'id' ? 'Produktif' : 'Productive';
      case _ActivityFamily.sosial:
        return localeCode == 'id' ? 'Sosial' : 'Social';
      case _ActivityFamily.hiburan:
        return localeCode == 'id' ? 'Hiburan' : 'Leisure';
      case _ActivityFamily.umum:
        return localeCode == 'id' ? 'Umum' : 'General';
    }
  }

  String _familyKey(_ActivityFamily family) {
    return switch (family) {
      _ActivityFamily.olahraga => 'olahraga',
      _ActivityFamily.hidrasi => 'hidrasi',
      _ActivityFamily.makan => 'makan',
      _ActivityFamily.perawatanDiri => 'perawatanDiri',
      _ActivityFamily.kesehatan => 'kesehatan',
      _ActivityFamily.tidur => 'tidur',
      _ActivityFamily.rehat => 'rehat',
      _ActivityFamily.belajar => 'belajar',
      _ActivityFamily.kerja => 'kerja',
      _ActivityFamily.rumah => 'rumah',
      _ActivityFamily.produktif => 'produktif',
      _ActivityFamily.sosial => 'sosial',
      _ActivityFamily.hiburan => 'hiburan',
      _ActivityFamily.umum => 'umum',
    };
  }

  String _categoryKey(SmartActivityCategory category) {
    return switch (category) {
      SmartActivityCategory.kesehatan => 'kesehatan',
      SmartActivityCategory.produktif => 'produktif',
      SmartActivityCategory.istirahat => 'istirahat',
      SmartActivityCategory.sosial => 'sosial',
      SmartActivityCategory.umum => 'umum',
    };
  }

  String _effortLevelKey(SmartActivityEffortLevel effortLevel) {
    return switch (effortLevel) {
      SmartActivityEffortLevel.low => 'low',
      SmartActivityEffortLevel.medium => 'medium',
      SmartActivityEffortLevel.high => 'high',
    };
  }

  String _buildDetailPrompt(
    _DetailPrompt prompt, {
    required String localeCode,
  }) {
    switch (prompt) {
      case _DetailPrompt.mealSpecificity:
        return localeCode == 'id'
            ? 'Judul `makan` masih terlalu umum. Tulis lebih spesifik seperti `sarapan`, `makan siang`, atau `makan malam` supaya jamnya tepat.'
            : 'The title `eat` is still too broad. Be more specific with `breakfast`, `lunch`, or `dinner` so the time is accurate.';
    }
  }

  List<String> _buildSuggestedTitles(
    _ActivityProfile profile, {
    required String localeCode,
  }) {
    switch (profile.detailPromptKey) {
      case _DetailPrompt.mealSpecificity:
        return localeCode == 'id'
            ? const <String>['Sarapan', 'Makan siang', 'Makan malam']
            : const <String>['Breakfast', 'Lunch', 'Dinner'];
      case null:
        return const <String>[];
    }
  }

  bool _containsAny(String source, List<String> patterns) {
    for (final String pattern in patterns) {
      if (source.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  int _meaningfulCharacterCount(String normalized) {
    final Iterable<String> meaningfulWords = normalized
        .split(' ')
        .where(
          (String word) =>
              word.isNotEmpty &&
              !_ignoredWords.contains(word) &&
              !_avoidanceTerms.contains(word),
        );
    return meaningfulWords.fold<int>(
      0,
      (int total, String word) => total + word.length,
    );
  }

  List<int> _fallbackWeekdaysForPlan(SmartActivityLocalPlan plan) {
    switch (plan.dayStrategy) {
      case SmartActivityDayStrategy.daily:
        return const <int>[1, 2, 3, 4, 5, 6, 7];
      case SmartActivityDayStrategy.spaced:
        return plan.maxSessionsPerWeek >= 3
            ? const <int>[2, 4, 6]
            : const <int>[2, 5];
      case SmartActivityDayStrategy.workdayFriendly:
        return plan.maxSessionsPerWeek >= 5
            ? const <int>[1, 2, 3, 4, 5]
            : const <int>[1, 3, 5];
      case SmartActivityDayStrategy.weekendFriendly:
        return plan.maxSessionsPerWeek >= 3
            ? const <int>[5, 6, 7]
            : const <int>[6, 7];
      case SmartActivityDayStrategy.flexible:
        return plan.maxSessionsPerWeek >= 4
            ? const <int>[1, 3, 5, 7]
            : const <int>[2, 4, 6];
    }
  }
}

enum _ActivityFamily {
  olahraga,
  hidrasi,
  makan,
  perawatanDiri,
  kesehatan,
  tidur,
  rehat,
  belajar,
  kerja,
  rumah,
  produktif,
  sosial,
  hiburan,
  umum,
}

enum _ActionReason {
  olahragaPagi,
  hidrasiPagi,
  sarapanPagi,
  makanSiang,
  makanMalam,
  perawatanPagi,
  kesehatanPagi,
  tidurSiang,
  tidurMalam,
  rehatRingan,
  rehatMalam,
  meditasiMalam,
  belajarSore,
  kerjaPagi,
  rumahSore,
  sosialSore,
  hiburanMalam,
}

enum _DetailPrompt { mealSpecificity }

class _ActivityProfile {
  const _ActivityProfile({
    required this.family,
    required this.aliases,
    required this.category,
    this.localPlan,
    this.canonicalKeyword,
    this.defaultTimeMinutes,
    this.actionReasonKey,
    this.needsTitleDetail = false,
    this.detailPromptKey,
  });

  final _ActivityFamily family;
  final List<String> aliases;
  final SmartActivityCategory category;
  final SmartActivityLocalPlan? localPlan;
  final String? canonicalKeyword;
  final int? defaultTimeMinutes;
  final _ActionReason? actionReasonKey;
  final bool needsTitleDetail;
  final _DetailPrompt? detailPromptKey;

  factory _ActivityProfile.fromJson(Map<String, dynamic> json) {
    final Object? localPlanJson = json['localPlan'];
    return _ActivityProfile(
      family: _parseActivityFamily(json['family'] as String?),
      aliases: (json['aliases'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .where((String item) => item.trim().isNotEmpty)
          .toList(growable: false),
      category: _parseCategory(json['category'] as String?),
      localPlan: localPlanJson is Map<String, dynamic>
          ? _parseLocalPlan(localPlanJson)
          : null,
      canonicalKeyword: json['canonicalKeyword'] as String?,
      defaultTimeMinutes: (json['defaultTimeMinutes'] as num?)?.toInt(),
      actionReasonKey: _parseActionReason(json['actionReasonKey'] as String?),
      needsTitleDetail: json['needsTitleDetail'] == true,
      detailPromptKey: _parseDetailPrompt(json['detailPromptKey'] as String?),
    );
  }

  static SmartActivityLocalPlan _parseLocalPlan(Map<String, dynamic> json) {
    final List<SmartActivityTimeWindow> preferredTimeWindows =
        (json['preferredTimeWindows'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => _parseTimeWindow(item as String?))
            .toList(growable: false);
    final SmartActivityRoutinePlacement routinePlacement =
        _parseRoutinePlacement(json['routinePlacement'] as String?) ??
        _deriveLegacyRoutinePlacement(
          preferredTimeWindows: preferredTimeWindows,
          routineCompatible: json['routineCompatible'] == true,
        );
    return SmartActivityLocalPlan(
      minSessionsPerWeek: (json['minSessionsPerWeek'] as num?)?.toInt() ?? 1,
      maxSessionsPerWeek: (json['maxSessionsPerWeek'] as num?)?.toInt() ?? 1,
      minGapDays: (json['minGapDays'] as num?)?.toInt() ?? 0,
      dayStrategy: _parseDayStrategy(json['dayStrategy'] as String?),
      preferredTimeWindows: preferredTimeWindows,
      effortLevel: _parseEffortLevel(json['effortLevel'] as String?),
      routineCompatible:
          json['routineCompatible'] == true ||
          routinePlacement != SmartActivityRoutinePlacement.none,
      routinePlacement: routinePlacement,
    );
  }
}

_ActivityFamily _parseActivityFamily(String? value) {
  return switch (value) {
    'olahraga' => _ActivityFamily.olahraga,
    'hidrasi' => _ActivityFamily.hidrasi,
    'makan' => _ActivityFamily.makan,
    'perawatanDiri' => _ActivityFamily.perawatanDiri,
    'kesehatan' => _ActivityFamily.kesehatan,
    'tidur' => _ActivityFamily.tidur,
    'rehat' => _ActivityFamily.rehat,
    'belajar' => _ActivityFamily.belajar,
    'kerja' => _ActivityFamily.kerja,
    'rumah' => _ActivityFamily.rumah,
    'produktif' => _ActivityFamily.produktif,
    'sosial' => _ActivityFamily.sosial,
    'hiburan' => _ActivityFamily.hiburan,
    _ => _ActivityFamily.umum,
  };
}

SmartActivityCategory _parseCategory(String? value) {
  return switch (value) {
    'kesehatan' => SmartActivityCategory.kesehatan,
    'produktif' => SmartActivityCategory.produktif,
    'istirahat' => SmartActivityCategory.istirahat,
    'sosial' => SmartActivityCategory.sosial,
    _ => SmartActivityCategory.umum,
  };
}

SmartActivityDayStrategy _parseDayStrategy(String? value) {
  return switch (value) {
    'daily' => SmartActivityDayStrategy.daily,
    'spaced' => SmartActivityDayStrategy.spaced,
    'workdayFriendly' => SmartActivityDayStrategy.workdayFriendly,
    'weekendFriendly' => SmartActivityDayStrategy.weekendFriendly,
    _ => SmartActivityDayStrategy.flexible,
  };
}

SmartActivityTimeWindow _parseTimeWindow(String? value) {
  return switch (value) {
    'earlyMorning' => SmartActivityTimeWindow.earlyMorning,
    'morning' => SmartActivityTimeWindow.morning,
    'midday' => SmartActivityTimeWindow.midday,
    'afternoon' => SmartActivityTimeWindow.afternoon,
    'evening' => SmartActivityTimeWindow.evening,
    _ => SmartActivityTimeWindow.night,
  };
}

SmartActivityRoutinePlacement? _parseRoutinePlacement(String? value) {
  return switch (value) {
    'beforeStart' => SmartActivityRoutinePlacement.beforeStart,
    'duringRoutine' => SmartActivityRoutinePlacement.duringRoutine,
    'afterEnd' => SmartActivityRoutinePlacement.afterEnd,
    'outsideRoutine' => SmartActivityRoutinePlacement.outsideRoutine,
    'anytime' => SmartActivityRoutinePlacement.anytime,
    'none' => SmartActivityRoutinePlacement.none,
    _ => null,
  };
}

SmartActivityRoutinePlacement _deriveLegacyRoutinePlacement({
  required List<SmartActivityTimeWindow> preferredTimeWindows,
  required bool routineCompatible,
}) {
  if (!routineCompatible) {
    return SmartActivityRoutinePlacement.none;
  }

  final Set<SmartActivityTimeWindow> windows = preferredTimeWindows.toSet();
  final bool hasMorning =
      windows.contains(SmartActivityTimeWindow.earlyMorning) ||
      windows.contains(SmartActivityTimeWindow.morning);
  final bool hasMidday =
      windows.contains(SmartActivityTimeWindow.midday) ||
      windows.contains(SmartActivityTimeWindow.afternoon);
  final bool hasEvening =
      windows.contains(SmartActivityTimeWindow.evening) ||
      windows.contains(SmartActivityTimeWindow.night);

  if (hasMidday && !hasMorning && !hasEvening) {
    return SmartActivityRoutinePlacement.duringRoutine;
  }
  if (hasMorning && !hasMidday && !hasEvening) {
    return SmartActivityRoutinePlacement.beforeStart;
  }
  if (hasEvening && !hasMorning && !hasMidday) {
    return SmartActivityRoutinePlacement.afterEnd;
  }
  if (hasMidday && (hasMorning || hasEvening)) {
    return SmartActivityRoutinePlacement.duringRoutine;
  }
  if (hasMorning || hasEvening) {
    return SmartActivityRoutinePlacement.outsideRoutine;
  }
  return SmartActivityRoutinePlacement.anytime;
}

SmartActivityEffortLevel _parseEffortLevel(String? value) {
  return switch (value) {
    'low' => SmartActivityEffortLevel.low,
    'high' => SmartActivityEffortLevel.high,
    _ => SmartActivityEffortLevel.medium,
  };
}

_ActionReason? _parseActionReason(String? value) {
  return switch (value) {
    'olahragaPagi' => _ActionReason.olahragaPagi,
    'hidrasiPagi' => _ActionReason.hidrasiPagi,
    'sarapanPagi' => _ActionReason.sarapanPagi,
    'makanSiang' => _ActionReason.makanSiang,
    'makanMalam' => _ActionReason.makanMalam,
    'perawatanPagi' => _ActionReason.perawatanPagi,
    'kesehatanPagi' => _ActionReason.kesehatanPagi,
    'tidurSiang' => _ActionReason.tidurSiang,
    'tidurMalam' => _ActionReason.tidurMalam,
    'rehatRingan' => _ActionReason.rehatRingan,
    'rehatMalam' => _ActionReason.rehatMalam,
    'meditasiMalam' => _ActionReason.meditasiMalam,
    'belajarSore' => _ActionReason.belajarSore,
    'kerjaPagi' => _ActionReason.kerjaPagi,
    'rumahSore' => _ActionReason.rumahSore,
    'sosialSore' => _ActionReason.sosialSore,
    'hiburanMalam' => _ActionReason.hiburanMalam,
    _ => null,
  };
}

_DetailPrompt? _parseDetailPrompt(String? value) {
  return switch (value) {
    'mealSpecificity' => _DetailPrompt.mealSpecificity,
    _ => null,
  };
}

class _ActivityMatch {
  const _ActivityMatch({required this.profile, required this.matchedAlias});

  final _ActivityProfile profile;
  final String matchedAlias;
}

class _ActionRecommendation {
  const _ActionRecommendation({
    required this.timeMinutes,
    required this.reason,
  });

  final int timeMinutes;
  final String reason;
}
