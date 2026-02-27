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
const BUNDLETOOL_JAR = path.join(bundletoolDir, 'bundletool-all.jar');

if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
if (!fs.existsSync(bundletoolDir)) fs.mkdirSync(bundletoolDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => cb(null, `bundle_${Date.now()}_${(file.originalname || 'app').replace(/[^a-zA-Z0-9._-]/g, '_')}`),
});
const upload = multer({ storage, limits: { fileSize: 500 * 1024 * 1024 } }); // 500 MB

app.use(cors());
app.use(express.json());

function runBundletool(args) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(BUNDLETOOL_JAR)) {
      return reject(new Error('bundletool not found. Download bundletool-all.jar to server/bundletool/ (see README).'));
    }
    const proc = spawn('java', ['-jar', BUNDLETOOL_JAR, ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => { stdout += d.toString(); });
    proc.stderr.on('data', (d) => { stderr += d.toString(); });
    proc.on('close', (code) => {
      if (code !== 0) return reject(new Error(stderr || stdout || `bundletool exited ${code}`));
      resolve(stdout);
    });
    proc.on('error', (err) => reject(err));
  });
}

function ensureBundletool() {
  if (!fs.existsSync(BUNDLETOOL_JAR)) {
    throw new Error('bundletool-all.jar not found. Place it in server/bundletool/ (see server/README.md).');
  }
}

// --- POST /analyze ---
app.post('/analyze', upload.single('file'), async (req, res) => {
  const file = req.file;
  if (!file) return res.status(400).json({ error: 'No file uploaded. Use field name "file".' });

  const cleanup = () => {
    try { fs.unlinkSync(file.path); } catch (_) {}
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
      const apksPath = file.path.replace(/\.aab$/i, '.apks');
      await runBundletool(['build-apks', '--bundle=' + file.path, '--output=' + apksPath, '--mode=universal']);
      const sizeOut = await runBundletool(['get-size', 'total', '--apks=' + apksPath]);
      try { fs.unlinkSync(apksPath); } catch (_) {}
      const minMatch = sizeOut.match(/Min size[^:]*:\s*(\d+)/i);
      const maxMatch = sizeOut.match(/Max size[^:]*:\s*(\d+)/i);
      if (minMatch) minDownloadSizeBytes = parseInt(minMatch[1], 10);
      if (maxMatch) maxInstallSizeBytes = parseInt(maxMatch[1], 10);
    } catch (_) {}

    const estimatedUniversalApkSizeBytes = maxInstallSizeBytes || Math.round(aabSizeBytes * 1.1);

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
    res.status(500).json({ error: err.message || String(err) });
  } finally {
    cleanup();
  }
});

// --- POST /convert ---
app.post('/convert', upload.single('file'), async (req, res) => {
  const file = req.file;
  if (!file) return res.status(400).json({ error: 'No file uploaded. Use field name "file".' });

  const cleanup = () => {
    try { fs.unlinkSync(file.path); } catch (_) {}
    try { if (apksPath && fs.existsSync(apksPath)) fs.unlinkSync(apksPath); } catch (_) {}
  };

  let apksPath = null;
  try {
    ensureBundletool();
    apksPath = file.path.replace(/\.aab$/i, '.apks');
    await runBundletool(['build-apks', '--bundle=' + file.path, '--output=' + apksPath, '--mode=universal']);

    const zip = new AdmZip(apksPath);
    const entries = zip.getEntries();
    let apkEntry = entries.find((e) => !e.isDirectory && e.entryName.endsWith('.apk'));
    if (!apkEntry) apkEntry = entries.find((e) => !e.isDirectory);
    if (!apkEntry) {
      cleanup();
      return res.status(500).json({ error: 'No APK found inside generated .apks' });
    }

    const apkBuffer = apkEntry.getData();
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', 'attachment; filename="universal.apk"');
    res.send(apkBuffer);
  } catch (err) {
    res.status(500).json({ error: err.message || String(err) });
  } finally {
    cleanup();
  }
});

app.get('/health', (_, res) => res.json({ ok: true, bundletool: fs.existsSync(BUNDLETOOL_JAR) }));

app.listen(PORT, () => {
  console.log(`AAB2APK server running at http://localhost:${PORT}`);
  if (!fs.existsSync(BUNDLETOOL_JAR)) {
    console.warn('WARN: bundletool-all.jar not found in server/bundletool/. Download it for /convert and full /analyze (see server/README.md).');
  }
});
