# Uploading the Family Hub codebase to Claude — Phase 3 (Chores)

Use this instead of `UPLOAD_CODEBASE_TO_CLAUDE.md` while you work on `docs/PHASE3_CHORES_ROADMAP.md`.
The old guide zips almost everything. Phase 3 only touches the chores feature, shared widgets, core helpers, rules and docs, so this guide uploads **only what the step needs** — on your current tree that is about **2.5 MB (458 files) instead of 4.8 MB (653 files)** before zip compression, and far fewer tokens for Claude to read; Delta zips are usually a few hundred KB.

Three ways to upload, from smallest to largest:

| Mode | Command | Use when |
| --- | --- | --- |
| **Delta** | `.\make_p3_zip.ps1 -ChangedSince <git ref>` | Claude already saw the code this session and you changed a few files (Copilot, hand edits, after running a step) |
| **Lean** (default) | `.\make_p3_zip.ps1` | Start of a new Claude session / a new step |
| **Full** | `.\make_p3_zip.ps1 -Profile Full` | Step P3-01 gate, or when Claude must check Bazar code or iOS/Android details |

## 1. What Lean uploads, and what it deliberately leaves out

**Included:** `lib/` (all except the Bazar feature internals), `test/` (except Bazar tests and golden images), `firebase/` (rules, indexes, `rules_test` + `fixtures`, but not `node_modules`), `tools/`, `docs/`, `.github/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `l10n.yaml`, `dart_test.yaml`, `firebase.json`, `.firebaserc`, `.gitignore`, `.gitattributes`, `CLAUDE.md`, `AGENTS.md`, `PROGRESS.md`, `README.md`, the Android manifest and Gradle files, and a generated `UPLOAD_MANIFEST.txt` that tells Claude exactly what is missing.

**Kept from Bazar on purpose** (Phase 3 copies these patterns): `lib/features/bazar/bazar_module.dart`, `bazar_entries.dart`, `lib/features/bazar/settings/` (the template for `settings/chores`), and `test/support/` (the in-memory backend pattern).

**Left out in Lean:** `assets/fonts/` (1.3 MB, not code), `ios/`, the rest of `android/`, `lib/features/bazar/{advances,budgets,contributions,expenses,fund,import,items_categories,presentation,reports}`, `test/features/bazar/`, golden PNGs, the old roadmaps (`ROADMAP.md`, `PHASE1_HARDENING_ROADMAP.md`, `PHASE2_BAZAR_ROADMAP.md`) and the old upload guide — Phase 3 restates everything it needs from them.

**Never uploaded (all modes):** `google-services.json`, `GoogleService-Info.plist`, `key.properties`, `*.jks`, `*.keystore`, `.env*`, service-account JSON, `.git/`, `.dart_tool/`, `build/`, `.idea/`, `.vscode/`, `node_modules/`, `.gradle/`, `Pods/`, `*.log`, `*.apk`, `*.aab`.

## 2. The script

Save as `make_p3_zip.ps1` in the project root (the folder with `pubspec.yaml`) and run it from there. It uses `robocopy` to copy into a temporary folder and Windows' built-in `tar` to zip (forward-slash paths, so the zip opens correctly on Linux).

```powershell
# make_p3_zip.ps1 — run from the project root.
param(
  [ValidateSet('Lean','Full')][string]$Profile = 'Lean',
  [string]$ChangedSince = ''          # e.g. HEAD~1, main, a tag, a commit hash
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path .\pubspec.yaml)) { throw 'Run this from the folder that contains pubspec.yaml' }

$root    = (Get-Location).Path
$stamp   = Get-Date -Format 'yyyyMMdd-HHmm'
$mode    = if ($ChangedSince) { 'delta' } else { $Profile.ToLower() }
$staging = Join-Path $env:TEMP "family_hub_p3_$stamp"
$zip     = Join-Path $root "family_hub_p3_${mode}_$stamp.zip"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null

# Never copied, in any mode.
$excludeDirs  = @('.git','.dart_tool','build','.idea','.vscode','node_modules','.gradle','Pods','coverage','.fvm')
$excludeFiles = @('google-services.json','GoogleService-Info.plist','key.properties','*.jks','*.keystore',
                  '.env','.env.*','*.log','*.apk','*.aab','*.iml','local.properties','service-account*.json')

# Lean profile: folders skipped (relative to the project root).
$leanSkip = @(
  'assets\fonts',
  'ios',
  'lib\features\bazar\advances',
  'lib\features\bazar\budgets',
  'lib\features\bazar\contributions',
  'lib\features\bazar\expenses',
  'lib\features\bazar\fund',
  'lib\features\bazar\import',
  'lib\features\bazar\items_categories',
  'lib\features\bazar\presentation',
  'lib\features\bazar\reports',
  'test\features\bazar'
)
# Lean profile: root markdown files skipped.
$leanSkipRootFiles = @('ROADMAP.md','PHASE1_HARDENING_ROADMAP.md','PHASE2_BAZAR_ROADMAP.md','UPLOAD_CODEBASE_TO_CLAUDE.md')
# Lean profile: the only Android files copied.
$leanAndroidFiles = @('android\app\src\main\AndroidManifest.xml','android\app\build.gradle','android\app\build.gradle.kts',
                      'android\build.gradle','android\build.gradle.kts','android\settings.gradle','android\settings.gradle.kts',
                      'android\gradle.properties')
# Root files always copied when present.
$rootFiles = @('pubspec.yaml','pubspec.lock','analysis_options.yaml','l10n.yaml','dart_test.yaml','firebase.json',
               '.firebaserc','.gitignore','.gitattributes','CLAUDE.md','AGENTS.md','PROGRESS.md','README.md')

function Copy-Tree($rel, $extraSkip) {
  $src = Join-Path $root $rel
  if (-not (Test-Path $src)) { return }
  $xd = @($excludeDirs) + @($extraSkip | ForEach-Object { Join-Path $root $_ })
  robocopy $src (Join-Path $staging $rel) /E /XD $xd /XF $excludeFiles /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $rel (exit $LASTEXITCODE)" }
}

$skipped = @()
if ($ChangedSince) {
  # DELTA: only files changed since the given git ref, plus the always-needed root files.
  $changed  = @(git diff --name-only --diff-filter=ACMR $ChangedSince)
  $changed += @(git ls-files --others --exclude-standard)
  foreach ($f in ($changed | Sort-Object -Unique)) {
    $p = Join-Path $root $f
    if (-not (Test-Path $p -PathType Leaf)) { continue }
    $name = Split-Path $f -Leaf
    if ($excludeFiles | Where-Object { $name -like $_ }) { continue }
    if ($f -match '(^|[\\/])(node_modules|build|\.dart_tool|\.git)[\\/]') { continue }
    $dest = Join-Path $staging $f
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item $p $dest -Force
  }
  foreach ($f in @('CLAUDE.md','PROGRESS.md','pubspec.yaml')) {
    $p = Join-Path $root $f
    if (Test-Path $p) { Copy-Item $p (Join-Path $staging $f) -Force }
  }
} else {
  $folders = @('lib','test','firebase','tools','docs','.github')
  if ($Profile -eq 'Full') { $folders += @('android','assets','integration_test') }
  $extra = if ($Profile -eq 'Lean') { $leanSkip } else { @() }
  foreach ($f in $folders) { Copy-Tree $f $extra }
  foreach ($f in $rootFiles) {
    $p = Join-Path $root $f
    if (Test-Path $p) { Copy-Item $p (Join-Path $staging $f) -Force }
  }
  if ($Profile -eq 'Full') {
    Get-ChildItem $root -Filter *.md -File | ForEach-Object { Copy-Item $_.FullName (Join-Path $staging $_.Name) -Force }
  } else {
    Get-ChildItem $root -Filter *.md -File | Where-Object { $leanSkipRootFiles -notcontains $_.Name } |
      ForEach-Object { Copy-Item $_.FullName (Join-Path $staging $_.Name) -Force }
    foreach ($f in $leanAndroidFiles) {
      $p = Join-Path $root $f
      if (Test-Path $p) {
        $dest = Join-Path $staging $f
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Copy-Item $p $dest -Force
      }
    }
    $skipped = $leanSkip + $leanSkipRootFiles + @('android (everything except manifest + gradle files)')
  }
  # Golden images are never needed by Claude.
  Get-ChildItem $staging -Recurse -Directory -Filter goldens -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force
}

# Safety net: remove any secret that slipped in.
Get-ChildItem $staging -Recurse -Force -File | Where-Object {
  $_.Name -in @('google-services.json','GoogleService-Info.plist','key.properties') -or
  $_.Extension -in @('.jks','.keystore')
} | Remove-Item -Force

# Manifest so Claude knows what it is looking at.
$head = ''; $dirty = ''
try { $head = (git rev-parse --short HEAD) 2>$null; $dirty = (git status --porcelain | Measure-Object).Count } catch {}
@(
  "Family Hub upload manifest",
  "Created : $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
  "Mode    : $mode" + $(if ($ChangedSince) { " (changed since $ChangedSince)" } else { '' }),
  "Git     : HEAD $head, $dirty uncommitted change(s)",
  "Skipped : " + $(if ($skipped.Count) { ($skipped -join ', ') } else { '(nothing beyond the standard excludes)' }),
  "Note    : files not listed here are simply not in this zip; ask me for them instead of guessing."
) | Set-Content -Encoding UTF8 (Join-Path $staging 'UPLOAD_MANIFEST.txt')

if (Test-Path $zip) { Remove-Item $zip -Force }
tar -a -c -f $zip -C $staging .
Remove-Item $staging -Recurse -Force
"{0}  ({1:N2} MB)" -f $zip, ((Get-Item $zip).Length / 1MB)
```

### Quick check before uploading

```powershell
tar -tf .\family_hub_p3_*.zip | Select-Object -First 40
tar -tf .\family_hub_p3_*.zip | Select-String -Pattern 'google-services|key.properties|\.jks|\.keystore|\.env|node_modules'
# The second command must print nothing.
```

## 3. Which mode for which step

| Step(s) | Mode | Why |
| --- | --- | --- |
| P3-01 (gate) | **Full** | The gate runs the whole project and Claude may need to repair Phase 2 code |
| P3-02 … P3-04 | **Lean** | Core helpers, vocabulary and widgets |
| P3-05 … P3-14 | **Lean** (then **Delta** for follow-up fixes) | Engines, data, rules |
| P3-15 … P3-19 | **Lean** | Screens |
| P3-20 … P3-24 | **Lean** | Calendar; goldens are not uploaded, so send a screenshot of any visual problem |
| P3-25 … P3-28 | **Lean** | |
| P3-29, P3-30 | **Lean**, **Full** for the final review | |
| After you ran a step and fixed errors by hand | **Delta** (`-ChangedSince HEAD~1`, or the commit before the step) | Claude sees exactly what changed |

## 4. What to tell Claude with the upload

```text
This is the current Family Hub codebase (PROFILE: lean / delta / full — see UPLOAD_MANIFEST.txt).
Read CLAUDE.md, PROGRESS.md and docs/PHASE3_CHORES_ROADMAP.md (sections 1-3 and the card for the step) first.
The code may have changed outside Claude (Copilot, my edits): inspect the files and verify the steps marked
Done in PROGRESS.md before building on them. If something you need is not in the zip, tell me the exact
path and I will send it; do not guess its contents.
Task: implement P3-xx (or: fix the errors below).
Assume you cannot compile: I will run dart format / flutter gen-l10n / flutter analyze / flutter test
(--exclude-tags golden), the rules suite and node tools/check_indexes.mjs, and paste any errors back.
Return only the files you created or changed, as a zip with the same folder structure, and update
PROGRESS.md (and CLAUDE.md / this guide if they are affected). List files you deleted separately.
```

## 5. Applying the changed-files zip Claude sends back

```powershell
# From the project root. Commit or stash first so `git diff` shows exactly what changed.
git status
tar -xf "$HOME\Downloads\<claude_changes>.zip" -C .
git diff --stat
dart format .
flutter pub get
flutter gen-l10n          # must produce no diff in lib/core/localization/generated/
flutter analyze
flutter test --exclude-tags golden
node tools/check_indexes.mjs
```

If `firebase/firestore.rules` changed, also run the emulator rules suite (CLAUDE.md "Rules extension"). Files Claude deleted are listed in its reply (a zip cannot delete). Paste any failure back with the file name; for a fix round use **Delta** mode.

## 6. Tips

* Commit after every step (`P3-07: Template data layer`); then `-ChangedSince <previous step commit>` always gives a perfect delta.
* Put what you changed outside Claude into `PROGRESS.md` (one line each).
* Large visual problems: send a screenshot instead of a zip (goldens are not uploaded).
* The Bazar spreadsheet and the chores PDF are not code; attach them only if Claude asks (the PDF is already decoded in roadmap Appendix A).
* If Lean misses something Claude needs, run Full once for that step, then go back to Lean.
