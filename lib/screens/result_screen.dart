import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/file_service.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.apkPath,
    required this.fileName,
  });

  final String apkPath;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final fileService = FileService();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 80),
              const SizedBox(height: 24),
              Text(
                'Success',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'APK saved to Downloads',
                style: TextStyle(color: AppTheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                fileName,
                style: TextStyle(color: AppTheme.electricBlue, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () async {
                  await fileService.openFile(apkPath);
                },
                icon: const Icon(Icons.install_mobile),
                label: const Text('Install APK'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: AppTheme.electricBlue,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Share.shareXFiles([XFile(apkPath)]);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Convert another'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
