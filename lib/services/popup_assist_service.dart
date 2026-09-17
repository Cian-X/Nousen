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
    String title = 'NOUSEN Assist',
    String time = 'Siap mendampingi aktivitasmu',
    int streak = 0,
  }) async {
    final bool granted = await isPermissionGranted();
    if (!granted) {
      final bool? requested = await requestPermission();
      if (requested != true) {
        return;
      }
    }

    await FlutterOverlayWindow.showOverlay(
      height: 80,
      width: 80,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      overlayTitle: 'NOUSEN Assist Aktif',
      overlayContent: 'Ketuk untuk membuka asisten aktivitas',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilitySecret,
    );

    await syncData(title: title, time: time, streak: streak);
  }

  Future<void> syncData({
    required String title,
    required String time,
    int streak = 0,
  }) async {
    try {
      await FlutterOverlayWindow.shareData(
        jsonEncode(<String, dynamic>{
          'title': title,
          'time': time,
          'streak': streak,
        }),
      );
    } catch (_) {}
  }

  Future<void> close() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
