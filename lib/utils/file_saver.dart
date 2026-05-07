import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileSaver {
  FileSaver._();
  static Future<String?> saveBytes({
    required List<int> bytes,
    required String suggestedName,
    String mimeType = 'application/octet-stream',
  }) async {
    if (bytes.isEmpty) return null;
    final data = Uint8List.fromList(bytes);

    final ext = _extractExtension(suggestedName);

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      var path = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить файл',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ext == null ? null : [ext],
      );
      if (path == null || path.trim().isEmpty) return null;

      path = _ensureExtension(path, ext);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data, flush: true);

      return path;
    }
    Directory? dir;
    if (Platform.isAndroid) {
      try {
        dir = await getExternalStorageDirectory();
      } catch (_) {
        dir = null;
      }
    }
    dir ??= await getApplicationDocumentsDirectory();

    final path = '${dir.path}${Platform.pathSeparator}$suggestedName';
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(data, flush: true);
    try {
      await Share.shareXFiles([
        XFile(path, mimeType: mimeType, name: suggestedName),
      ], subject: suggestedName);
    } catch (_) {}

    return path;
  }

  static String? _extractExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  static String _ensureExtension(String path, String? ext) {
    if (ext == null || ext.isEmpty) return path;
    final lowerPath = path.toLowerCase();
    final suffix = '.$ext';
    if (lowerPath.endsWith(suffix)) return path;
    return '$path$suffix';
  }
}
