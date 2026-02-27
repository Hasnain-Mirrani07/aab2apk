import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DropZone extends StatelessWidget {
  const DropZone({
    super.key,
    required this.onTap,
    this.fileName,
    this.fileSize,
  });

  final VoidCallback onTap;
  final String? fileName;
  final int? fileSize;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? AppTheme.electricBlue : AppTheme.onSurface.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFile ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
              size: 56,
              color: hasFile ? AppTheme.electricBlue : AppTheme.onSurface,
            ),
            const SizedBox(height: 16),
            Text(
              hasFile ? (fileName ?? '') : 'Tap to select .aab file',
              style: TextStyle(
                fontSize: 16,
                color: hasFile ? AppTheme.electricBlueLight : AppTheme.onSurface,
                fontWeight: hasFile ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (fileSize != null && fileSize! > 0) ...[
              const SizedBox(height: 8),
              Text(
                _formatBytes(fileSize!),
                style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.8), fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
