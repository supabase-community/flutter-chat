import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_chat/utils/cover_resize_image.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> decodeCovering(
  WidgetTester tester,
  int width,
  int height,
) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final provider = CoverResizeImage(
    MemoryImage(bytes!),
    width: 400,
    height: 400,
  );
  final image = await tester.runAsync(() async {
    final stream = provider.resolve(ImageConfiguration.empty);
    final completer = Completer<ui.Image>();
    stream.addListener(
      ImageStreamListener((info, _) => completer.complete(info.image)),
    );
    return completer.future;
  });
  return image!;
}

void main() {
  testWidgets('wide image', (tester) async {
    final image = await decodeCovering(tester, 4000, 1000);
    expect((image.width, image.height), (1600, 400));
  });
  testWidgets('tall image', (tester) async {
    final image = await decodeCovering(tester, 1000, 3000);
    expect((image.width, image.height), (400, 1200));
  });
  testWidgets('small image is not upscaled', (tester) async {
    final image = await decodeCovering(tester, 100, 50);
    expect((image.width, image.height), (100, 50));
  });
}
