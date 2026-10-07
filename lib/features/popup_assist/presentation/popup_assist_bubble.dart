import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:liburan_create/core/widgets/nousen_nav_icon.dart';

class PopUpAssistBubbleApp extends StatefulWidget {
  const PopUpAssistBubbleApp({super.key});

  @override
  State<PopUpAssistBubbleApp> createState() => _PopUpAssistBubbleAppState();
}

class _PopUpAssistBubbleAppState extends State<PopUpAssistBubbleApp> {
  bool _isExpanded = false;
  bool _isTransitioning = false;
  bool _isCardClosing = false;
  String _activityId = '';
  String _activityTitle = 'NOUSEN Assist';
  String _timeLabel = 'Siap mendampingi';
  String _speechText = '';
  List<dynamic> _todaySchedules = <dynamic>[];
  final Set<String> _announcedScheduleKeys = <String>{};
  int _streak = 0;
  List<String> _subActivities = <String>[];
  Set<String> _completedSubActivities = <String>{};
  bool _isCompleted = false;
  bool _isSkipped = false;
  String? _statusBanner;

  bool _isIdle = false;
  bool _isNearDismiss = false;
  String _bubbleSide = 'right'; // which screen edge the bubble is on
  bool _showSpeechLabel = false;
  bool _isSpeechFadingOut = false; // retract: speech menyusut masuk ke sisi icon
  int _speechEpoch = 0; // memicu replay entrance animation tiap trigger speech
  int _speechGen = 0; // generation guard: chain lama mati saat trigger baru masuk
  bool _greetingShown = false; // debounce: greeting 1x per sesi overlay
  Timer? _speechTimer;
  Timer? _scheduleTicker;
  Timer? _idleTimer;
  Timer? _autoMinimizeTimer;
  Timer? _echoTimer;
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();
    _startScheduleTicker();

    _overlaySubscription =
        FlutterOverlayWindow.overlayListener.listen((dynamic event) {
      if (event == null) return;
      try {
        final Map<String, dynamic> data = event is String
            ? jsonDecode(event) as Map<String, dynamic>
            : Map<String, dynamic>.from(event as Map);

        if (data['type'] == 'drag_near_dismiss') {
          final bool isNear = data['isNear'] == true;
          if (_isNearDismiss != isNear) {
            _plog('drag_near_dismiss isNear=$isNear');
            setState(() {
              _isNearDismiss = isNear;
              if (isNear) {
                _isIdle = false;
                _showSpeechLabel = false;
                _speechTimer?.cancel();
              }
            });
          }
          return;
        }

        if (data['type'] == 'reset_state' ||
            data['type'] == 'overlay_dismissed_by_user') {
          setState(() {
            _isNearDismiss = false;
            _isIdle = false;
            _isCardClosing = false;
            _greetingShown = false; // sesi baru -> greeting boleh tampil 1x lagi
          });
          return;
        }

        if (data['type'] == 'request_expand') {
          _plog('request_expand');
          if (!_isExpanded && !_isTransitioning && !_isCardClosing) {
            _expandOverlay();
          }
          return;
        }

        if (data['type'] == 'request_collapse') {
          _plog('request_collapse');
          if (_isExpanded && !_isTransitioning && !_isCardClosing) {
            _collapseOverlay();
          }
          return;
        }

        if (data['type'] == 'bubble_side') {
          final String side = data['side']?.toString() ?? 'right';
          if (_bubbleSide != side) {
            _plog('bubble_side=$side');
            setState(() => _bubbleSide = side);
          }
          return;
        }

        if (data['todaySchedules'] is List) {
          _todaySchedules = List<dynamic>.from(data['todaySchedules'] as List);
          _checkScheduleTick();
        }

        // Debounce: event yang sama bisa membawa sync_activity + schedules,
        // jadi hanya trigger greeting yang di-skip (tanpa return agar sync tetap jalan).
        if (data['isGreeting'] == true &&
            data['speechText'] != null &&
            !_greetingShown) {
          final String greeting = data['speechText'].toString();
          if (greeting.isNotEmpty && !_isExpanded && !_isNearDismiss) {
            _greetingShown = true;
            _plog('speech=greeting delayed 1500ms');
            setState(() {
              _speechText = greeting;
            });
            // Cold start: main thread masih berat (Choreographer skip frames).
            // Tunda trigger agar resize+render tidak desync (glitch expand).
            Future<void>.delayed(const Duration(milliseconds: 1500), () {
              if (!mounted || _isExpanded || _isNearDismiss) return;
              _triggerSpeechLabel();
            });
          }
        }

        if (data['type'] == 'sync_activity' || data.containsKey('title')) {
          // Echo kebenaran dari app tiba: batalkan watchdog rollback.
          _echoTimer?.cancel();
          setState(() {
            if (data['activityId'] != null) {
              _activityId = data['activityId'].toString();
            }
            if (data['title'] != null) {
              _activityTitle = data['title'].toString();
            }
            if (data['time'] != null) {
              _timeLabel = data['time'].toString();
            }
            if (data['streak'] != null) {
              _streak = int.tryParse(data['streak'].toString()) ?? 0;
            }
            if (data['subActivities'] is List) {
              _subActivities = (data['subActivities'] as List)
                  .map((e) => e.toString())
                  .toList();
            }
            if (data['completedSubActivities'] is List) {
              _completedSubActivities = (data['completedSubActivities'] as List)
                  .map((e) => e.toString())
                  .toSet();
            }
            if (data['isCompleted'] != null) {
              _isCompleted = data['isCompleted'] == true;
            }
            if (data['isSkipped'] != null) {
              _isSkipped = data['isSkipped'] == true;
            }
          });
        }
      } catch (_) {}
    });

    // Request initial data from main app
    FlutterOverlayWindow.shareData(
      jsonEncode(<String, dynamic>{'type': 'request_sync'}),
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _autoMinimizeTimer?.cancel();
    _speechTimer?.cancel();
    _scheduleTicker?.cancel();
    _echoTimer?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
  }

  void _plog(String event) {
    debugPrint('[PopUpAssist] $event');
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isIdle) {
      setState(() => _isIdle = false);
      _plog('idle=off (activity)');
    }
    if (!_isExpanded) {
      _idleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_isExpanded) {
          setState(() => _isIdle = true);
          _plog('idle=on (alpha transparan)');
        }
      });
    }
  }

  void _startScheduleTicker() {
    _scheduleTicker?.cancel();
    _checkScheduleTick();
    _scheduleTicker = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkScheduleTick();
    });
  }

  void _checkScheduleTick() {
    if (_isExpanded || _isNearDismiss || _todaySchedules.isEmpty) return;
    final DateTime now = DateTime.now();
    final int currentMinutes = now.hour * 60 + now.minute;
    final String datePrefix = '${now.year}_${now.month}_${now.day}';

    for (final dynamic item in _todaySchedules) {
      if (item is! Map) continue;
      final Map<String, dynamic> schedule = Map<String, dynamic>.from(item);
      final int? timeMin = schedule['timeMinutes'] as int?;
      final String id = schedule['id']?.toString() ?? '';
      final String title = schedule['title']?.toString() ?? '';
      final bool isDone = schedule['isCompleted'] == true;
      final bool isSkip = schedule['isSkipped'] == true;

      if (timeMin != null && timeMin == currentMinutes && !isDone && !isSkip && id.isNotEmpty) {
        final String announceKey = '${datePrefix}_${id}_$timeMin';
        if (!_announcedScheduleKeys.contains(announceKey)) {
          _announcedScheduleKeys.add(announceKey);
          setState(() {
            _activityId = id;
            _activityTitle = title;
            final int h = timeMin ~/ 60;
            final int m = timeMin % 60;
            _timeLabel = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
            _speechText = 'Waktunya $title!';
          });
          _plog('speech=schedule title="$title"');
          // Auto-reopen: overlay mungkin ditutup ke X — pasang dulu view-nya
          // (channel antri berurutan, jadi resize di trigger jalan sesudahnya).
          unawaited(FlutterOverlayWindow.ensureOverlayVisible());
          _triggerSpeechLabel();
          break;
        }
      }
    }
  }

  Future<void> _triggerSpeechLabel() async {
    if (_isExpanded || _speechText.isEmpty || _isNearDismiss) return;
    final int gen = ++_speechGen;
    _plog('speech=trigger gen=$gen text="$_speechText"');
    // Getar mantap: sensasi fisik nyata saat speech bubble muncul.
    unawaited(HapticFeedback.heavyImpact());
    _speechTimer?.cancel();
    _idleTimer?.cancel();
    setState(() {
      _isIdle = false;
      _isSpeechFadingOut = false;
    });
    // Resize overlay wider to fit speech label
    const int speechWidth = 230;
    _plog('resize=230x58 start');
    await FlutterOverlayWindow.resizeOverlay(speechWidth, 58, true);
    if (!mounted || gen != _speechGen) return;
    _plog('resize=230x58 done');
    // Sinkron frame: pastikan layout 230px sudah ter-composite sebelum tampil.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || gen != _speechGen) return;
    setState(() {
      _showSpeechLabel = true;
      _speechEpoch++;
    });
    _plog('speech=show epoch=$_speechEpoch');
    _speechTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted || _isExpanded || gen != _speechGen) return;
      _plog('speech=retract-start');
      _idleTimer?.cancel();

      // FASE 1: Balon menyusut & pudar ke badan icon (icon tetap solid 100%)
      setState(() {
        _isSpeechFadingOut = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 240));
      if (!mounted || _isExpanded || gen != _speechGen) return;

      // Lepas widget balon yang sudah tuntas masuk
      setState(() {
        _showSpeechLabel = false;
        _isSpeechFadingOut = false;
      });
      // Sinkron frame: pastikan hide sudah ke-composite SEBELUM window dipotong.
      // Delay ms tidak bisa jamin ini (jank/GC) -> itulah "gacha"-nya.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _isExpanded || gen != _speechGen) return;

      // FASE 2: Resize native ke 58x58 (konten blank, tak ada yang bisa gepeng)
      _plog('speech=hide resize=58x58 start');
      await FlutterOverlayWindow.resizeOverlay(58, 58, true);
      if (!mounted || _isExpanded || gen != _speechGen) return;
      // Tunggu 1 frame pasca-resize agar surface swap tuntas sebelum tampil
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || gen != _speechGen) return;

      // Balon sudah bersih & window sudah 58x58 -> BARU redupkan icon ke transparan
      _plog('resize=58x58 done icon=idle-on');
      setState(() {
        _isIdle = true;
      });
    });
  }

  void _startAutoMinimizeTimer() {
    _autoMinimizeTimer?.cancel();
    _autoMinimizeTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isExpanded) {
        _collapseOverlay();
      }
    });
  }

  Future<void> _expandOverlay() async {
    _plog('expand=start');
    _idleTimer?.cancel();
    _autoMinimizeTimer?.cancel();
    _speechTimer?.cancel();
    if (_isTransitioning || _isCardClosing) return;
    setState(() {
      _isTransitioning = true;
      _showSpeechLabel = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Fullscreen (-1999): kartu digambar sebagai bottom-sheet responsif
    // (lebar layar-32, tinggi maks layar-32). Bubble 58 tidak tersentuh.
    await FlutterOverlayWindow.resizeOverlay(-1999, -1999, false);
    // Allow native window to settle at screen center and restore alpha
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() {
      _isExpanded = true;
      _isTransitioning = false;
      _isIdle = false;
    });
    _startAutoMinimizeTimer();
  }

  Future<void> _collapseOverlay() async {
    _plog('collapse=start');
    _autoMinimizeTimer?.cancel();
    if (_isTransitioning || _isCardClosing) return;
    // 1. Shrink card smoothly in place at screen center
    setState(() {
      _isCardClosing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (!mounted) return;

    // 2. Set transparent buffer while native window repositions
    setState(() {
      _isTransitioning = true;
      _isCardClosing = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // 3. Move and resize native window back to saved edge coordinates (native hides alpha=0f)
    await FlutterOverlayWindow.resizeOverlay(58, 58, true);

    // 4. Wait for Android WindowManager to complete surface relayout at screen edge
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    // 5. Render bubble directly at screen edge with clean pop-in
    setState(() {
      _isExpanded = false;
      _isTransitioning = false;
    });
    _resetIdleTimer();
  }

  Future<void> _handleOpenActivity() async {
    _autoMinimizeTimer?.cancel();
    if (_activityId.isNotEmpty) {
      // Fire-and-forget: buka app tidak boleh tertahan timeout transport.
      unawaited(_sendAction('open_app_detail'));
      await FlutterOverlayWindow.openApp(_activityId);
    } else {
      await FlutterOverlayWindow.openApp();
    }
    await _collapseOverlay();
  }

  /// Kirim aksi ke app. Balikan true = native teruskan ke main engine.
  /// False/timeout = transport mati -> rollback langsung tanpa tunggu watchdog.
  Future<bool> _sendAction(String type, [Map<String, dynamic>? extras]) async {
    _autoMinimizeTimer?.cancel();
    final Map<String, dynamic> payload = <String, dynamic>{
      'type': type,
      'activityId': _activityId,
      ...?extras,
    };
    try {
      final Object? reply = await FlutterOverlayWindow.shareData(
        jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));
      return reply == true;
    } catch (_) {
      return false;
    }
  }

  /// Watchdog echo: aksi popup optimistis. Bila sync kebenaran dari app
  /// tidak tiba dalam 4 detik (event hilang di transport / app mati),
  /// kembalikan state lokal + tampilkan banner gagal. Mencegah divergensi
  /// permanen popup-selesai vs app-belum.
  void _armEchoWatchdog(VoidCallback rollback) {
    _echoTimer?.cancel();
    _echoTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      rollback();
    });
  }

  void _handleComplete() {
    final bool prevCompleted = _isCompleted;
    final bool prevSkipped = _isSkipped;
    setState(() {
      _isCompleted = true;
      _isSkipped = false;
      _statusBanner = 'Hebat! Aktivitas selesai';
    });
    void rollback() {
      if (!mounted) return;
      setState(() {
        _isCompleted = prevCompleted;
        _isSkipped = prevSkipped;
        _statusBanner = 'Gagal tersimpan, coba lagi';
      });
    }

    _sendAction('action_complete').then((bool ok) {
      if (!mounted) return;
      if (!ok) {
        rollback();
      } else {
        _armEchoWatchdog(rollback);
      }
    });
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _collapseOverlay();
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusBanner = null);
    });
  }

  void _handleSkip() {
    final bool prevCompleted = _isCompleted;
    final bool prevSkipped = _isSkipped;
    setState(() {
      _isSkipped = true;
      _isCompleted = false;
      _statusBanner = 'Aktivitas dilewati hari ini';
    });
    void rollback() {
      if (!mounted) return;
      setState(() {
        _isCompleted = prevCompleted;
        _isSkipped = prevSkipped;
        _statusBanner = 'Gagal tersimpan, coba lagi';
      });
    }

    _sendAction('action_skip').then((bool ok) {
      if (!mounted) return;
      if (!ok) {
        rollback();
      } else {
        _armEchoWatchdog(rollback);
      }
    });
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _collapseOverlay();
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusBanner = null);
    });
  }

  void _handleReopen() {
    final bool wasCompleted = _isCompleted;
    final bool prevSkipped = _isSkipped;
    setState(() {
      _isCompleted = false;
      _isSkipped = false;
      _statusBanner =
          wasCompleted ? 'Selesai dibatalkan' : 'Lewati dibatalkan';
    });
    void rollback() {
      if (!mounted) return;
      setState(() {
        _isCompleted = wasCompleted;
        _isSkipped = prevSkipped;
        _statusBanner = 'Gagal tersimpan, coba lagi';
      });
    }

    _sendAction('action_reopen').then((bool ok) {
      if (!mounted) return;
      if (!ok) {
        rollback();
      } else {
        _armEchoWatchdog(rollback);
      }
    });
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _collapseOverlay();
    });
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusBanner = null);
    });
  }

  void _toggleSubActivity(String sub) {
    _startAutoMinimizeTimer();
    final bool nextCompleted = !_completedSubActivities.contains(sub);
    final Set<String> prevSubs = Set<String>.from(_completedSubActivities);
    setState(() {
      if (nextCompleted) {
        _completedSubActivities.add(sub);
      } else {
        _completedSubActivities.remove(sub);
      }
    });
    void rollback() {
      if (!mounted) return;
      setState(() {
        _completedSubActivities
          ..clear()
          ..addAll(prevSubs);
        _statusBanner = 'Gagal tersimpan, coba lagi';
      });
    }

    _sendAction('toggle_sub_activity', <String, dynamic>{
      'subActivity': sub,
      'completed': nextCompleted,
    }).then((bool ok) {
      if (!mounted) return;
      if (!ok) {
        rollback();
      } else {
        _armEchoWatchdog(rollback);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B7BD6),
        brightness: Brightness.light,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isTransitioning
            ? const SizedBox.shrink()
            : (_isExpanded
                ? Center(child: _buildExpandedCard())
                : _buildCollapsedWithSpeech()),
      ),
    );
  }

  Widget _buildCollapsedWithSpeech() {
    // Bubble di-pin absolut ke tepi via Stack: posisi bubble TIDAK PERNAH
    // bergantung pada reflow Row saat speech retract (widthFactor mengecil).
    // Speech mengisi sisa ruang dan menyusut tanpa menggeser bubble.
    final Widget bubble = _buildCollapsedBubble();
    final bool isRight = _bubbleSide == 'right';
    final Widget speechSlot =
        (!_showSpeechLabel || _speechText.isEmpty)
            ? const SizedBox.shrink()
            : _buildSpeechLabel(isRight);

    return Stack(
      children: [
        // Speech mengisi ruang di sisi icon, anchored tepat di bibir icon
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
              right: isRight ? 56 : 0, // ruang untuk bubble di kanan
              left: isRight ? 0 : 56, // ruang untuk bubble di kiri
            ),
            child: Align(
              alignment:
                  isRight ? Alignment.centerRight : Alignment.centerLeft,
              child: speechSlot,
            ),
          ),
        ),
        // Bubble 58dp pas memenuhi window native 58x58: tanpa padding
        // luar agar artwork tidak terpotong.
        Align(
          alignment:
              isRight ? Alignment.centerRight : Alignment.centerLeft,
          child: bubble,
        ),
      ],
    );
  }

  Widget _buildSpeechLabel(bool isRight) {
    final Alignment exitAnchor =
        isRight ? Alignment.centerRight : Alignment.centerLeft;
    // TANPA Flexible: parent kini Stack (bukan Row). Flexible di bawah
    // Stack = crash ParentDataWidget. Tween mengukur mengikuti Container.
    // SATU controller untuk entrance & exit: scale + fade penuh ber-anchor
    // bibir icon. Tanpa ClipRect -> teks utuh mengecil/membesar, tak teriris.
    // Key berubah tiap trigger & tiap flip fade -> animasi selalu replay.
    final Widget speechLabel = TweenAnimationBuilder<double>(
      key: ValueKey<String>(
          'speech_anim_${_speechEpoch}_${_isSpeechFadingOut ? "out" : "in"}'),
      tween: _isSpeechFadingOut
          ? Tween<double>(begin: 1.0, end: 0.0)
          : Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(
          milliseconds: _isSpeechFadingOut ? 220 : 280),
      curve:
          _isSpeechFadingOut ? Curves.easeInCubic : Curves.easeOutCubic,
      builder: (BuildContext context, double v, Widget? child) {
        final double vc = v.clamp(0.0, 1.0);
        return Opacity(
          opacity: vc,
          child: Transform.scale(
            scale: vc,
            alignment: exitAnchor,
            child: child,
          ),
        );
      },
      child: Container(
            margin: EdgeInsets.only(
              left: isRight ? 0 : 4,
              right: isRight ? 4 : 0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              // Transparan selaras icon idle (~50%), tidak lagi solid 94%.
              // Flat murni: tanpa boxShadow agar tidak ada bayangan.
              color: const Color(0x801E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
            child: Text(
              _speechText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
                decoration: TextDecoration.none,
              ),
            ),
          ),
      );
    return speechLabel;
  }

  Widget _buildCollapsedBubble() {
    // Icon STATIS: tanpa scale bounce. AnimatedOpacity mengatur redup saja.
    // (Scale pop-in 0.75->1.0 tiap remount adalah sumber efek "mental".)
    // Key persisten: identitas bubble tidak pernah remount saat sibling berubah.
    return AnimatedOpacity(
      key: const ValueKey<String>('popup_bubble_root'),
      opacity: _isIdle ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _resetIdleTimer();
          _expandOverlay();
        },
        child: SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Image.asset(
                'assets/branding/bubble/bubble.png',
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
            if (_streak > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      NousenNavIcon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 8,
                      ),
                      Text(
                        '$_streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isCompleted)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B7BD6),
                    shape: BoxShape.circle,
                  ),
                  child: NousenNavIcon(
                    Icons.check,
                    color: Colors.white,
                    size: 9,
                  ),
                ),
              )
            else if (_isSkipped)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B),
                    shape: BoxShape.circle,
                  ),
                  child: NousenNavIcon(
                    Icons.fast_forward,
                    color: Colors.white,
                    size: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildExpandedCard() {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('expanded_card_${_isCardClosing ? "close" : "open"}'),
      tween: _isCardClosing
          ? Tween<double>(begin: 1.0, end: 0.82)
          : Tween<double>(begin: 0.85, end: 1.0),
      duration: Duration(milliseconds: _isCardClosing ? 130 : 200),
      curve: _isCardClosing ? Curves.easeInCubic : Curves.easeOutCubic,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            // Backdrop gelap: tap di luar kartu = tutup (collapse).
            Positioned.fill(
              child: GestureDetector(
                onTap: _collapseOverlay,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
            // Modal tengah layar (jangkauan jari): margin 16 tiap sisi,
            // tinggi maks layar-32. Bubble idle tetap di tepi layar.
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder:
                      (BuildContext context, BoxConstraints constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        maxHeight: constraints.maxHeight - 32,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Header: avatar 40 + title/subtitle + AI + streak + close 36
                            Row(
                              children: <Widget>[
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: <Color>[
                                            Color(0xFF3B7BD6),
                                            Color(0xFF3B7BD6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                      child: Image.asset(
                                        'assets/branding/nousen_mark_192.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      right: -1,
                                      top: -1,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFF3B7BD6),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: const <Widget>[
                                          Text(
                                            'NOUSEN Assist',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF3B7BD6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'Asisten Produktivitas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_streak > 0)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              const Color(0xFFFDBA74)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        NousenNavIcon(
                                          Icons.local_fire_department,
                                          color: Color(0xFFEA580C),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$_streak h',
                                          style: const TextStyle(
                                            color: Color(0xFFEA580C),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: _collapseOverlay,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: NousenNavIcon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Konten tengah scrollable (header + footer tetap)
                            Flexible(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    // Panel pesan Assist (jika ada teks)
                                    if (_speechText.isNotEmpty) ...<Widget>[
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: const Color(
                                                  0xFFDBEAFE)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            NousenNavIcon(
                                              Icons.auto_awesome_rounded,
                                              color: Color(0xFF3B7BD6),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _speechText,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color:
                                                      Color(0xFF334155),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    // Panel info tugas
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(
                                                0xFFF1F5F9)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: <Widget>[
                                                const Text(
                                                  'Tugas Berjalan',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Color(
                                                        0xFF94A3B8),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _activityTitle,
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: Color(
                                                        0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _timeLabel,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: Color(
                                                        0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_activityId.isNotEmpty)
                                            InkWell(
                                              onTap: _handleOpenActivity,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.only(
                                                        left: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFBFDBFE)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    Text(
                                                      'Buka',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                            0xFF3B7BD6),
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                      ),
                                                    ),
                                                    NousenNavIcon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      size: 15,
                                                      color: Color(
                                                          0xFF3B7BD6),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Panel sub-aktivitas
                                    if (_subActivities
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding:
                                            const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: const Color(
                                                  0xFFE2E8F0)),
                                        ),
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                const Text(
                                                  'Ceklis Sub-Aktivitas',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: Color(
                                                        0xFF64748B),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFDBEAFE),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    '${_completedSubActivities.length} / ${_subActivities.length} Selesai',
                                                    style:
                                                        const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(
                                                          0xFF3B7BD6),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Scroll mandiri maks 180dp (~3-4 baris):
                                            // header/pesan/task/footer tetap terlihat.
                                            ConstrainedBox(
                                              constraints:
                                                  const BoxConstraints(
                                                      maxHeight: 180),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount:
                                                    _subActivities.length,
                                              itemBuilder: (BuildContext
                                                      context,
                                                  int index) {
                                                final String sub =
                                                    _subActivities[
                                                        index];
                                                final bool isChecked =
                                                    _completedSubActivities
                                                        .contains(sub);
                                                return GestureDetector(
                                                  onTap: () =>
                                                      _toggleSubActivity(
                                                          sub),
                                                  behavior: HitTestBehavior
                                                      .opaque,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFFE2E8F0)),
                                                    ),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isChecked
                                                                ? const Color(
                                                                    0xFF3B7BD6)
                                                                : Colors
                                                                    .transparent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    6),
                                                            border:
                                                                Border.all(
                                                              color: isChecked
                                                                  ? const Color(
                                                                      0xFF3B7BD6)
                                                                  : const Color(
                                                                      0xFF94A3B8),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: isChecked
                                                              ? NousenNavIcon(
                                                                  Icons.check_rounded,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white,
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            sub,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                TextStyle(
                                                              fontSize:
                                                                  12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: const Color(
                                                                  0xFF1E293B),
                                                              decoration: isChecked
                                                                  ? TextDecoration
                                                                      .lineThrough
                                                                  : null,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Banner status
                                    if (_statusBanner !=
                                        null) ...<Widget>[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _statusBanner!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: const Color(0xFFF1F5F9),
                            ),
                            const SizedBox(height: 8),
                            // Footer: Batal / Lewati+Selesai / Buka
                            if (_activityId.isNotEmpty)
                              if (_isCompleted || _isSkipped)
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      side: const BorderSide(
                                          color: Color(0xFFCBD5E1)),
                                    ),
                                    onPressed: _handleReopen,
                                    icon: NousenNavIcon(
                                      Icons.undo_rounded,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    label: Text(
                                      _isCompleted
                                          ? 'Batal Selesai'
                                          : 'Batal Lewati',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      14),
                                            ),
                                            side: const BorderSide(
                                                color: Color(0xFFCBD5E1)),
                                          ),
                                          onPressed: _handleSkip,
                                          child: const Text(
                                            'Lewati',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF3B7BD6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      14),
                                            ),
                                          ),
                                          onPressed: _handleComplete,
                                          child: const Text(
                                            'Selesai',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF3B7BD6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _handleOpenActivity,
                                  icon: NousenNavIcon(
                                      Icons.open_in_new_rounded,
                                      size: 16),
                                  label: const Text(
                                    'Buka NOUSEN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
