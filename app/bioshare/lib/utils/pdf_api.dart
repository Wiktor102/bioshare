import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PdfApi {
  static Future<File> loadAsset(String path, String filename) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    return _storeFile(path, filename, bytes);
  }

  static Future<File> _storeFile(String url, String filename, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    File file = File("${dir.path}/$filename");
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
