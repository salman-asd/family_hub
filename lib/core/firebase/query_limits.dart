/// Query discipline (CLAUDE.md rule 11, H12): every collection read is bounded.
///
/// Phase 2 screens page with [defaultPageSize] and never ask for more than
/// [kMaxListenerDocs] documents on one listener.  `test/architecture/
/// no_unbounded_queries_test.dart` fails when a `.collection(...)` read in a
/// data layer has no `.limit(...)`.
const int defaultPageSize = 30;

/// Hard cap for one live listener (a month of expenses fits comfortably).
const int kMaxListenerDocs = 500;

/// Hard cap for one catalog listener (11 categories + 54 built-in items plus
/// room for custom entries; the rules cap the same collections implicitly).
const int kMaxCatalogDocs = 500;
