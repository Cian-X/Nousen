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
  String _activityTitle = 'NOUSEN Assist';
  String _timeLabel = 'Siap mendampingi';
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((dynamic event) {
      if (event == null) return;
      try {
        final Map<String, dynamic> data =
            event is String ? jsonDecode(event) : Map<String, dynamic>.from(event as Map);
        setState(() {
          if (data['title'] != null) _activityTitle = data['title'].toString();
          if (data['time'] != null) _timeLabel = data['time'].toString();
          if (data['streak'] != null) _streak = int.tryParse(data['streak'].toString()) ?? 0;
        });
      } catch (_) {}
    });
  }

  Future<void> _expandOverlay() async {
    setState(() => _isExpanded = true);
    await FlutterOverlayWindow.resizeOverlay(320, 230, false);
  }

  Future<void> _collapseOverlay() async {
    setState(() => _isExpanded = false);
    await FlutterOverlayWindow.resizeOverlay(80, 80, true);
  }

  Future<void> _closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
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
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF1A5BAD),
          shape: BoxShape.circle,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 36,
            ),
            if (_streak > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                      Text(
                        '$_streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
      width: 310,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1A5BAD).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5BAD).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF1A5BAD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'NOUSEN Assist',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A5BAD),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: _collapseOverlay,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activityTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _timeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFF1A5BAD)),
                  ),
                  onPressed: _collapseOverlay,
                  child: const Text('Tutup', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5BAD),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await _collapseOverlay();
                    await _closeOverlay();
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('OK', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
