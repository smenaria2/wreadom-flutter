import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveCertificateBytes(Uint8List bytes, String filename) async {
  final safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  final directories = <Directory?>[
    await getDownloadsDirectory(),
    await getExternalStorageDirectory(),
    await getApplicationDocumentsDirectory(),
    await getTemporaryDirectory(),
  ];

  for (final directory in directories.whereType<Directory>()) {
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('${directory.path}${Platform.pathSeparator}$safeName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      continue;
    }
  }

  return null;
}
