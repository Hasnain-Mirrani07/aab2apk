import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../theme/app_theme.dart';

class SizeBreakdownChart extends StatelessWidget {
  const SizeBreakdownChart({super.key, this.breakdown});

  final SizeBreakdown? breakdown;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (breakdown == null || breakdown!.total == 0) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No size data', style: TextStyle(color: AppTheme.onSurface)),
      );
    }

    final b = breakdown!;
    final sections = <PieChartSectionData>[];
    final colors = [
      AppTheme.electricBlue,
      const Color(0xFF3DDC84),
      const Color(0xFFFFB74D),
      const Color(0xFFAB47BC),
      AppTheme.onSurface,
    ];
    final labels = ['DEX', 'Resources', 'Assets', 'Native Libs', 'Other'];
    final values = [b.dexBytes, b.resourcesBytes, b.assetsBytes, b.nativeLibsBytes, b.otherBytes];

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      sections.add(
        PieChartSectionData(
          value: values[i].toDouble(),
          color: colors[i],
          title: '',
          radius: 48,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < values.length; i++)
              if (values[i] > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${labels[i]}: ${_formatBytes(values[i])}',
                      style: const TextStyle(color: AppTheme.onSurface, fontSize: 12),
                    ),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}
