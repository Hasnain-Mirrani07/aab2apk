/// Response from the /analyze API (bundletool get-size, zipinfo, dump manifest).
class AnalysisResponse {
  const AnalysisResponse({
    this.packageName,
    this.versionName,
    this.versionCode,
    this.minSdkVersion,
    this.signed = false,
    this.minDownloadSizeBytes,
    this.maxInstallSizeBytes,
    this.aabSizeBytes,
    this.estimatedUniversalApkSizeBytes,
    this.sizeBreakdown,
    this.topLargestFiles,
    this.folderSizes,
  });

  final String? packageName;
  final String? versionName;
  final int? versionCode;
  final int? minSdkVersion;
  final bool signed;
  final int? minDownloadSizeBytes;
  final int? maxInstallSizeBytes;
  final int? aabSizeBytes;
  final int? estimatedUniversalApkSizeBytes;
  final SizeBreakdown? sizeBreakdown;
  final List<FileEntry>? topLargestFiles;
  final Map<String, int>? folderSizes;

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      packageName: json['packageName'] as String? ?? json['package_name'] as String?,
      versionName: json['versionName'] as String? ?? json['version_name'] as String?,
      versionCode: json['versionCode'] as int? ?? json['version_code'] as int?,
      minSdkVersion: json['minSdkVersion'] as int? ?? json['min_sdk_version'] as int?,
      signed: json['signed'] as bool? ?? false,
      minDownloadSizeBytes: json['minDownloadSizeBytes'] as int? ?? json['min_download_size_bytes'] as int?,
      maxInstallSizeBytes: json['maxInstallSizeBytes'] as int? ?? json['max_install_size_bytes'] as int?,
      aabSizeBytes: json['aabSizeBytes'] as int? ?? json['aab_size_bytes'] as int?,
      estimatedUniversalApkSizeBytes: json['estimatedUniversalApkSizeBytes'] as int? ?? json['estimated_universal_apk_size_bytes'] as int?,
      sizeBreakdown: json['sizeBreakdown'] != null || json['size_breakdown'] != null
          ? SizeBreakdown.fromJson((json['sizeBreakdown'] ?? json['size_breakdown']) as Map<String, dynamic>)
          : null,
      topLargestFiles: (json['topLargestFiles'] as List<dynamic>? ?? json['top_largest_files'] as List<dynamic>?)
          ?.map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      folderSizes: (json['folderSizes'] as Map<String, dynamic>? ?? json['folder_sizes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

class SizeBreakdown {
  const SizeBreakdown({
    this.dexBytes = 0,
    this.resourcesBytes = 0,
    this.assetsBytes = 0,
    this.nativeLibsBytes = 0,
    this.otherBytes = 0,
  });

  final int dexBytes;
  final int resourcesBytes;
  final int assetsBytes;
  final int nativeLibsBytes;
  final int otherBytes;

  int get total => dexBytes + resourcesBytes + assetsBytes + nativeLibsBytes + otherBytes;

  factory SizeBreakdown.fromJson(Map<String, dynamic> json) {
    return SizeBreakdown(
      dexBytes: (json['dexBytes'] ?? json['dex_bytes'] ?? 0) as int,
      resourcesBytes: (json['resourcesBytes'] ?? json['resources_bytes'] ?? 0) as int,
      assetsBytes: (json['assetsBytes'] ?? json['assets_bytes'] ?? 0) as int,
      nativeLibsBytes: (json['nativeLibsBytes'] ?? json['native_libs_bytes'] ?? 0) as int,
      otherBytes: (json['otherBytes'] ?? json['other_bytes'] ?? 0) as int,
    );
  }
}

class FileEntry {
  const FileEntry({this.path = '', this.sizeBytes = 0});

  final String path;
  final int sizeBytes;

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      path: json['path'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] ?? json['size_bytes'] ?? 0) as int,
    );
  }
}
