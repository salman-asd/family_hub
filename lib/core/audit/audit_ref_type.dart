/// The closed set of audit/activity reference types (P2-03).
///
/// Mirror of `refTypes()` in `firebase/firestore.rules`; the two lists are
/// compared by `test/core/audit/audit_event_type_test.dart`, so a new type here
/// that is missing from the rules (or the other way round) fails the build.
///
/// These are machine values. An event stores a `refType` + `refId`, never a
/// display label (CLAUDE.md rule 18).
abstract final class AuditRefType {
  static const String family = 'family';
  static const String member = 'member';
  static const String invitation = 'invitation';

  // Phase 2 (roadmap section 3.9).
  static const String category = 'category';
  static const String item = 'item';
  static const String expense = 'expense';
  static const String trip = 'trip';
  static const String budget = 'budget';
  static const String contribution = 'contribution';
  static const String contributionPlan = 'contributionPlan';
  static const String settlement = 'settlement';
  static const String month = 'month';
  static const String importBatch = 'importBatch';

  /// Every ref type, in the same order as the rules list.
  static const List<String> all = <String>[
    family,
    member,
    invitation,
    category,
    item,
    expense,
    trip,
    budget,
    contribution,
    contributionPlan,
    settlement,
    month,
    importBatch,
  ];
}
