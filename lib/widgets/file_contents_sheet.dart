import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../theme/app_theme.dart';

class FileContentsSheet extends StatelessWidget {
  const FileContentsSheet({super.key, this.analysis});

  final AnalysisResponse? analysis;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final folders = analysis?.folderSizes ?? {};
    final topFiles = analysis?.topLargestFiles ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.onSurface.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Largest folders (assets, res, lib)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
              const SizedBox(height: 12),
              if (folders.isEmpty)
                const Text('No folder data', style: TextStyle(color: AppTheme.onSurface))
              else
                ...folders.entries.map((e) => ListTile(
                      title: Text(e.key, style: const TextStyle(color: AppTheme.onSurface)),
                      trailing: Text(_formatBytes(e.value), style: const TextStyle(color: AppTheme.electricBlue)),
                    )),
              const SizedBox(height: 24),
              const Text('Largest files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
              const SizedBox(height: 12),
              if (topFiles.isEmpty)
                const Text('No file list', style: TextStyle(color: AppTheme.onSurface))
              else
                ...topFiles.take(15).map((e) => ListTile(
                      title: Text(e.path, style: const TextStyle(color: AppTheme.onSurface, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text(_formatBytes(e.sizeBytes), style: const TextStyle(color: AppTheme.electricBlue, fontSize: 12)),
                    )),
            ],
          ),
        );
      },
    );
  }
}
