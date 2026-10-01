import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// The cache key of a [CoverResizeImage].
typedef CoverResizeImageKey = (Object imageKey, int width, int height);

/// Decodes [image] at the smallest size that still covers [width] by [height]
/// physical pixels, keeping its aspect ratio, so that a large image shown
/// with [BoxFit.cover] in a small box is not decoded at its full size.
class const CoverResizeImage(
  final ImageProvider image, {
  required final int width,
  required final int height,
}) extends ImageProvider<CoverResizeImageKey> {
  @override
  Future<CoverResizeImageKey> obtainKey(ImageConfiguration configuration) {
    return image
        .obtainKey(configuration)
        .then((imageKey) => (imageKey, width, height));
  }

  @override
  ImageStreamCompleter loadImage(
    CoverResizeImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeCovering(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      return decode(
        buffer,
        getTargetSize: (intrinsicWidth, intrinsicHeight) {
          final scale = math.min(
            1.0,
            math.max(width / intrinsicWidth, height / intrinsicHeight),
          );
          return ui.TargetImageSize(
            width: (intrinsicWidth * scale).ceil(),
            height: (intrinsicHeight * scale).ceil(),
          );
        },
      );
    }

    return image.loadImage(key.$1, decodeCovering);
  }
}
