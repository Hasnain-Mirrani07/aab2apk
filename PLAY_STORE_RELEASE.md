# Play Store release checklist

Use this checklist to publish **BundleSnap** (`com.applooms.bundlesnap`) to Google Play.

---

## 1. App signing key (first time only)

1. Create an upload keystore (if you don’t have one):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Fill in the real values (passwords, alias, path to `upload-keystore.jks`).
4. **Do not commit** `key.properties` or `*.jks` to git (add them to `.gitignore`).

---

## 2. Build the release app bundle

From the project root:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The output is: `build/app/outputs/bundle/release/app-release.aab`

---

## 3. Google Play Console

1. Go to [Google Play Console](https://play.google.com/console).
2. Create an app (or select existing), name **BundleSnap**.
3. **App content**
   - **Privacy policy**: Add a URL (required if you collect data; your app sends AAB/APK to your server for conversion — add a short policy).
   - **App access**: If the app is usable by everyone, say “All functionality is available without login.”
   - **Ads**: Declare if the app contains ads (this app does not).
4. **Release** → **Production** (or testing track) → **Create new release** → Upload `app-release.aab`.
5. **Store listing**
   - Short description (max 80 chars).
   - Full description.
   - Screenshots (phone at least; follow Play’s size rules).
   - App icon 512×512 (optional; Play can use the one from the app).
6. **Content rating**: Complete the questionnaire (e.g. utility, no sensitive content).
7. **Target audience**: Choose age groups.
8. **Data safety**: Declare what data is collected and how (e.g. “Files you select are sent to our server to convert AAB to APK”).
9. Submit for review.

---

## 4. Permissions (Play policy)

The app uses:

- **INTERNET** – to call the conversion API.
- **READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE** – to pick AAB/APK and save converted APK.
- **MANAGE_EXTERNAL_STORAGE** – only if needed on some devices for Downloads; you may need to justify this in Play Console.
- **REQUEST_INSTALL_PACKAGES** – to open the system installer for the converted APK.

In Play Console, if asked, explain that the app lets users convert AAB to APK and install the resulting APK, so file access and install permission are required.

---

## 5. Application ID (optional but recommended)

The app uses Application ID `com.applooms.bundlesnap` (BundleSnap · Applooms). Changing it again would require:

- Updating `applicationId` in `android/app/build.gradle.kts`.
- Updating `namespace` and package in Kotlin files and `AndroidManifest.xml`.
- Updating the MethodChannel name in `MainActivity.kt` and `lib/services/file_service.dart` if you want it to match.

You can do this before the first upload; changing the ID after publishing creates a new app on Play.

---

## 6. Version updates

For each new release, bump in `pubspec.yaml`:

```yaml
version: 1.0.1+2   # 1.0.1 = versionName, 2 = versionCode (must increase each upload)
```

Then run `flutter build appbundle --release` again and upload the new AAB.

---

## Quick build summary

| Step                    | Command / action                          |
|-------------------------|-------------------------------------------|
| Signing (one-time)      | Create keystore, add `key.properties`     |
| Build release AAB       | `flutter build appbundle --release`      |
| Output file             | `build/app/outputs/bundle/release/app-release.aab` |
| Release uses production | Yes — `useLocalServer` is off in release |
