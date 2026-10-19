# 0004 - No code generation (decision D1)

**Status:** accepted (Phase 1 hardening, H1)

`freezed`, `json_serializable`, `riverpod_generator` and `build_runner` were declared but never used:
all models are hand-written immutable classes, mappers are hand-written, and providers are plain
`Provider`/`Notifier`. They were removed so that CI has no code-generation step and the lock file
carries no dead weight.

**Revisit** at Phase 2 Step 12 if `Expense` (about 20 fields) makes hand-written `==`/`copyWith`
error-prone. Then adopt `freezed` for NEW entities only, add `build_runner` to CI and README, and
change CLAUDE.md rule 8 again.
