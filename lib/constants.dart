/// Set to true to use your computer's server (run: cd server && npm start).
/// Set to false to use the live Render API.
const bool useLocalServer = false;

/// Your computer's IP on the same Wi‑Fi as the emulator/device (run server and check "LAN IP(s)" in the terminal).
/// Ignored when [useLocalServer] is false.
const String localServerHost = '192.168.100.4';

/// API base URL (no trailing slash). Use LAN IP for local — 10.0.2.2 often fails on emulator.
const String apiBaseUrl = useLocalServer
    ? 'http://$localServerHost:3000'
    : 'https://aab2apk.onrender.com';

/// Set to true only for development (self-signed cert or hostname mismatch).
/// Do not enable in production.
const bool allowInsecureConnections = false;

/// Endpoints (your backend must implement these)
const String analyzeEndpoint = '/analyze';
const String convertEndpoint = '/convert';


