import 'dart:html' as html;
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class FileHelper {
  static Future<String> tempDirPath() async {
    return '/tmp';
  }

  static Future<String?> downloadDirPath() async {
    return null;
  }

  static Future<void> ensureDir(String path) async {}

  static Future<String> writeBytes(String path, Uint8List bytes) async {
    return path;
  }

  static Future<void> shareFile(String filePath, String name, {String? text}) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: text,
    );
  }

  static Future<void> shareBytes(Uint8List bytes, String name, {String? text}) async {
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: name, mimeType: 'application/octet-stream')],
      text: text,
    );
  }

  /// 触发浏览器下载文件
  static Future<void> triggerDownload(String name, Uint8List bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
