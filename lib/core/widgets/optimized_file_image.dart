import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

int _resolveCacheDimension(BuildContext context, double logicalDimension) {
  final double devicePixelRatio =
      MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1;
  return math.max(1, (logicalDimension * devicePixelRatio).round());
}

ImageProvider<Object>? buildResizedFileImageProvider(
  BuildContext context, {
  required String? path,
  required double logicalWidth,
  required double logicalHeight,
}) {
  final String normalized = (path ?? '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return ResizeImage(
    FileImage(File(normalized)),
    width: _resolveCacheDimension(context, logicalWidth),
    height: _resolveCacheDimension(context, logicalHeight),
  );
}

class OptimizedFileImage extends StatelessWidget {
  const OptimizedFileImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.logicalCacheWidth,
    this.logicalCacheHeight,
    this.filterQuality = FilterQuality.low,
    this.errorBuilder,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? logicalCacheWidth;
  final double? logicalCacheHeight;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final String normalized = path.trim();
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    final int? cacheWidth = logicalCacheWidth != null
        ? _resolveCacheDimension(context, logicalCacheWidth!)
        : (width != null ? _resolveCacheDimension(context, width!) : null);
    final int? cacheHeight = logicalCacheHeight != null
        ? _resolveCacheDimension(context, logicalCacheHeight!)
        : (height != null ? _resolveCacheDimension(context, height!) : null);

    return Image.file(
      File(normalized),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      errorBuilder: errorBuilder,
    );
  }
}
