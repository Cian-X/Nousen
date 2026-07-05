import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum PhotoAccessSource { camera, gallery }

class PhotoAccessService {
  Future<bool> ensureAccess({
    required BuildContext context,
    required String localeCode,
    required PhotoAccessSource source,
  }) async {
    final Permission? permission = _permissionForSource(source);
    if (permission == null) {
      return true;
    }

    final PermissionStatus currentStatus = await permission.status;
    if (_isGranted(currentStatus)) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final bool approved = await _showRationaleDialog(
      context: context,
      localeCode: localeCode,
    );
    if (!approved) {
      return false;
    }

    final PermissionStatus requestedStatus = await permission.request();
    return _isGranted(requestedStatus);
  }

  Permission? _permissionForSource(PhotoAccessSource source) {
    if (Platform.isIOS) {
      return source == PhotoAccessSource.camera
          ? Permission.camera
          : Permission.photos;
    }
    if (Platform.isAndroid) {
      return source == PhotoAccessSource.camera ? Permission.camera : null;
    }
    return null;
  }

  bool _isGranted(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  Future<bool> _showRationaleDialog({
    required BuildContext context,
    required String localeCode,
  }) async {
    final bool isId = localeCode == 'id';
    final bool? approved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Text(
            isId
                ? 'Aplikasi membutuhkan akses kamera atau galeri untuk menambahkan foto profil atau mendokumentasikan progres aktivitas.'
                : 'The app needs camera or gallery access to update your profile photo or document activity progress.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isId ? 'Batal' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isId ? 'Izinkan' : 'Allow'),
            ),
          ],
        );
      },
    );
    return approved == true;
  }
}
