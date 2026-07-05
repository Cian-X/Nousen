import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  ImageStorageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final Uuid _uuid = const Uuid();

  Future<String?> pickAndSaveImage() async {
    return pickAndSaveImageFromGallery();
  }

  Future<String?> pickAndSaveImageFromGallery() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    return _saveSinglePickedFile(selected);
  }

  Future<String?> pickAndSaveImageFromCamera() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    return _saveSinglePickedFile(selected);
  }

  Future<String?> _saveSinglePickedFile(XFile? selected) async {
    if (selected == null) {
      return null;
    }
    final Directory outputDir = await _ensureOutputDirectory();
    return _copyPickedFile(selected, outputDir);
  }

  Future<List<String>> pickAndSaveImages() async {
    return pickAndSaveImagesFromGallery();
  }

  Future<List<String>> pickAndSaveImagesFromGallery() async {
    final List<XFile> selected = await _picker.pickMultiImage(imageQuality: 88);
    if (selected.isEmpty) {
      return <String>[];
    }

    final Directory outputDir = await _ensureOutputDirectory();
    final List<String> outputPaths = <String>[];
    for (final XFile item in selected) {
      final String? saved = await _copyPickedFile(item, outputDir);
      if (saved != null) {
        outputPaths.add(saved);
      }
    }
    return outputPaths;
  }

  Future<Directory> _ensureOutputDirectory() async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory outputDir = Directory(p.join(root.path, 'progress_photos'));
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    return outputDir;
  }

  Future<String?> _copyPickedFile(XFile selected, Directory outputDir) async {
    final String filename =
        '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
    final String outputPath = p.join(outputDir.path, filename);
    final File sourceFile = File(selected.path);
    try {
      final File copied = await sourceFile.copy(outputPath);
      return copied.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteImageAtPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return;
    }

    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
