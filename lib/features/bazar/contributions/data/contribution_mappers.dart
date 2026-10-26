import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';

/// Pure functions between contributions/plans and their Firestore maps.
///
/// Money is integer paisa (`*Paisa`).  Optional values are LEFT OUT when absent
/// (the rules check `!('fundTxId' in d)` on a member's request).  The key list
/// written here is mirrored by `contributionKeys()` / `contributionPlanKeys()`
/// in the rules and by `test/contract/rules_key_sets_test.dart`.  Reads are
/// tolerant: a document without `status` (legacy) is read as approved.
abstract final class ContributionMappers {
  static Map<String, dynamic> toMap(
    Contribution c,
    BaseDocumentMetadata meta,
  ) => <String, dynamic>{
    'memberId': c.memberId,
    'monthKey': c.monthKey.toString(),
    'dateKey': c.dateKey.toString(),
    'amountPaisa': c.amount.paisa,
    if (c.method != null) 'method': c.method!.name,
    if (c.note != null) 'note': c.note,
    'status': c.status.name,
    'requestedBy': c.requestedBy,
    if (c.fundTxId != null) 'fundTxId': c.fundTxId,
    if (c.decidedBy != null) 'decidedBy': c.decidedBy,
    if (c.decidedAt != null)
      'decidedAt': BaseMapper.dateTimeToTimestamp(c.decidedAt),
    if (c.rejectReason != null) 'rejectReason': c.rejectReason,
    if (c.pendingChange != null) 'pendingChange': changeToMap(c.pendingChange!),
    if (c.voidedAt != null)
      'voidedAt': BaseMapper.dateTimeToTimestamp(c.voidedAt),
    if (c.voidedBy != null) 'voidedBy': c.voidedBy,
    ...BaseMapper.metadataToMap(meta),
  };

  static Map<String, dynamic> changeToMap(ContributionChange change) =>
      <String, dynamic>{
        'amountPaisa': change.amount.paisa,
        'dateKey': change.date.toString(),
        if (change.method != null) 'method': change.method!.name,
        if (change.note != null) 'note': change.note,
        'requestedAt': BaseMapper.dateTimeToTimestamp(change.requestedAt),
      };

  /// `null` when the document has no usable amount or date (it is skipped).
  static Contribution? fromMap(String id, Map<String, dynamic> map) {
    final meta = BaseMapper.metadataFromMap(map);
    final amount = _positiveInt(map['amountPaisa']);
    final dateKey = _dateKey(map['dateKey']);
    if (amount == null || dateKey == null) return null;
    final status = _status(map['status']);
    final requestedBy = _string(map['requestedBy']) ?? meta.createdBy;
    return Contribution(
      id: id,
      memberId: _string(map['memberId']) ?? '',
      monthKey: _month(map['monthKey']) ?? dateKey.monthKey,
      dateKey: dateKey,
      amount: Money.paisa(amount),
      method: _method(map['method']),
      note: _string(map['note']),
      status: status,
      requestedBy: requestedBy,
      createdAt: meta.createdAt,
      fundTxId: _string(map['fundTxId']),
      decidedBy: _string(map['decidedBy']),
      decidedAt: BaseMapper.timestampToDateTime(map['decidedAt']),
      rejectReason: _string(map['rejectReason']),
      pendingChange: changeFromMap(map['pendingChange']),
      voidedAt: BaseMapper.timestampToDateTime(map['voidedAt']),
      voidedBy: _string(map['voidedBy']),
    );
  }

  static ContributionChange? changeFromMap(Object? raw) {
    if (raw is! Map) return null;
    final amount = _positiveInt(raw['amountPaisa']);
    final date = _dateKey(raw['dateKey']);
    if (amount == null || date == null) return null;
    return ContributionChange(
      amount: Money.paisa(amount),
      date: date,
      method: _method(raw['method']),
      note: _string(raw['note']),
      requestedAt:
          BaseMapper.timestampToDateTime(raw['requestedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static Map<String, dynamic> planToMap(
    ContributionPlan plan,
    BaseDocumentMetadata meta,
  ) => <String, dynamic>{
    'monthKey': plan.month.toString(),
    'memberId': plan.memberId,
    'expectedPaisa': plan.expected.paisa,
    ...BaseMapper.metadataToMap(meta),
  };

  /// `null` for a plan without a readable month or member.
  static ContributionPlan? planFromMap(Map<String, dynamic> map) {
    final month = _month(map['monthKey']);
    final memberId = _string(map['memberId']);
    final expected = map['expectedPaisa'];
    if (month == null || memberId == null || memberId.isEmpty) return null;
    final paisa = expected is num ? expected.toInt() : 0;
    return ContributionPlan(
      month: month,
      memberId: memberId,
      expected: Money.paisa(paisa < 0 ? 0 : paisa),
    );
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static int? _positiveInt(Object? value) {
    if (value is! num) return null;
    final result = value.toInt();
    return result > 0 ? result : null;
  }

  static DateKey? _dateKey(Object? value) =>
      value is String ? DateKey.parse(value).valueOrNull : null;

  static MonthKey? _month(Object? value) =>
      value is String ? MonthKey.parse(value).valueOrNull : null;

  static ContributionApproval _status(Object? value) {
    for (final status in ContributionApproval.values) {
      if (status.name == value) return status;
    }
    return ContributionApproval.approved;
  }

  static ContributionMethod? _method(Object? value) {
    for (final method in ContributionMethod.values) {
      if (method.name == value) return method;
    }
    return null;
  }
}
