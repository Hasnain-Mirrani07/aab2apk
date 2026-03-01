/// API base URL — set to your backend (no trailing slash).
/// Live API: https://aab2apk.onrender.com
/// For local dev: http://10.0.2.2:3000 (emulator) or http://YOUR_LAN_IP:3000 (device).
const String apiBaseUrl = 'https://aab2apk.onrender.com';

/// Set to true only for development (self-signed cert or hostname mismatch).
/// Do not enable in production.
const bool allowInsecureConnections = false;

/// Endpoints (your backend must implement these)
const String analyzeEndpoint = '/analyze';
const String convertEndpoint = '/convert';
