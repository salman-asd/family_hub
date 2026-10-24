# Phase 1 evidence

**Status: NOT YET GENERATED.** The author of H13 had no Flutter SDK, no Node and no
Firestore emulator, so no check below has been run and no number is claimed.

On a clean Linux clone (or the CI runner), run:

```bash
bash tools/phase1_evidence.sh
```

The script runs every check below, overwrites this file with PASS/FAIL and counts only, and
appends the coverage summary. Commit the generated file as the evidence.

| Check | Command |
| --- | --- |
| Format | `dart format --output=none --set-exit-if-changed .` |
| Analyze | `flutter analyze` |
| Tests (no golden) + coverage | `flutter test --exclude-tags golden --coverage` |
| Goldens | `flutter test --tags golden` (Linux only; generate first with the *Update goldens* workflow) |
| Indexes | `node tools/check_indexes.mjs && node tools/check_indexes.test.mjs` |
| Rules | `npm run test:emulator --prefix firebase/rules_test` |
| Step TODOs | `grep -rn "TODO(step" lib` must print nothing |
| APK dev | `flutter build apk --flavor dev -t lib/main_dev.dart` |
| APK prod | `flutter build apk --flavor prod -t lib/main_prod.dart --release` (needs `android/key.properties`) |
| Coverage | `dart run tools/coverage_summary.dart` |

Coverage rule: any file under 70% in `lib/core/` or `lib/features/*/domain/` is listed with its
uncovered line count, and its tests are added before the tag.
