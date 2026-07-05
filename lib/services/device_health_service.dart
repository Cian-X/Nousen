import 'package:flutter/services.dart';

class DeviceHealthService {
  static const MethodChannel _channel = MethodChannel(
    'reminder_schedule/device_health',
  );

  Future<bool?> isIgnoringBatteryOptimizations() async {
    try {
      final bool? value = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return value;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> openBatteryOptimizationSettings() async {
    return _invokeOpen('openBatteryOptimizationSettings');
  }

  Future<bool> openAutoStartSettings() async {
    return _invokeOpen('openAutoStartSettings');
  }

  Future<bool> openExactAlarmSettings() async {
    return _invokeOpen('openExactAlarmSettings');
  }

  Future<bool> openNotificationSettings() async {
    return _invokeOpen('openNotificationSettings');
  }

  Future<bool> openAppDetailsSettings() async {
    return _invokeOpen('openAppDetailsSettings');
  }

  Future<bool> _invokeOpen(String method) async {
    try {
      final bool? value = await _channel.invokeMethod<bool>(method);
      return value ?? false;
    } on PlatformException {
      return false;
    }
  }
}
