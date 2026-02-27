import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../theme/app_theme.dart';
import 'size_breakdown_chart.dart';

class InsightsDashboard extends StatelessWidget {
  const InsightsDashboard({
    super.key,
    required this.analysis,
    this.aabFileSizeBytes,
    required this.onConvert,
    required this.onViewFileContents,
  });

  final AnalysisResponse analysis;
  final int? aabFileSizeBytes;
  final VoidCallback onConvert;
  final VoidCallback onViewFileContents;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final aabSize = analysis.aabSizeBytes ?? aabFileSizeBytes ?? 0;
    final estimatedApk = analysis.estimatedUniversalApkSizeBytes ?? analysis.maxInstallSizeBytes ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('App Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                      const Spacer(),
                      Icon(
                        analysis.signed ? Icons.verified_user : Icons.warning_amber_rounded,
                        color: analysis.signed ? AppTheme.success : AppTheme.error,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Package', value: analysis.packageName ?? '—'),
                  _InfoRow(label: 'Version', value: analysis.versionName ?? '—'),
                  _InfoRow(label: 'Min SDK', value: analysis.minSdkVersion != null ? '${analysis.minSdkVersion}' : '—'),
                  const SizedBox(height: 8),
                  Text(
                    analysis.signed ? 'Signed' : 'Unsigned',
                    style: TextStyle(color: analysis.signed ? AppTheme.success : AppTheme.error, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Size breakdown (donut)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Size breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                  const SizedBox(height: 16),
                  SizeBreakdownChart(breakdown: analysis.sizeBreakdown),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Before vs After
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Before vs After', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('AAB', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.8), fontSize: 12)),
                          Text(_formatBytes(aabSize), style: const TextStyle(color: AppTheme.electricBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                          if (analysis.minDownloadSizeBytes != null)
                            Text('Min: ${_formatBytes(analysis.minDownloadSizeBytes!)}', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.7), fontSize: 11)),
                          if (analysis.maxInstallSizeBytes != null)
                            Text('Max: ${_formatBytes(analysis.maxInstallSizeBytes!)}', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.7), fontSize: 11)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: AppTheme.onSurface),
                      Column(
                        children: [
                          Text('Universal APK', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.8), fontSize: 12)),
                          Text(_formatBytes(estimatedApk), style: const TextStyle(color: AppTheme.electricBlueLight, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top 5 largest files
          if (analysis.topLargestFiles != null && analysis.topLargestFiles!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top files in bundle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                    const SizedBox(height: 12),
                    ...analysis.topLargestFiles!.take(5).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text(e.path, style: const TextStyle(color: AppTheme.onSurface, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Text(_formatBytes(e.sizeBytes), style: const TextStyle(color: AppTheme.electricBlue, fontSize: 12)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: onViewFileContents,
            icon: const Icon(Icons.folder_open, size: 20),
            label: const Text('View file contents'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onConvert,
            icon: const Icon(Icons.transform, size: 20),
            label: const Text('Convert now'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.7), fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.onSurface, fontSize: 14), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
