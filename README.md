# BundleLens

A Flutter app to **convert AAB to APK** with a **File Insights** dashboard. Dark theme with electric blue accents.

## Features

- **File picker**: Select `.aab` files via `file_picker`
- **Upload progress**: Dio-based upload with a visible progress bar
- **Analyze**: After selecting a file, calls your `/analyze` API and shows:
  - **Size breakdown**: DEX, Resources, Assets, Native libs (donut chart via `fl_chart`)
  - **App metadata**: Package name, version, min SDK
  - **Before vs After**: AAB size vs estimated Universal APK size
  - **Security**: Signed (green shield) / Unsigned (red)
  - **Top files**: List of largest files in the bundle
  - **View file contents**: Bottom sheet with largest folders (assets, res, lib)
- **Convert**: Uploads to your API, receives the APK, saves to Downloads
- **Install & Share**: method channel (install) and `share_plus` to share the APK
- **Permissions**: Storage and install handled via `permission_handler`

## Setup

1. **API base URL**  
   Edit `lib/constants.dart` and set `apiBaseUrl` to your backend (e.g. `https://your-api.com`).  
   **Hostname / certificate mismatch:** If you see a Dio SSL or hostname error (e.g. self-signed or dev server), set `allowInsecureConnections = true` in `lib/constants.dart` **only for development**; do not use in production.

2. **Included Node.js server**  
   A ready-to-run backend is in the **`server/`** folder. It exposes `POST /analyze` and `POST /convert` using [bundletool](https://developer.android.com/tools/bundletool). See **[server/README.md](server/README.md)** for setup (Node 18+, Java 11+, download `bundletool-all.jar`). Run with `cd server && npm install && npm start`; the app is preconfigured to use `http://10.0.2.2:3000` for the Android emulator.

3. **API endpoints**  
   - `POST /analyze` — multipart file; response: JSON with `packageName`, `versionName`, `minSdkVersion`, `signed`, `sizeBreakdown` (e.g. `dexBytes`, `resourcesBytes`, `assetsBytes`, `nativeLibsBytes`), `minDownloadSizeBytes`, `maxInstallSizeBytes`, `aabSizeBytes`, `estimatedUniversalApkSizeBytes`, `topLargestFiles` (list of `{path, sizeBytes}`), `folderSizes` (map of folder name → size).
   - `POST /convert` — multipart file; response: raw APK bytes.

4. **Run**
   ```bash
   flutter pub get
   flutter run
   ```

## Packages

- `dio` — uploads and progress
- `file_picker` — select .aab
- `path_provider` — save directory
- `permission_handler` — storage/install
- method channel (native) — install APK
- `fl_chart` — size donut chart
- `share_plus` — share APK

## Project structure

- `lib/main.dart` — app entry and theme
- `lib/screens/home_screen.dart` — drop zone, analyze, dashboard, convert
- `lib/screens/result_screen.dart` — success, Install, Share
- `lib/widgets/` — drop zone, insights dashboard, donut chart, progress overlay, file contents sheet
- `lib/services/api_service.dart` — analyze & convert API calls
- `lib/services/file_service.dart` — permissions, save to Downloads, open file
- `lib/models/analysis_response.dart` — analysis API model
- `lib/constants.dart` — API base URL and endpoints
- `lib/theme/app_theme.dart` — dark theme (#121212, electric blue #2979FF)
