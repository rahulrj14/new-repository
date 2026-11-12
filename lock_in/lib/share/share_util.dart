import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the RepaintBoundary behind [key] to a PNG and opens the system
/// share sheet. Everything happens on the phone; the app uploads nothing.
/// Returns false if it couldn't make the image.
Future<bool> sharePng(
  GlobalKey key, {
  required double pixelRatio,
  required String name,
}) async {
  try {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
    );
    return true;
  } catch (_) {
    return false;
  }
}
