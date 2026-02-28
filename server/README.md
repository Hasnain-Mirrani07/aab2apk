# AAB2APK Node.js server

Express API that provides **POST /analyze** and **POST /convert** for the BundleLens Flutter app. Conversion uses Google’s **bundletool** (Java).

## Requirements

- **Node.js** 18+
- **Java** 11+ (for bundletool)
- **keytool** (comes with Java) to auto-generate a debug keystore
- **bundletool**: download the JAR and place it in this folder (see below)

## 1. Install dependencies

```bash
cd server
npm install
```

## 2. Download bundletool (required for /convert)

**Option A – automatic (recommended):**

```bash
cd server
node download-bundletool.js
```

This downloads the latest bundletool JAR into `server/bundletool/bundletool-all.jar`.

**Option B – manual:**

1. Get **bundletool-all.jar** from: https://github.com/google/bundletool/releases  
   (e.g. [bundletool-all-1.18.3.jar](https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar))
2. Create the folder and place the JAR:

```bash
mkdir -p bundletool
# Copy the downloaded file to server/bundletool/bundletool-all.jar
```

Without bundletool, **POST /convert** will fail with a clear error; **POST /analyze** still works (zip-only).

## 3. Run the server

```bash
npm start
```

Server listens on **http://localhost:3000** (or `PORT` env var).

- **GET /health** — Returns `{ ok: true, bundletool: true/false }`.
- **POST /analyze** — Form field `file` (AAB). Returns JSON (packageName, versionName, sizeBreakdown, topLargestFiles, etc.). Works without bundletool (zip-only); with bundletool adds manifest and size estimates.
- **POST /convert** — Form field `file` (AAB). Returns raw universal APK bytes. **Requires bundletool.**

### Signing / keystore (important)

`bundletool build-apks` requires signing. This server will **auto-generate** a debug keystore at:

- `server/keystore/debug.keystore`

Defaults:

- **alias**: `androiddebugkey`
- **passwords**: `android`

Override with environment variables:

- `KEYSTORE_PATH`, `KEYSTORE_PASS`, `KEY_ALIAS`, `KEY_PASS`

## 4. Use from the Flutter app

- **Local:** In `lib/constants.dart` set  
  `apiBaseUrl = 'http://10.0.2.2:3000'` for Android emulator, or  
  `apiBaseUrl = 'http://YOUR_MACHINE_IP:3000'` for a physical device on the same network.
- If you use HTTPS with a self-signed cert or see hostname mismatch, set `allowInsecureConnections = true` in `constants.dart` for development only.

## Deploy (e.g. free tier)

- The server needs **Java** and **Node** and a way to run **bundletool** (JAR on the host or in the image).
- Example: **Docker** image with Node + OpenJDK, copy `bundletool-all.jar` into the image, run `node index.js`.
- Deploy to **Render**, **Railway**, **Fly.io**, or any VPS; set `PORT` and point the Flutter app’s `apiBaseUrl` to your deployed URL.
