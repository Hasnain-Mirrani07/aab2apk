/// API base URL — set to your backend (no trailing slash).
/// For the included Node.js server: run `cd server && npm install && npm start`, then use:
///   Android emulator: http://10.0.2.2:3000
///   Physical device (same Wi‑Fi): http://YOUR_PC_IP:3000
const String apiBaseUrl = 'http://10.0.2.2:3000';

/// Set to true only for development (self-signed cert or hostname mismatch).
/// Do not enable in production.
const bool allowInsecureConnections = false;

/// Endpoints (your backend must implement these)
const String analyzeEndpoint = '/analyze';
const String convertEndpoint = '/convert';
