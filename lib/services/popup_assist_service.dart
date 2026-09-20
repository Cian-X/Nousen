import 'dart:convert';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class PopUpAssistService {
  const PopUpAssistService();

  Future<bool> isPermissionGranted() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  Future<bool?> requestPermission() async {
    return await FlutterOverlayWindow.requestPermission();
  }

  Future<bool> isActive() async {
    return await FlutterOverlayWindow.isActive();
  }

  Future<void> show({
    String activityId = '',
    String title = 'NOUSEN Assist',
    String time = 'Siap mendampingi',
    String? speechText,
    bool isGreeting = false,
    List<Map<String, dynamic>>? todaySchedules,
    int streak = 0,
    List<String> subActivities = const <String>[],
    List<String> completedSubActivities = const <String>[],
    bool isCompleted = false,
    bool isSkipped = false,
  }) async {
    final bool granted = await isPermissionGranted();
    if (!granted) {
      final bool? requested = await requestPermission();
      if (requested != true) {
        return;
      }
    }

    await FlutterOverlayWindow.showOverlay(
      height: 58,
      width: 58,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      overlayTitle: 'NOUSEN Assist',
      overlayContent: 'Ketuk untuk membuka asisten aktivitas',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilitySecret,
    );

    await syncActivity(
      activityId: activityId,
      title: title,
      timeLabel: time,
      speechText: speechText,
      isGreeting: isGreeting,
      todaySchedules: todaySchedules,
      streak: streak,
      subActivities: subActivities,
      completedSubActivities: completedSubActivities,
      isCompleted: isCompleted,
      isSkipped: isSkipped,
    );
  }

  Future<void> syncActivity({
    required String activityId,
    required String title,
    required String timeLabel,
    String? speechText,
    bool isGreeting = false,
    List<Map<String, dynamic>>? todaySchedules,
    int streak = 0,
    List<String> subActivities = const <String>[],
    List<String> completedSubActivities = const <String>[],
    bool isCompleted = false,
    bool isSkipped = false,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'type': 'sync_activity',
        'activityId': activityId,
        'title': title,
        'time': timeLabel,
        'streak': streak,
        'subActivities': subActivities,
        'completedSubActivities': completedSubActivities,
        'isCompleted': isCompleted,
        'isSkipped': isSkipped,
      };
      if (speechText != null && speechText.isNotEmpty) {
        payload['speechText'] = speechText;
      }
      if (isGreeting) {
        payload['isGreeting'] = true;
      }
      if (todaySchedules != null) {
        payload['todaySchedules'] = todaySchedules;
      }
      await FlutterOverlayWindow.shareData(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> close() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
