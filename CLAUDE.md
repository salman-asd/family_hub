# Family Hub - project context (read before every task)

You are a senior Flutter engineer building 'Family Hub', a Bangla-first household app (bazar and family finance + family chores) for one family. Android first, iOS-ready. Backend: Firebase Auth + Cloud Firestore on the free Spark plan. No Cloud Functions, and no hard dependency on Cloud Storage.

ARCHITECTURE: feature-first Clean Architecture. Each feature has data/, domain/, presentation/. domain is pure Dart (no flutter or firebase imports). presentation never touches Firestore: screen -> Riverpod controller -> use case -> repository interface. data implements repositories and maps Firestore documents to domain entities through mappers.

## HARD RULES
1. Money is integer paisa in a Money value object. Quantities are integer milli-units. Never double.
2. Time-based records store a UTC Timestamp plus dateKey (yyyy-MM-dd) and monthKey (yyyy-MM) computed in the family timezone (default Asia/Dhaka). Use an injected Clock; never call DateTime.now() in domain code.
3. All writes go through use cases. A use case checks permission (PermissionPolicy), applies business rules, writes through a repository, and writes audit and activity entries in the same batch/transaction where required.
4. Deterministic IDs: occurrences {templateId}_{yyyyMMdd}; budgets {yyyy-MM}; contribution plans {yyyy-MM}_{memberId}.
5. Soft delete only (deletedAt, deletedBy). Every document has createdAt, createdBy, updatedAt, updatedBy, schemaVersion.
6. No raw Color(0x...) or hex outside lib/app/theme/. Screens read tokens via context.tokens.
7. No hard-coded user-visible strings. Use ARB localization (bn default, en). Test long Bangla strings for overflow.
8. Riverpod (Notifier/AsyncNotifier), freezed immutable models, go_router with auth and family guards.
9. Use cases return Result<T> with a sealed AppFailure. UI maps failures to localized messages. No silent catches.
10. Business rules live in domain with unit tests. Every screen handles loading, empty, error and offline states.
11. Queries are bounded by a monthKey/dateKey range and a limit. One listener per screen; cancel on dispose.
12. Every permission is enforced in Firestore Security Rules as well as the UI.
13. Accessibility: touch targets >= 48dp, status never by color alone (icon + label + color), text scales with system font size.

## Layer boundaries
| Layer | May import | Must never import |
| --- | --- | --- |
| presentation | domain, shared, core | data, firebase packages |
| domain | Dart core, freezed, core value objects | flutter, firebase, any I/O |
| data | domain, firebase packages | presentation |

Naming: snake_case files; FooRepository (interface), FirestoreFooRepository (impl), FooController, FooScreen, FooMapper, AddFooUseCase. One class per use case file. Split widget files over ~300 lines.

## Folder structure
lib/ main_dev.dart, main_prod.dart; app/ (app, router, bootstrap, flavor, theme/); core/ (errors, utils, firebase, localization, notifications, permissions, constants); shared/ (widgets, services); modules/; features/ auth, onboarding, family, dashboard, settings, notifications, bazar/{expenses, items_categories, budgets, contributions, advances, reports, import}, chores/{templates, duty_groups, occurrences, calendar, swaps, availability, comments, achievements} (each: data/ domain/ presentation/). test/ mirrors lib/. firebase/ holds firestore.rules, firestore.indexes.json, rules_test/.

## WORKING METHOD
Before coding, list the files you will create or change. Write tests together with the code. Afterwards run dart format, flutter analyze and flutter test and report the results. Do not add packages not named. When something depends on current Firebase pricing, quotas, or package versions, check official docs instead of guessing. If an instruction is ambiguous, state your assumption and continue; ask only when a wrong guess would be expensive. End every task with: files changed, how to verify, anything you assumed.

## DEFAULT DECISIONS (until changed)
Teal accent token; chore verification off by default; absence policy A (ask for cover); members see only their own contributions; equal-split contributions; onion and potato are items under Vegetables; client-side scoring; Hub Level shown as a plant; Android only; Spark plan only.

## Rules extension (from Step 10 onward)
Every step that adds a collection must extend firestore.rules and the rules tests in the same commit.
