# Uploading the Family Hub codebase to Claude

Use this after changing the code with GitHub Copilot or any other tool, so Claude sees your **current** code.

## 1. What to upload

Upload ONE zip with the source only. Claude does not need build output, caches or secrets.

### Include

| Path | Why |
| --- | --- |
| `lib/` (all, including `lib/core/localization/generated/`) | App code. The generated l10n files are edited by hand in this project, so they are needed. |
| `test/` | Unit, widget and contract tests. Goldens (`test/**/goldens/*.png`) are optional. |
| `firebase/` (`firestore.rules`, `firestore.indexes.json`, `rules_test/` including `fixtures/`, `firebase.json`) | Security rules and rules tests. Leave out `rules_test/node_modules`. |
| `android/app/src/` and `android/app/build.gradle*`, `android/build.gradle*`, `android/settings.gradle*`, `android/gradle.properties` | Flavors and manifest. |
| `pubspec.yaml`, `pubspec.lock` | Dependencies and exact versions. |
| `analysis_options.yaml`, `l10n.yaml`, `dart_test.yaml` | Lints and tooling. |
| `tools/` | Helper scripts (for example `check_indexes.mjs`). |
| `docs/` | Decisions, permission matrix, checklists. |
| `.github/` | CI workflows. |
| `CLAUDE.md`, `AGENTS.md`, `PROGRESS.md`, `README.md`, `PHASE1_HARDENING_ROADMAP.md`, `PHASE2_BAZAR_ROADMAP.md`, `ROADMAP.md` (and any other `*.md` in the root) | Project rules and status. Claude reads these first. |
| `.gitignore`, `.gitattributes` | Repo conventions. |

### Never upload (secrets and noise)

- `android/app/google-services.json`, `android/app/src/*/google-services.json`
- `android/key.properties`, `*.jks`, `*.keystore`
- `.env*`, service-account JSON files, anything with passwords or tokens
- `.git/`, `.dart_tool/`, `build/`, `.idea/`, `.vscode/`
- `node_modules/`, `android/.gradle/`, `android/app/build/`
- `ios/Pods/`, `ios/build/`, `*.log`, `firestore-debug.log`, `*.apk`, `*.aab`

`lib/core/firebase/firebase_options_*.dart` contain Firebase web/app keys. They are not secret, but replace them with placeholders if you prefer.

### If the zip is too large

Upload in two parts: (1) `lib/` + `firebase/` + root files, (2) `test/` + `docs/` + the rest.
For a small task you can upload only the files you changed plus `CLAUDE.md`, `pubspec.yaml` and the files they import.

## 2. PowerShell: build the zip

Run from the project root (the folder that contains `pubspec.yaml`).
This uses `robocopy` to copy only what is needed into a temporary folder, then `tar` (built into Windows 10/11) to zip it. `tar` writes forward-slash paths, so the zip opens correctly on Linux, unlike `Compress-Archive` in Windows PowerShell 5.

```powershell
# Run from the project root.
$ErrorActionPreference = 'Stop'
if (-not (Test-Path .\pubspec.yaml)) { throw 'Run this from the folder that contains pubspec.yaml' }

$root    = (Get-Location).Path
$stamp   = Get-Date -Format 'yyyyMMdd-HHmm'
$staging = Join-Path $env:TEMP "family_hub_upload_$stamp"
$zip     = Join-Path $root "family_hub_upload_$stamp.zip"

if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null

# Folders and files that must never be copied.
$excludeDirs  = @('.git','.dart_tool','build','.idea','.vscode','node_modules','.gradle','Pods','coverage','.fvm')
$excludeFiles = @('google-services.json','GoogleService-Info.plist','key.properties','*.jks','*.keystore',
                  '.env','.env.*','*.log','*.apk','*.aab','*.iml','local.properties','service-account*.json')

# Source folders to include.
$folders = @('lib','test','firebase','tools','docs','.github','android','assets','integration_test')
foreach ($f in $folders) {
  $src = Join-Path $root $f
  if (Test-Path $src) {
    robocopy $src (Join-Path $staging $f) /E /XD $excludeDirs /XF $excludeFiles /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $f (exit $LASTEXITCODE)" }
  }
}

# Root files.
$rootFiles = @('pubspec.yaml','pubspec.lock','analysis_options.yaml','l10n.yaml','dart_test.yaml',
               '.gitignore','.gitattributes','CLAUDE.md','PROGRESS.md','README.md','ROADMAP.md',
               'PHASE1_HARDENING_ROADMAP.md','PHASE2_BAZAR_ROADMAP.md','AGENTS.md','firebase.json','.firebaserc')
foreach ($f in $rootFiles) {
  $p = Join-Path $root $f
  if (Test-Path $p) { Copy-Item $p (Join-Path $staging $f) -Force }
}
# Any other markdown in the root (roadmaps, notes).
Get-ChildItem $root -Filter *.md -File | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $staging $_.Name) -Force
}

# Optional: drop golden images to keep the zip small (uncomment).
# Get-ChildItem $staging -Recurse -Directory -Filter goldens | Remove-Item -Recurse -Force

# Safety net: remove any secret that slipped in.
Get-ChildItem $staging -Recurse -Force -File | Where-Object {
  $_.Name -in @('google-services.json','GoogleService-Info.plist','key.properties') -or
  $_.Extension -in @('.jks','.keystore')
} | Remove-Item -Force

if (Test-Path $zip) { Remove-Item $zip -Force }
tar -a -c -f $zip -C $staging .
Remove-Item $staging -Recurse -Force

"{0}  ({1:N1} MB)" -f $zip, ((Get-Item $zip).Length / 1MB)
```

The result is `family_hub_upload_<date>.zip` in the project root.

### Quick check before uploading

```powershell
# List the first entries and confirm no secrets are inside.
tar -tf .\family_hub_upload_*.zip | Select-Object -First 30
tar -tf .\family_hub_upload_*.zip | Select-String -Pattern 'google-services|key.properties|\.jks|\.keystore|\.env'
# The second command must print nothing.
```

## 3. What to tell Claude with the upload

Paste this with the zip:

```text
This is the current Family Hub codebase (changed outside Claude with Copilot/other tools).
Read CLAUDE.md, PROGRESS.md and PHASE2_BAZAR_ROADMAP.md (sections 1-3 and the card for the
step) first. Do not assume the code matches your earlier changes; inspect the files and verify
the steps marked Done in PROGRESS.md before building on them.
Task: <describe the task, e.g. "implement P2-19 to P2-20">.
Assume it is not compiled on your side: I will run dart format / flutter analyze / flutter test.
Give me the changed files only as a zip with the same folder structure, and update
PROGRESS.md, CLAUDE.md and this file when they are affected.
```

## 3b. Phase 2 (Bazar) hints

- Roadmap: `PHASE2_BAZAR_ROADMAP.md` (also `docs/`). Say which step to do, e.g. "implement P2-13".
- In `PROGRESS.md` each step says Done / Written (not run). Steps marked "not run" were written without a Flutter SDK, so run `dart format .`, `flutter gen-l10n`, `flutter analyze`, `flutter test --exclude-tags golden` and the rules suite first and paste any errors back.
- Bazar code: `lib/features/bazar/**`, `lib/shared/widgets/`, `lib/app/gallery/`, tests under `test/features/bazar/` and `test/support/in_memory_bazar_backend.dart`. Include `firebase/rules_test/fixtures` (small JSON) so contract tests can be checked.
- Contract fixtures: when a step adds a mapper, Claude hand-writes the matching `firebase/rules_test/fixtures/*.json` (P2-17: `budget.json`; P2-19: `contribution_request.json`, `contribution_recorded.json`, `contribution_plan.json` are NOT hand-written: run the Dart test once and commit the generated files). Run `flutter test test/contract/rules_fixtures_test.dart` once; if `git diff firebase/rules_test/fixtures` shows a change, keep the generated file.
- The zip may be named after a folder (for example `android.zip`) but must contain the project root (`lib/`, `test/`, `firebase/`, the `*.md` files). Claude lists it before reading.
- `Bazar.xlsx` and the chores PDF are not code; attach them separately only for the import/seed steps (P2-26+).

## 3c. Applying the changed-files zip Claude sends back

Claude returns only the files it created or changed, with the same folder structure.

```powershell
# From the project root. Commit or stash first so `git diff` shows exactly what changed.
git status
tar -xf "$HOME\\Downloads\\<claude_changes>.zip" -C .
git diff --stat
dart format .
flutter pub get
flutter gen-l10n          # must produce no diff in lib/core/localization/generated/
flutter analyze
flutter test --exclude-tags golden
node tools/check_indexes.mjs
```

If a rules file changed, also run the emulator suite (CLAUDE.md "Rules extension"). Generated l10n
files are edited by hand by Claude when it has no SDK: if `flutter gen-l10n` changes them, keep
the generated version and commit it. Paste any failure back to Claude together with the file name.

## 4. Tips

- Upload a fresh zip each session: Claude does not see your disk, and its earlier copy is out of date after you edit elsewhere.
- Put what changed outside Claude into `PROGRESS.md` (one line each); it saves Claude from guessing.
- To get Claude's changes back, ask for "changed files only as a zip, same folder structure", then extract over your project root and review with `git diff`.
- Extract the zip over the project root, then run `flutter pub get` and the checks in section 3c. Files Claude deleted are listed in the reply (a zip cannot delete).
