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
| Run prod | `flutter run --flavor prod -t lib/main_prod.dart` |
| Code generation | `dart run build_runner build --delete-conflicting-outputs` |
| Tests | `flutter test` |
| Format / analyze | `dart format .` and `flutter analyze` |
| Build APK (dev) | `flutter build apk --flavor dev -t lib/main_dev.dart` |
| Build APK (prod) | `flutter build apk --flavor prod -t lib/main_prod.dart` |
