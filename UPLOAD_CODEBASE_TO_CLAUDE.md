# Uploading the Family Hub codebase to Claude

Use this after changing the code with GitHub Copilot or any other tool, so Claude sees your **current** code.

## 1. What to upload

Upload ONE zip with the source only. Claude does not need build output, caches or secrets.

### Include

| Path | Why |
| --- | --- |
| `lib/` (all, including `lib/core/localization/generated/`) | App code. The generated l10n files are edited by hand in this project, so they are needed. |
| `test/` | Unit, widget and contract tests. Goldens (`test/**/goldens/*.png`) are optional. |
| `firebase/` (`firestore.rules`, `firestore.indexes.json`, `rules_test/`, `firebase.json`) | Security rules and rules tests. Leave out `rules_test/node_modules`. |
| `android/app/src/` and `android/app/build.gradle*`, `android/build.gradle*`, `android/settings.gradle*`, `android/gradle.properties` | Flavors and manifest. |
| `pubspec.yaml`, `pubspec.lock` | Dependencies and exact versions. |
| `analysis_options.yaml`, `l10n.yaml`, `dart_test.yaml` | Lints and tooling. |
| `tools/` | Helper scripts (for example `check_indexes.mjs`). |
| `docs/` | Decisions, permission matrix, checklists. |
| `.github/` | CI workflows. |
| `CLAUDE.md`, `PROGRESS.md`, `README.md`, `PHASE1_HARDENING_ROADMAP.md`, `ROADMAP.md` (and any other `*.md` in the root) | Project rules and status. Claude reads these first. |
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
               'PHASE1_HARDENING_ROADMAP.md','firebase.json','.firebaserc')
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
Read CLAUDE.md and PROGRESS.md first. Do not assume the code matches your earlier
changes; inspect the files. Task: <describe the task>.
Assume it is not compiled on your side: I will run flutter analyze / flutter test.
```

## 4. Tips

- Upload a fresh zip each session: Claude does not see your disk, and its earlier copy is out of date after you edit elsewhere.
- Put what changed outside Claude into `PROGRESS.md` (one line each); it saves Claude from guessing.
- To get Claude's changes back, ask for "changed files only as a zip, same folder structure", then extract over your project root and review with `git diff`.
