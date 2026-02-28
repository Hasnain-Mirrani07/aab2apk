const express = require('express');
const cors = require('cors');
const multer = require('multer');
const AdmZip = require('adm-zip');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// Upload to temp dir; field name must match Flutter: 'file'
const uploadDir = path.join(os.tmpdir(), 'aab2apk-uploads');
const bundletoolDir = path.join(__dirname, 'bundletool');
const BUNDLETOOL_JAR = process.env.BUNDLETOOL_JAR || path.join(bundletoolDir, 'bundletool-all.jar');

// bundletool build-apks requires signing. We use a debug keystore by default.
const keystoreDir = path.join(__dirname, 'keystore');
const KEYSTORE_PATH = process.env.KEYSTORE_PATH || path.join(keystoreDir, 'debug.keystore');
const KEYSTORE_PASS = process.env.KEYSTORE_PASS || 'android';
const KEY_ALIAS = process.env.KEY_ALIAS || 'androiddebugkey';
const KEY_PASS = process.env.KEY_PASS || 'android';

if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
if (!fs.existsSync(bundletoolDir)) fs.mkdirSync(bundletoolDir, { recursive: true });
if (!fs.existsSync(keystoreDir)) fs.mkdirSync(keystoreDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => cb(null, `bundle_${Date.now()}_${(file.originalname || 'app').replace(/[^a-zA-Z0-9._-]/g, '_')}`),
});
const upload = multer({ storage, limits: { fileSize: 500 * 1024 * 1024 } }); // 500 MB

app.use(cors());
app.use(express.json());

// Log every request so we can see if the server receives hits from the app/emulator
app.use((req, res, next) => {
  const ts = new Date().toISOString();
  console.log(`[${ts}] INCOMING ${req.method} ${req.url} (from ${req.ip || req.socket?.remoteAddress || 'unknown'})`);
  const onDone = () => {
    console.log(`[${new Date().toISOString()}] OUTGOING ${req.method} ${req.url} -> ${res.statusCode}`);
  };
  res.on('finish', onDone);
  res.on('close', onDone);
  next();
});

function runBundletool(args) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(BUNDLETOOL_JAR)) {
      return reject(new Error(
        'bundletool not found. Run: cd server && node download-bundletool.js (or place bundletool-all.jar in server/bundletool/).'
      ));
    }
    const proc = spawn('java', ['-jar', BUNDLETOOL_JAR, ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => { stdout += d.toString(); });
    proc.stderr.on('data', (d) => { stderr += d.toString(); });
    proc.on('close', (code) => {
      if (code !== 0) {
        const msg = (stderr || stdout || `bundletool exited ${code}`).trim();
        return reject(new Error(msg));
      }
      resolve(stdout);
    });
    proc.on('error', (err) => {
      if (err.code === 'ENOENT') {
        return reject(new Error(
          'Java not found. Install Java 11+ (e.g. OpenJDK) and ensure "java" is in your PATH. See server/README.md.'
        ));
      }
      reject(err);
    });
  });
}

function ensureBundletool() {
  if (!fs.existsSync(BUNDLETOOL_JAR)) {
    throw new Error('bundletool-all.jar not found. Place it in server/bundletool/ (see server/README.md).');
  }
}

function runCmd(cmd, args) {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => { stdout += d.toString(); });
    proc.stderr.on('data', (d) => { stderr += d.toString(); });
    proc.on('close', (code) => {
      if (code !== 0) return reject(new Error(stderr || stdout || `${cmd} exited ${code}`));
      resolve(stdout);
    });
    proc.on('error', (err) => reject(err));
  });
}

async function ensureDebugKeystore() {
  if (fs.existsSync(KEYSTORE_PATH)) return;
  // Generate a debug keystore locally (not secret, for dev only).
  const dname = 'CN=Android Debug,O=Android,C=US';
  await runCmd('keytool', [
    '-genkey',
    '-v',
    '-keystore', KEYSTORE_PATH,
    '-storepass', KEYSTORE_PASS,
    '-alias', KEY_ALIAS,
    '-keypass', KEY_PASS,
    '-dname', dname,
    '-keyalg', 'RSA',
    '-keysize', '2048',
    '-validity', '10000',
  ]);
}

function buildApksArgs(bundlePath, apksOutPath) {
  return [
    'build-apks',
    '--bundle=' + bundlePath,
    '--output=' + apksOutPath,
    '--mode=universal',
    '--ks=' + KEYSTORE_PATH,
    '--ks-pass=pass:' + KEYSTORE_PASS,
    '--ks-key-alias=' + KEY_ALIAS,
    '--key-pass=pass:' + KEY_PASS,
    '--overwrite',
  ];
}

// --- POST /analyze ---
app.post('/analyze', upload.single('file'), async (req, res) => {
  console.log('[POST /analyze] Request received');
  const file = req.file;
  if (!file) {
    console.log('[POST /analyze] Response: 400 - No file uploaded');
    return res.status(400).json({ error: 'No file uploaded. Use field name "file".' });
  }
  console.log('[POST /analyze] File received:', file.originalname, file.size, 'bytes');

  let apksPath = null;
  const cleanup = () => {
    try { fs.unlinkSync(file.path); } catch (_) {}
    try { if (apksPath && fs.existsSync(apksPath)) fs.unlinkSync(apksPath); } catch (_) {}
  };

  try {
    const zip = new AdmZip(file.path);
    const entries = zip.getEntries();
    const aabSizeBytes = fs.statSync(file.path).size;

    const byFolder = {};
    const allFiles = [];
    for (const e of entries) {
      if (e.isDirectory) continue;
      const name = e.entryName;
      const size = e.header.size;
      allFiles.push({ path: name, sizeBytes: size });
      const top = name.split('/')[0] || 'root';
      byFolder[top] = (byFolder[top] || 0) + size;
    }

    const topLargestFiles = allFiles
      .sort((a, b) => b.sizeBytes - a.sizeBytes)
      .slice(0, 15)
      .map(({ path: p, sizeBytes }) => ({ path: p, sizeBytes }));

    const byPath = (re) => allFiles.reduce((s, f) => (re.test(f.path) ? s + f.sizeBytes : s), 0);
    const dexBytes = byPath(/\/dex\//i) || byPath(/\.dex$/i);
    const resourcesBytes = byPath(/\/res\//i);
    const assetsBytes = byPath(/\/assets\//i) || byFolder['assets'] || 0;
    const nativeLibsBytes = byPath(/\/lib\//i) || byPath(/\.so$/i);

    let packageName = null;
    let versionName = null;
    let versionCode = null;
    let minSdkVersion = null;
    let signed = false;

    try {
      ensureBundletool();
      const manifestOut = await runBundletool(['dump', 'manifest', '--bundle=' + file.path]);
      const pkgMatch = manifestOut.match(/package="([^"]+)"/);
      const verNameMatch = manifestOut.match(/android:versionName="([^"]*)"/);
      const verCodeMatch = manifestOut.match(/android:versionCode(?:Internal)?="(\d+)"/);
      const minSdkMatch = manifestOut.match(/android:minSdkVersion="(\d+)"/);
      if (pkgMatch) packageName = pkgMatch[1];
      if (verNameMatch) versionName = verNameMatch[1];
      if (verCodeMatch) versionCode = parseInt(verCodeMatch[1], 10);
      if (minSdkMatch) minSdkVersion = parseInt(minSdkMatch[1], 10);
      signed = manifestOut.includes('android:signing');
    } catch (_) {
      // bundletool missing or failed; keep zip-based response
    }

    const otherBytes = aabSizeBytes - (dexBytes + resourcesBytes + assetsBytes + nativeLibsBytes);

    let minDownloadSizeBytes = null;
    let maxInstallSizeBytes = null;
    try {
      ensureBundletool();
      await ensureDebugKeystore();
      apksPath = `${file.path}.apks`;
      await runBundletool(buildApksArgs(file.path, apksPath));
      const sizeOut = await runBundletool(['get-size', 'total', '--apks=' + apksPath]);
      const minMatch = sizeOut.match(/Min size[^:]*:\s*(\d+)/i);
      const maxMatch = sizeOut.match(/Max size[^:]*:\s*(\d+)/i);
      if (minMatch) minDownloadSizeBytes = parseInt(minMatch[1], 10);
      if (maxMatch) maxInstallSizeBytes = parseInt(maxMatch[1], 10);
    } catch (_) {}

    const estimatedUniversalApkSizeBytes = maxInstallSizeBytes || Math.round(aabSizeBytes * 1.1);

    console.log('[POST /analyze] Response: 200 OK', { packageName, aabSizeBytes });
    res.json({
      packageName,
      versionName,
      versionCode,
      minSdkVersion,
      signed,
      aabSizeBytes,
      minDownloadSizeBytes,
      maxInstallSizeBytes,
      estimatedUniversalApkSizeBytes,
      sizeBreakdown: {
        dexBytes,
        resourcesBytes,
        assetsBytes,
        nativeLibsBytes,
        otherBytes: Math.max(0, otherBytes),
      },
      topLargestFiles,
      folderSizes: byFolder,
    });
  } catch (err) {
    console.log('[POST /analyze] Response: 500 Error:', err.message);
    res.status(500).json({ error: err.message || String(err) });
  } finally {
    cleanup();
  }
});

// --- POST /convert ---
app.post('/convert', upload.single('file'), async (req, res) => {
  console.log('[POST /convert] Request received');
  const file = req.file;
  if (!file) {
    console.log('[POST /convert] Response: 400 - No file uploaded');
    return res.status(400).json({ error: 'No file uploaded. Use field name "file".' });
  }
  console.log('[POST /convert] File received:', file.originalname, file.size, 'bytes');

  const cleanup = () => {
    try { fs.unlinkSync(file.path); } catch (_) {}
    try { if (apksPath && fs.existsSync(apksPath)) fs.unlinkSync(apksPath); } catch (_) {}
  };

  let apksPath = null;
  try {
    ensureBundletool();
    await ensureDebugKeystore();
    apksPath = `${file.path}.apks`;
    await runBundletool(buildApksArgs(file.path, apksPath));

    const zip = new AdmZip(apksPath);
    const entries = zip.getEntries();
    let apkEntry = entries.find((e) => !e.isDirectory && e.entryName.toLowerCase().endsWith('universal.apk'));
    if (!apkEntry) apkEntry = entries.find((e) => !e.isDirectory && e.entryName.endsWith('.apk'));
    if (!apkEntry) apkEntry = entries.find((e) => !e.isDirectory);
    if (!apkEntry) {
      cleanup();
      return res.status(500).json({ error: 'No APK found inside generated .apks' });
    }

    const apkBuffer = apkEntry.getData();
    console.log('[POST /convert] Response: 200 OK, sending APK', apkBuffer.length, 'bytes');
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', 'attachment; filename="universal.apk"');
    res.send(apkBuffer);
  } catch (err) {
    const message = err.message || String(err);
    console.error('[POST /convert]', message);
    res.status(500).json({ error: message });
  } finally {
    cleanup();
  }
});

app.get('/health', (req, res) => {
  console.log('[GET /health] Request received');
  const payload = { ok: true, bundletool: fs.existsSync(BUNDLETOOL_JAR) };
  console.log('[GET /health] Response: 200', JSON.stringify(payload));
  res.json(payload);
});

// Get this machine's LAN IP(s) for physical device / alternate emulator config
function getLanIps() {
  const nets = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(nets)) {
    for (const iface of nets[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) ips.push(iface.address);
    }
  }
  return [...new Set(ips)];
}

// Listen on 0.0.0.0 so Android emulator (10.0.2.2) and other devices on LAN can connect
app.listen(PORT, '0.0.0.0', () => {
  const lanIps = getLanIps();
  console.log(`AAB2APK server running at http://localhost:${PORT}`);
  console.log(`  Emulator:  http://10.0.2.2:${PORT}`);
  if (lanIps.length) console.log(`  LAN IP(s): ${lanIps.map((ip) => `http://${ip}:${PORT}`).join(', ')} (use in app if 10.0.2.2 fails or on physical device)`);
  console.log('');
  console.log('If the app shows "connection timeout" and you see NO "INCOMING" lines here when you tap Analyze:');
  console.log('  1) Physical device? In lib/constants.dart set apiBaseUrl to http://YOUR_LAN_IP:3000 (see LAN IP(s) above).');
  console.log('  2) macOS Firewall? System Settings > Network > Firewall — allow "node" or turn off to test.');
  console.log('  3) Emulator? Try using your LAN IP in constants.dart instead of 10.0.2.2.');
  if (!fs.existsSync(BUNDLETOOL_JAR)) {
    console.warn('WARN: bundletool-all.jar not found in server/bundletool/. Download it for /convert and full /analyze (see server/README.md).');
  }
});
