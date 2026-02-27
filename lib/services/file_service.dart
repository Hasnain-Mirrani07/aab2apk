import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const MethodChannel _channel = MethodChannel('com.example.aab2apk/open_file');

class FileService {
  /// Request storage permissions (Android 10 and below).
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      final manageExternal = await Permission.manageExternalStorage.request();
      return manageExternal.isGranted;
    }
    return true;
  }

  /// Get the public Downloads directory (or app documents as fallback).
  Future<Directory> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Try common public Downloads paths
      const candidates = ['/storage/emulated/0/Download', '/storage/emulated/0/Downloads'];
      for (final p in candidates) {
        final dir = Directory(p);
        if (await dir.exists()) return dir;
      }
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final download = Directory('${external.path}${Platform.pathSeparator}..${Platform.pathSeparator}Download');
        if (await download.exists()) return download;
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  /// Save [bytes] as [fileName] in Downloads and return the file path.
  Future<String> saveToDownloads(List<int> bytes, String fileName) async {
    final dir = await getDownloadsDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Open the file (e.g. APK) with system handler (install on Android).
  Future<bool> openFile(String path) async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('openFile', path);
        return result == true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
