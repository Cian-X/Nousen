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

  Timer? _autoMinimizeTimer;
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    // Normalize window size to exact DPI scaled bounds immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterOverlayWindow.resizeOverlay(76, 76, true);
    });

    _overlaySubscription =
        FlutterOverlayWindow.overlayListener.listen((dynamic event) {
      if (event == null) return;
      try {
        final Map<String, dynamic> data = event is String
            ? jsonDecode(event) as Map<String, dynamic>
            : Map<String, dynamic>.from(event as Map);

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
    _autoMinimizeTimer?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
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
    setState(() => _isExpanded = true);
    await FlutterOverlayWindow.resizeOverlay(330, 290, false);
    _startAutoMinimizeTimer();
  }

  Future<void> _collapseOverlay() async {
    _autoMinimizeTimer?.cancel();
    setState(() => _isExpanded = false);
    await FlutterOverlayWindow.resizeOverlay(76, 76, true);
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
          child: _isExpanded ? _buildExpandedCard() : _buildCollapsedBubble(),
        ),
      ),
    );
  }

  Widget _buildCollapsedBubble() {
    return GestureDetector(
      onTap: _expandOverlay,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 34,
            ),
            if (_streak > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 9,
                      ),
                      Text(
                        '$_streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isCompleted)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              )
            else if (_isSkipped)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF64748B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fast_forward,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E40AF),
          width: 1.8,
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
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NOUSEN Assist',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              if (_streak > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$_streak hari',
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
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Speech Balloon / Proactive cue
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('💬', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _speechText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _sendAction('open_app_detail');
                  _collapseOverlay();
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Buka',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
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
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 72),
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
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isChecked
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isChecked
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
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
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 12),

          // Action buttons: Lewati | Tunda 10m | Selesai
          Row(
            children: <Widget>[
              // Lewati
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  onPressed: _handleSkip,
                  child: const Text(
                    'Lewati',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Tunda 10m
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                  onPressed: _handlePostpone,
                  child: const Text(
                    'Tunda 10m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Selesai
              Expanded(
                flex: 1,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _handleComplete,
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
