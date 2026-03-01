# Deploy AAB2APK API to a live server

The API needs **Node.js**, **Java** (for bundletool), and the **bundletool JAR**. The easiest way is to use the included **Docker** image, which has everything.

---

## Best for low traffic (50–100 users/day, cheap/free)

| Platform    | Cost              | Best for                          |
|------------|-------------------|-----------------------------------|
| **Render** | **Free tier**     | First project, zero cost. Service sleeps after ~15 min idle; first request after that may take 30–60 s (cold start). |
| **Fly.io** | Free tier         | Always on, no sleep. Free allowance may be enough for &lt;100 req/day. |
| **Railway**| ~\$5 free credit, then pay | Easiest UX; good if you’re okay with a few \$/month after trial. |
| **Oracle Cloud** | Always-free VPS | \$0 forever, always on. More setup (SSH, Docker, firewall). |

**Recommendation for your case:** Start with **Render (free)**. Connect GitHub → set root to `server` → deploy. If cold starts bother you, switch to **Fly.io** free tier or a small paid instance later.

---

## Option 1: Railway (simple, paid after free credit)

1. Sign up at [railway.app](https://railway.app).
2. **New Project** → **Deploy from GitHub** (connect your repo) or **Empty Project** and deploy from CLI.
3. If using GitHub: select this repo, set **Root Directory** to `server`. Railway will detect the Dockerfile.
4. If no Dockerfile detection: add **Dockerfile** and set **Dockerfile path** to `server/Dockerfile`, **Build context** to `server` (or repo root if Dockerfile is in server and context is server).
5. Deploy. Railway assigns a URL like `https://your-app.up.railway.app`.
6. In your Flutter app’s `lib/constants.dart` set:
   ```dart
   const String apiBaseUrl = 'https://your-app.up.railway.app';
   ```
7. (Optional) Add a custom domain in Railway dashboard.

**CLI alternative:**
```bash
cd server
railway init
railway up
railway domain   # get your public URL
```

---

## Option 2: Render

1. Sign up at [render.com](https://render.com).
2. **New** → **Web Service**. Connect your repo.
3. Set **Root Directory** to `server`.
4. **Environment**: Docker (Render will use the Dockerfile in `server/`).
5. **Instance type**: Free or paid (free tier may spin down after inactivity).
6. Deploy. You get a URL like `https://your-app.onrender.com`.
7. In `lib/constants.dart`:
   ```dart
   const String apiBaseUrl = 'https://your-app.onrender.com';
   ```

---

## Option 3: Fly.io

1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/).
2. From the **project root** (parent of `server`):
   ```bash
   cd server
   fly launch --no-deploy
   ```
   When asked for Dockerfile path, use `./Dockerfile` (or ensure Dockerfile is in `server/`).
3. Edit `fly.toml` if needed (e.g. set `internal_port = 3000`, `protocol = "tcp"` for `[[services.ports]]`).
4. Deploy:
   ```bash
   fly deploy
   fly status
   ```
5. Your URL: `https://your-app-name.fly.dev`. Set that in `lib/constants.dart`.

---

## Option 4: VPS (DigitalOcean, Linode, AWS EC2, etc.)

On a Linux VPS with Docker installed:

```bash
# On the VPS: clone or copy the project, then:
cd server
docker build -t aab2apk-api .
docker run -d -p 3000:3000 --restart unless-stopped --name aab2apk aab2apk-api
```

- API: `http://YOUR_SERVER_IP:3000`
- For HTTPS: put Nginx (or Caddy) in front and add SSL (e.g. Let’s Encrypt).

In `lib/constants.dart`:
```dart
const String apiBaseUrl = 'https://your-domain.com';  // or http://YOUR_SERVER_IP:3000
```

---

## Environment variables (optional)

| Variable        | Description                          |
|----------------|--------------------------------------|
| `PORT`         | Port to listen on (default 3000).   |
| `KEYSTORE_PATH` | Path to keystore for signing APKs.  |
| `KEYSTORE_PASS` | Keystore password.                  |
| `KEY_ALIAS`    | Key alias.                           |
| `KEY_PASS`     | Key password.                        |

The server can auto-create a debug keystore if none is provided (fine for dev; for production you may want your own keystore).

---

## After deployment

1. Test the API: open `https://your-deployed-url/health` in a browser. You should see `{"ok":true,"bundletool":true}`.
2. In the Flutter app, set `apiBaseUrl` in `lib/constants.dart` to your **public** URL (no trailing slash).
3. If the server uses **HTTPS** with a valid certificate, leave `allowInsecureConnections = false`. For self-signed certs (not recommended in production), you’d set it to `true` only for testing.
