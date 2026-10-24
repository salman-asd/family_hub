# firebase/

| File | Purpose |
| --- | --- |
| `firestore.rules` | Security rules (the backend half of every permission) |
| `firestore.indexes.json` | Composite indexes only (>= 2 fields). Checked by `node tools/check_indexes.mjs` |
| `rules_test/` | Emulator tests for the rules |

## Projects

`.firebaserc` defines two aliases: `dev` -> `familyhub-dev`, `prod` -> `familyhub-prod`.

```
npx firebase use dev          # or prod
npx firebase deploy --only firestore:rules,firestore:indexes
```

Deploy to `dev` first, exercise the app, then deploy the same files to `prod`.

## Real Firebase configuration (manual, once per project)

The repo ships placeholder keys in `lib/core/firebase/firebase_options_*.dart` and
placeholder `google-services.json` entries. A non-emulator run with placeholders now
fails at startup with `FirebaseNotConfiguredException`.

1. `dart pub global activate flutterfire_cli`
2. `flutterfire configure --project=familyhub-dev  --android-app-id=com.familyhub.family_hub.dev  --out=lib/core/firebase/firebase_options_dev.dart`
3. `flutterfire configure --project=familyhub-prod --android-app-id=com.familyhub.family_hub      --out=lib/core/firebase/firebase_options_prod.dart`
   (FlutterFire generates a class named `DefaultFirebaseOptions`; rename it to
   `DevFirebaseOptions` / `ProdFirebaseOptions` and keep the `projectId` constant.)
4. Put each project's `google-services.json` in `android/app/src/dev/` and
   `android/app/src/prod/`.
5. Android API keys are not secrets, but restrict them to the app's package name and
   SHA-1 in the Google Cloud console.

## Verify the rules

```
npx firebase emulators:exec --only firestore --project demo-family-hub \
  "npm --prefix firebase/rules_test test"
```
