import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class PopUpAssistBubbleApp extends StatefulWidget {
  const PopUpAssistBubbleApp({super.key});

  @override
  State<PopUpAssistBubbleApp> createState() => _PopUpAssistBubbleAppState();
}

class _PopUpAssistBubbleAppState extends State<PopUpAssistBubbleApp> {
  bool _isExpanded = false;
  bool _isTransitioning = false;
  String _activityId = '';
  String _activityTitle = 'NOUSEN Assist';
  String _timeLabel = 'Siap mendampingi';
  String _speechText = 'Halo! Mau cek jadwal aktivitasmu sekarang?';
  int _streak = 0;
  List<String> _subActivities = <String>[];
  Set<String> _completedSubActivities = <String>{};
  bool _isCompleted = false;
  bool _isSkipped = false;
  String? _statusBanner;

  bool _isIdle = false;
  bool _isNearDismiss = false;
  Timer? _idleTimer;
  Timer? _autoMinimizeTimer;
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();

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
            setState(() {
              _isNearDismiss = isNear;
              if (isNear) {
                _isIdle = false;
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
          });
          return;
        }

        if (data['type'] == 'request_expand') {
          if (!_isExpanded) {
            _expandOverlay();
          }
          return;
        }

        if (data['type'] == 'sync_activity' || data.containsKey('title')) {
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
            if (data['speechText'] != null) {
              _speechText = data['speechText'].toString();
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
    _overlaySubscription?.cancel();
    super.dispose();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isIdle) {
      setState(() => _isIdle = false);
    }
    if (!_isExpanded) {
      _idleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_isExpanded) {
          setState(() => _isIdle = true);
        }
      });
    }
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
    _idleTimer?.cancel();
    _autoMinimizeTimer?.cancel();
    if (_isTransitioning) return;
    setState(() {
      _isTransitioning = true;
    });
    // Let Flutter render 1 transparent frame before native Window resize
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await FlutterOverlayWindow.resizeOverlay(286, 240, false);
    if (!mounted) return;
    setState(() {
      _isExpanded = true;
      _isTransitioning = false;
      _isIdle = false;
    });
    _startAutoMinimizeTimer();
  }

  Future<void> _collapseOverlay() async {
    _autoMinimizeTimer?.cancel();
    if (_isTransitioning) return;
    setState(() {
      _isTransitioning = true;
    });
    // Let Flutter render 1 transparent frame before native Window resize
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await FlutterOverlayWindow.resizeOverlay(58, 58, true);
    if (!mounted) return;
    setState(() {
      _isExpanded = false;
      _isTransitioning = false;
    });
    _resetIdleTimer();
  }

  Future<void> _handleOpenActivity() async {
    _autoMinimizeTimer?.cancel();
    if (_activityId.isNotEmpty) {
      await _sendAction('open_app_detail');
      await FlutterOverlayWindow.openApp(_activityId);
    } else {
      await FlutterOverlayWindow.openApp();
    }
    await _collapseOverlay();
  }

  Future<void> _sendAction(String type, [Map<String, dynamic>? extras]) async {
    _autoMinimizeTimer?.cancel();
    final Map<String, dynamic> payload = <String, dynamic>{
      'type': type,
      'activityId': _activityId,
      ...?extras,
    };
    await FlutterOverlayWindow.shareData(jsonEncode(payload));
  }

  void _handleComplete() {
    setState(() {
      _isCompleted = true;
      _isSkipped = false;
      _statusBanner = 'Hebat! Aktivitas selesai';
    });
    _sendAction('action_complete');
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _collapseOverlay();
    });
  }

  void _handleSkip() {
    setState(() {
      _isSkipped = true;
      _isCompleted = false;
      _statusBanner = 'Aktivitas dilewati hari ini';
    });
    _sendAction('action_skip');
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _collapseOverlay();
    });
  }

  void _handlePostpone() {
    setState(() {
      _statusBanner = 'Pengingat ditunda 10 menit';
    });
    _sendAction('action_postpone', <String, dynamic>{'minutes': 10});
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _collapseOverlay();
    });
  }

  void _toggleSubActivity(String sub) {
    _startAutoMinimizeTimer();
    final bool nextCompleted = !_completedSubActivities.contains(sub);
    setState(() {
      if (nextCompleted) {
        _completedSubActivities.add(sub);
      } else {
        _completedSubActivities.remove(sub);
      }
    });
    _sendAction('toggle_sub_activity', <String, dynamic>{
      'subActivity': sub,
      'completed': nextCompleted,
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A5BAD),
        brightness: Brightness.light,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: _isTransitioning
              ? const SizedBox.shrink()
              : (_isExpanded ? _buildExpandedCard() : _buildCollapsedBubble()),
        ),
      ),
    );
  }

  Widget _buildCollapsedBubble() {
    final double a = _isIdle ? 0.45 : 1.0;
    return TweenAnimationBuilder<double>(
      key: const ValueKey<String>('collapsed_bubble_scale'),
      tween: Tween<double>(begin: 0.88, end: 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _resetIdleTimer();
          _expandOverlay();
        },
        child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isNearDismiss
                ? <Color>[
                    const Color(0xFFEF4444).withValues(alpha: a),
                    const Color(0xFFB91C1C).withValues(alpha: a),
                  ]
                : <Color>[
                    const Color(0xFF2563EB).withValues(alpha: a),
                    const Color(0xFF1D4ED8).withValues(alpha: a),
                  ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: (_isNearDismiss ? const Color(0xFFFCA5A5) : Colors.white)
                .withValues(alpha: a),
            width: 2.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(
              _isNearDismiss ? Icons.delete_outline : Icons.smart_toy_rounded,
              color: Colors.white.withValues(alpha: a),
              size: 26,
            ),
            if (!_isNearDismiss && _streak > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: a),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: a),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.white.withValues(alpha: a),
                        size: 8,
                      ),
                      Text(
                        '$_streak',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: a),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isNearDismiss && _isCompleted)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: a),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white.withValues(alpha: a),
                    size: 9,
                  ),
                ),
              )
            else if (!_isNearDismiss && _isSkipped)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: a),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fast_forward,
                    color: Colors.white.withValues(alpha: a),
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
      key: const ValueKey<String>('expanded_card_scale'),
      tween: Tween<double>(begin: 0.90, end: 1.0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
      width: 276,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E40AF),
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 17,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'NOUSEN Assist',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              if (_streak > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFFEA580C),
                        size: 11,
                      ),
                      const SizedBox(width: 1),
                      Text(
                        '$_streak h',
                        style: const TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _collapseOverlay,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Speech Balloon / Proactive cue
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('💬', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _speechText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Activity Title & Time
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _activityTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _timeLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (_activityId.isNotEmpty)
                InkWell(
                  onTap: _handleOpenActivity,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'Buka',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Mini-checklist (if sub-activities exist)
          if (_subActivities.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 56),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _subActivities.length,
                itemBuilder: (BuildContext context, int index) {
                  final String sub = _subActivities[index];
                  final bool isChecked = _completedSubActivities.contains(sub);
                  return GestureDetector(
                    onTap: () => _toggleSubActivity(sub),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isChecked
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 14,
                            color: isChecked
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isChecked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isChecked
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF334155),
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
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

          // Status banner notification
          if (_statusBanner != null) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusBanner!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Action buttons: Lewati | Tunda 10m | Selesai, or Buka App if empty
          if (_activityId.isNotEmpty)
            Row(
              children: <Widget>[
                // Lewati
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onPressed: _handleSkip,
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                // Tunda 10m
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    onPressed: _handlePostpone,
                    child: const Text(
                      'Tunda 10m',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                // Selesai
                Expanded(
                  flex: 1,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _handleComplete,
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleOpenActivity,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text(
                  'Buka NOUSEN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
