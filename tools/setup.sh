#!/usr/bin/env bash
# One-time setup. Needs Flutter (stable) on PATH and internet access.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Generate native folders without touching our pubspec/lib.
if [ ! -d android ]; then
  flutter create --org com.familyhub --project-name family_hub \
    --platforms android,ios _gen
  cp -r _gen/android _gen/ios .
  rm -rf _gen
fi

# 2. Add packages at CURRENT stable versions (pub resolves them).
flutter pub add flutter_riverpod riverpod_annotation go_router \
  freezed_annotation json_annotation intl shared_preferences timezone \
  flutter_timezone characters
flutter pub add --dev build_runner freezed json_serializable \
  riverpod_generator flutter_lints mocktail

dart format .
flutter analyze
flutter test
echo "Done. Now apply Android flavors: see docs/ANDROID_FLAVORS.md"
