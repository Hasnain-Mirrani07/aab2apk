#!/usr/bin/env node
/**
 * Quick check that the AAB2APK server is reachable.
 * Run: node check-server.js [baseUrl]
 * Default: http://localhost:3000
 * Example: node check-server.js http://192.168.1.5:3000
 */
const http = require('http');
const base = process.argv[2] || 'http://localhost:3000';
const url = base.replace(/\/$/, '') + '/health';

console.log('Checking', url, '...');
const req = http.get(url, (res) => {
  let body = '';
  res.on('data', (c) => (body += c));
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('OK', res.statusCode, body);
      try {
        const j = JSON.parse(body);
        if (j.bundletool) console.log('bundletool: present');
        else console.log('bundletool: missing (run node download-bundletool.js)');
      } catch (_) {}
    } else console.log('HTTP', res.statusCode, body);
  });
});
req.on('error', (e) => {
  console.error('Connection failed:', e.message);
  console.error('Is the server running? Start with: npm start');
  if (base.includes('10.0.2.2')) console.error('Tip: 10.0.2.2 is for the emulator; run this script on your Mac with localhost or your LAN IP.');
  process.exit(1);
});
req.setTimeout(5000, () => {
  req.destroy();
  console.error('Timeout. Server not responding.');
  process.exit(1);
});
