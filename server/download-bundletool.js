#!/usr/bin/env node
/**
 * Downloads bundletool-all.jar from GitHub releases into server/bundletool/
 * Run from server dir: node download-bundletool.js
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

const BUNDLETOOL_VERSION = '1.18.3';
const DOWNLOAD_URL = `https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar`;
const OUT_DIR = path.join(__dirname, 'bundletool');
const OUT_FILE = path.join(OUT_DIR, 'bundletool-all.jar');

if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

console.log('Downloading bundletool from', DOWNLOAD_URL);
const file = fs.createWriteStream(OUT_FILE);

https.get(DOWNLOAD_URL, { redirect: true }, (res) => {
  if (res.statusCode === 302 || res.statusCode === 301) {
    const redirect = res.headers.location;
    console.log('Following redirect to', redirect);
    https.get(redirect, (res2) => pipeResponse(res2));
    return;
  }
  pipeResponse(res);
}).on('error', (err) => {
  fs.unlink(OUT_FILE, () => {});
  console.error('Download failed:', err.message);
  process.exit(1);
});

function pipeResponse(res) {
  if (res.statusCode !== 200) {
    console.error('Download failed: HTTP', res.statusCode);
    process.exit(1);
  }
  const len = parseInt(res.headers['content-length'], 10);
  let done = 0;
  res.on('data', (chunk) => {
    done += chunk.length;
    if (len && process.stdout.isTTY) {
      process.stdout.write(`\r ${Math.round((done / len) * 100)}%`);
    }
  });
  res.pipe(file);
  file.on('finish', () => {
    file.close();
    console.log('\nSaved to', OUT_FILE);
    console.log('You can now run: npm start');
  });
}
