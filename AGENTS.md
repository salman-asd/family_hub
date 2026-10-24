# AGENTS.md — rules for ANY AI model working on Family Hub

Applies to every tool and model (Claude, ChatGPT, DeepSeek, Copilot, Cursor, Codex ...).
Read this file and `CLAUDE.md` (project facts, hard rules 1-24) before changing anything.
If a request conflicts with these rules, say so and ask; do not silently break a rule.

## 1. Project in one paragraph
Flutter (Android first) + Firebase Auth + Cloud Firestore on the free Spark plan. Bangla is the
default language, English optional. Two modules: Bazar & Family Finance, Family Chores.
Feature-first Clean Architecture: `data/` (Firestore) -> `domain/` (pure Dart) <- `presentation/`
(Riverpod + screens). No Cloud Functions, no code generation (see docs/decisions/0004).

## 2. Before you write code
1. Read the files you will change AND one similar existing file; copy its style, naming and structure.
2. List the files you will create or change. Keep the change small and focused on the request.
3. Do not refactor, rename, reformat or "improve" unrelated code.
4. Do not add a package, a new pattern, or a new folder layout unless the user asked. If you think one is
   needed, propose it first.
5. If the request is ambiguous and a wrong guess is expensive, ask one short question. Otherwise state your
   assumption and continue.
6. Never invent APIs, package versions or Firebase limits. Check the official docs or the repo.

## 3. Architecture (never break)
- `domain/`: pure Dart. No flutter, firebase, riverpod, go_router imports (directly or transitively).
- `presentation/`: never imports `data/` or firebase packages. Flow: screen -> controller -> use case -> repository interface.
- `data/`: implements repository interfaces; maps documents <-> entities through mappers only.
- One class per use case file. Every write is a use case returning `Result<T>` / `AppFailure`.
  Order inside a use case: permission check -> validation -> business rule -> repository write.
- Writes: use `guardWrite`; reads: `guardFirestore`. Audit/activity entries are written in the SAME batch.
- Permissions: one matrix (`PermissionPolicy`). UI uses `PermissionGate`/`canProvider`; never test roles in widgets.
  Every permission is ALSO enforced in `firebase/firestore.rules`.
- Offline: a missing document from cache is UNKNOWN, not absent. Admin/onboarding actions need the server.
- A user belongs to at most one family.

## 4. Data and money
- Money = integer paisa (`Money`). Quantity = integer milli-units. Never `double`.
- Dates: UTC `Timestamp` + `dateKey` (yyyy-MM-dd) + `monthKey` (yyyy-MM) in the family timezone. Use the injected `Clock`.
- Soft delete only (`deletedAt`, `deletedBy`). Every document has createdAt/createdBy/updatedAt/updatedBy/schemaVersion.
- Deterministic ids where defined (occurrences `{templateId}_{yyyyMMdd}`, budgets `{yyyy-MM}`).
- Queries are bounded (monthKey/dateKey range + `limit`). One listener per screen; cancel on dispose.
- New collection or field => update `firestore.rules`, `firestore.indexes.json` (composite = 2+ fields only) and the
  rules tests in the SAME change: one allowed and one denied test per rule.

## 5. UI rules
- Colors and sizes only through `context.tokens` / the theme. No `Color(0x..)`, no `Colors.*` (except transparent) outside `lib/app/theme/`.
- No hard-coded user-visible text: add keys to BOTH `app_bn.arb` and `app_en.arb`, then run `flutter gen-l10n`.
- Every screen handles loading, empty, error and offline states.
- Touch targets >= 48dp; status = icon + label + color (never color alone); text must survive 2.0x scaling and long Bangla strings.
- Reuse widgets from `lib/shared/widgets/`; a new reusable widget gets a gallery entry in `gallery_sections.dart`.

## 6. Naming and style
snake_case files; `FooRepository` (interface), `FirestoreFooRepository`, `FooController`, `FooScreen`, `FooMapper`,
`AddFooUseCase`. Split widget files over ~300 lines. Immutable hand-written models with ==/hashCode/copyWith.
Follow `analysis_options.yaml`; imports sorted; `flutter analyze` must report ZERO issues (infos too).

## 7. Tests (written with the code, not after)
- Domain rules: unit tests. Use cases: tests with `InMemoryBackend`/`FakeTxRunner`. Mappers: round-trip tests.
- Rules: emulator tests. Screens: widget tests including bn/en and large text.
- Goldens are generated on Linux CI only; locally run `flutter test --exclude-tags golden`. Never hand-edit golden PNGs.
- A bug fix includes a test that failed before the fix.

## 8. Definition of done (run and report the result of each)
```
dart format .
flutter analyze
flutter test --exclude-tags golden
npx firebase emulators:exec --only firestore --project demo-family-hub "npm --prefix firebase/rules_test test"   # if rules or data changed
node tools/check_indexes.mjs                                                                                    # if indexes changed
```
If you cannot run a command, say so clearly and list exactly what the user must run. Never claim something
passes if you did not run it.

## 9. Do not
- Commit secrets, keystores, `key.properties`, real `google-services.json` values, logs or build output.
- Edit generated files by hand when the generator is available (`flutter gen-l10n`).
- Leave `TODO(step-N)` markers, debug prints, commented-out code or unused imports.
- Weaken or delete a test, a lint, or a security rule to make something pass.
- Change `CLAUDE.md`, `AGENTS.md` or the rules without the user asking.

## 10. How to answer
End every task with: **files changed** (new/modified/deleted), **how to verify**, **assumptions**, and anything
you could not test. When asked for "changed files", list full repo-relative paths and give complete file contents.
