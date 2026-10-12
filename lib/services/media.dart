import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Picks a photo or video and copies it into the app's own storage so it
/// survives the gallery file being moved or deleted.
class PickedMedia {
  final String path;
  final MediaType type;
  const PickedMedia(this.path, this.type);
}

final _picker = ImagePicker();

Future<PickedMedia?> pickMedia({
  required MediaType type,
  required bool fromCamera,
}) async {
  final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
  final XFile? file = type == MediaType.video
      ? await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 3),
        )
      : await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          imageQuality: 85,
        );
  if (file == null) return null;

  // On web there is no app folder; the browser keeps a blob URL instead.
  if (kIsWeb) return PickedMedia(file.path, type);

  final dir = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/media',
  );
  await dir.create(recursive: true);
  final ext = file.name.contains('.')
      ? file.name.split('.').last
      : (type == MediaType.video ? 'mp4' : 'jpg');
  final dest = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
  await File(file.path).copy(dest);
  return PickedMedia(dest, type);
}

void deleteMediaFile(String path) {
  if (kIsWeb) return;
  try {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  } catch (_) {
    // Missing files are fine.
  }
}

bool mediaExists(String path) {
  if (kIsWeb) return true;
  return File(path).existsSync();
}
