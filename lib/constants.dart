/// API base URL — set to your backend (no trailing slash).
/// Run server: cd server && npm start (it prints your LAN IP).
/// Using your Mac's LAN IP so the emulator can reach the server (10.0.2.2 often fails).
/// If your IP changes, update this or use http://10.0.2.2:3000 for emulator.
const String apiBaseUrl = 'http://192.168.100.4:3000';

/// Set to true only for development (self-signed cert or hostname mismatch).
/// Do not enable in production.
const bool allowInsecureConnections = false;

/// Endpoints (your backend must implement these)
const String analyzeEndpoint = '/analyze';
const String convertEndpoint = '/convert';
