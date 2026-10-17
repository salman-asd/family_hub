# Family Hub

Bangla-first household app: bazar / family finance + family chores.
Flutter, Riverpod, Firebase (Spark plan). See `CLAUDE.md` for architecture rules.

## First-time setup
```bash
./tools/setup.sh          # creates android/ios, adds packages, formats, analyzes, tests
# then follow docs/ANDROID_FLAVORS.md
```

## Commands
| Task | Command |
| --- | --- |
| Run dev | `flutter run --flavor dev -t lib/main_dev.dart` |
| Run dev (with emulators) | `flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true` |
| Run prod | `flutter run --flavor prod -t lib/main_prod.dart` |
| Code generation | `dart run build_runner build --delete-conflicting-outputs` |
| Tests | `flutter test` |
| Format / analyze | `dart format .` and `flutter analyze` |
| Build APK (dev) | `flutter build apk --flavor dev -t lib/main_dev.dart` |
| Build APK (prod) | `flutter build apk --flavor prod -t lib/main_prod.dart` |

## Firebase Emulators

The app is pre-configured with local Firebase Emulators for Auth (port `9099`), Firestore (port `8080`), and the Emulator UI (port `4000`).

### 1. Start the emulators
Ensure Java is available on your PATH (or `JAVA_HOME` set to JDK/JBR), then run:
```bash
firebase emulators:start
```
Or start only Auth and Firestore:
```bash
firebase emulators:start --only auth,firestore
```

### 2. Run the app against the emulators
Pass `--dart-define=USE_EMULATOR=true` to route all Auth and Firestore calls to the local emulator:
```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_EMULATOR=true
```
- On an **Android emulator**, the app automatically connects to `10.0.2.2`.
- On **Desktop/iOS/Web**, the app connects to `127.0.0.1`.
- View documents and test auth users in the Emulator UI at [http://localhost:4000](http://localhost:4000).
