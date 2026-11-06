# Android release checklist

## 1. Create the upload keystore (once, keep it OUT of git)

```
keytool -genkey -v -keystore ~/familyhub-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Back the file and both passwords up somewhere safe. Losing them blocks updates.

## 2. `android/key.properties` (git-ignored)

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/familyhub-upload.jks
```

Without this file `flutter build apk|appbundle --flavor prod --release` fails on purpose
(the debug keystore must never sign production). The dev flavor still falls back to the
debug keystore.

## 3. Real Firebase config

Follow `firebase/README.md` (flutterfire configure, `google-services.json`, restrict the
API key). A prod build with placeholder keys throws `FirebaseNotConfiguredException`.

## 4. Deploy backend

```
npx firebase use prod
npx firebase deploy --only firestore:rules,firestore:indexes
```

## 5. Build

```
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
```

## 6. Smoke test on a real device (airplane mode on/off)

Sign up, create a family, join with a code from a second account, add data offline,
reconnect and confirm it syncs.

## 7. Closed beta and go/no-go

- Distribute privately to named testers only; keep signing material out of Git.
- Verify account deletion, admin transfer, report CSV/PDF sharing, and offline
  queue/sync on physical Android devices.
- Follow `docs/ACCOUNT_LIFECYCLE.md` for the last-admin transfer procedure.
- Verify offline/conflict behavior against `docs/OFFLINE_SYNC.md`.
- Complete the per-screen read measurements in `docs/QUOTA_AUDIT.md` and have
  the project owner verify current Spark quotas in Firebase Console.
- Record a crash-reporting decision only after the owner reviews current
  Firebase options, costs, privacy disclosures, and consent requirements.
- Run a real-family beta for a full month and keep a dated fix list. Do not
  mark Phase 5 complete until the month finishes without developer data fixes.
