import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({
    super.key,
    required this.visible,
    this.progress,
    this.message = 'Extracting Universal APK...',
  });

  final bool visible;
  final double? progress;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress != null)
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.surface,
                      color: AppTheme.electricBlue,
                    ),
                  )
                else
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: AppTheme.electricBlue),
                  ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(color: AppTheme.onSurface, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (progress != null && progress! < 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: const TextStyle(color: AppTheme.electricBlue, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
