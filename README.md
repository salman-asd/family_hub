# Family Hub

Bangla-first household app: bazar / family finance + family chores.
Flutter, Riverpod, Firebase (Spark plan). Architecture rules: `CLAUDE.md`.
Build plan: `ROADMAP.md`; Phase 1 hardening plan: `PHASE1_HARDENING_ROADMAP.md`; status: `PROGRESS.md`.

## Prerequisites
| Tool | Version |
| --- | --- |
| Flutter / Dart | Flutter 3.47.7 (Dart 3.13.x) - the version CI uses (`FLUTTER_VERSION` in `.github/workflows/ci.yml`) |
| JDK for Android builds | 17 |
| JDK for the Firestore emulator | 21 or newer |
| Node (rules tests, index check) | 24 |
| Firebase CLI | `npm i -g firebase-tools` |

## Commands
| Task | Command |
| --- | --- |
| Install packages | `flutter pub get` |
| Run dev | `flutter run --flavor dev -t lib/main_dev.dart` |
| Run dev against emulators | `flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true` |
| Run prod | `flutter run --flavor prod -t lib/main_prod.dart` |
| Unit + widget tests (no goldens) | `flutter test --exclude-tags golden` |
| Format / analyze | `dart format .` and `flutter analyze` |
| Rules tests | `npm ci --prefix firebase/rules_test && npm run test:emulator --prefix firebase/rules_test` |
| Index file check | `node tools/check_indexes.mjs` |
| Build APK (dev) | `flutter build apk --flavor dev -t lib/main_dev.dart` |
| Build APK (prod, release) | `flutter build apk --release --flavor prod -t lib/main_prod.dart` (needs `android/key.properties`, see `docs/RELEASE.md`) |

There is no code generation step: models are hand-written immutable classes and
localizations are checked in (`flutter gen-l10n` regenerates them after an ARB change).

## Golden (image) tests
Goldens are **only** generated on Linux, by the `Update goldens` GitHub workflow
(Actions -> Update goldens -> Run workflow). Download the `linux-goldens` artifact, unzip it
at the repo root and commit the PNGs. Never commit goldens rendered on Windows or macOS.
Locally, skip them: `flutter test --exclude-tags golden`.

## Firebase
Two projects: `familyhub-dev` and `familyhub-prod` (aliases in `.firebaserc`).
First-time wiring (`flutterfire configure`, `google-services.json`, deploying rules and
indexes) is in `firebase/README.md`. Until `flutterfire configure` has been run, the
app refuses to start against real Firebase (placeholder guard); it still runs against
the emulators.

### Emulators
Auth (9099), Firestore (8080), UI (4000):
```bash
firebase emulators:start --only auth,firestore
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```
On an Android emulator the app connects to `10.0.2.2`, elsewhere to `127.0.0.1`.
The Emulator UI is at http://localhost:4000.
