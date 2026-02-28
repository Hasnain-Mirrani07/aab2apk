import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/analysis_response.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import '../widgets/drop_zone.dart';
import '../widgets/file_contents_sheet.dart';
import '../widgets/insights_dashboard.dart';
import '../widgets/progress_overlay.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final FileService _fileService = FileService();

  PlatformFile? _pickedFile;
  File? _file;
  AnalysisResponse? _analysis;
  bool _analyzing = false;
  bool _converting = false;
  double _uploadProgress = 0;
  String? _analyzeError;
  String? _convertError;

  String _formatDioError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      // /convert uses responseType: bytes, so 500 error body may be List<int>
      String? serverError;
      if (data is Map && data['error'] is String) {
        serverError = data['error'] as String;
      } else if (data is List<int> && data.isNotEmpty) {
        try {
          final json = String.fromCharCodes(data);
          final decoded = Map<String, dynamic>.from(
            (jsonDecode(json) as Map).cast<String, dynamic>(),
          );
          if (decoded['error'] is String) serverError = decoded['error'] as String;
        } catch (_) {}
      }
      final base = switch (e.type) {
        DioExceptionType.connectionTimeout => 'Connection timed out',
        DioExceptionType.sendTimeout => 'Upload timed out',
        DioExceptionType.receiveTimeout => 'Server response timed out',
        DioExceptionType.badCertificate => 'Bad certificate / hostname mismatch',
        DioExceptionType.connectionError => 'Network connection error',
        DioExceptionType.cancel => 'Request cancelled',
        DioExceptionType.badResponse => 'Server error',
        DioExceptionType.unknown => 'Network error',
      };
      final details = <String>[
        if (status != null) 'HTTP $status',
        if (serverError != null && serverError.isNotEmpty) serverError,
        if (e.message != null && e.message!.isNotEmpty) e.message!,
      ].where((s) => s.trim().isNotEmpty).join(' • ');
      final msg = details.isEmpty ? base : '$base • $details';
      final isUnreachable = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError;
      final hint = isUnreachable
          ? '\n\nMake sure the AAB2APK server is running on your computer: open a terminal, run “cd server && npm start”, and use the same Wi‑Fi for a physical device.'
          : '';
      return msg + hint;
    }
    return e.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }

  Future<void> _pickFile() async {
    final granted = await _fileService.requestStoragePermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is needed to select files')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final platformFile = result.files.single;
    final path = platformFile.path;
    if (path == null || path.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get file path')));
      }
      return;
    }
    final name = platformFile.name.toLowerCase();
    if (!name.endsWith('.aab')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an .aab file')),
        );
      }
      return;
    }

    setState(() {
      _pickedFile = platformFile;
      _file = File(path);
      _analysis = null;
      _analyzeError = null;
      _convertError = null;
    });

    _analyzeFile();
  }

  Future<void> _analyzeFile() async {
    if (_file == null) return;
    setState(() {
      _analyzing = true;
      _analyzeError = null;
    });

    try {
      final analysis = await _api.analyze(_file!);
      if (mounted) {
        setState(() {
          _analysis = analysis;
          _analyzing = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Analyze] error: $e');
      if (mounted) {
        setState(() {
          _analyzeError = _formatDioError(e);
          _analyzing = false;
        });
      }
    }
  }

  Future<void> _convert() async {
    if (_file == null) return;
    setState(() {
      _converting = true;
      _uploadProgress = 0;
      _convertError = null;
    });

    try {
      final bytes = await _api.convert(_file!, onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      });

      final fileName = '${_pickedFile?.name.replaceAll('.aab', '') ?? 'app'}_universal.apk';
      final savedPath = await _fileService.saveToDownloads(bytes, fileName);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ResultScreen(
            apkPath: savedPath,
            fileName: fileName,
          ),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[Convert] error: $e');
      if (mounted) {
        setState(() {
          _convertError = _formatDioError(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversion failed: $_convertError')));
      }
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  void _showFileContents() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FileContentsSheet(analysis: _analysis),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      'Convert AAB to APK',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DropZone(
                      onTap: _pickFile,
                      fileName: _pickedFile?.name,
                      fileSize: _pickedFile?.size,
                    ),
                  ),
                ),
                if (_analyzing)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.electricBlue)),
                    ),
                  ),
                if (_analyzeError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        color: AppTheme.error.withValues(alpha: 0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Analysis failed', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_analyzeError!, style: const TextStyle(color: AppTheme.onSurface, fontSize: 12)),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  setState(() => _analyzeError = null);
                                  _analyzeFile();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_analysis != null && !_analyzing)
                  SliverToBoxAdapter(
                    child: InsightsDashboard(
                      analysis: _analysis!,
                      aabFileSizeBytes: _pickedFile?.size,
                      onConvert: _convert,
                      onViewFileContents: _showFileContents,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
            ProgressOverlay(
              visible: _converting,
              progress: _uploadProgress,
              message: 'Uploading & extracting Universal APK...',
            ),
          ],
        ),
      ),
    );
  }
}
