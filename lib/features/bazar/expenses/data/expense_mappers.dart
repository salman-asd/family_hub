import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';

/// Pure functions between the expense entities and their Firestore maps.
///
/// The maps are the source of truth for the closed key sets in
/// `firebase/firestore.rules` and the fixtures in `test/contract`.
/// Money is integer paisa; quantities are integer milli-units; dates are
/// `yyyy-MM-dd` / `yyyy-MM` strings that sort in the family timezone.
abstract final class ExpenseMappers {
  static Map<String, dynamic> expenseToMap(Expense e, BaseDocumentMetadata m) =>
      <String, dynamic>{
        'dateKey': e.dateKey.toString(),
        'monthKey': e.monthKey.toString(),
        'occurredAt': BaseMapper.dateTimeToTimestamp(e.occurredAt),
        'itemId': e.itemId,
        'itemName': e.itemName,
        'categoryId': e.categoryId,
        if (e.qty != null) 'qtyMilli': e.qty!.milli,
        if (e.unit != null) 'unit': e.unit!.name,
        if (e.unitPrice != null) 'unitPricePaisa': e.unitPrice!.paisa,
        'totalPaisa': e.total.paisa,
        'fundingSource': e.funding.name,
        'paidByMemberId': e.paidByMemberId,
        'reimbursable': e.reimbursable,
        'purchaserId': e.purchaserId,
        'tripId': e.tripId,
        'shop': e.shop,
        'note': e.note,
        'source': e.source.name,
        'importBatchId': e.importBatchId,
        ...BaseMapper.metadataToMap(m),
      };

  /// Tolerant read: a bad enum becomes the safe default, missing counters are
  /// zero and an absent timestamp falls back to the document's creation time.
  static Expense expenseFromMap(String id, Map<String, dynamic> map) {
    final meta = BaseMapper.metadataFromMap(map);
    final occurredAt =
        BaseMapper.timestampToDateTime(map['occurredAt']) ?? meta.createdAt;
    final dateKey = _dateKeyFrom(
      map['dateKey'],
      DateKey(occurredAt.year, occurredAt.month, occurredAt.day),
    );
    final monthKey = _monthKeyFrom(map['monthKey'], dateKey.monthKey);
    final totalPaisa = _int(map['totalPaisa']);
    final requestedFunding = _funding(map['fundingSource']);
    final payer = _nullableString(map['paidByMemberId']);
    final funding = requestedFunding == FundingSource.member && payer != null
        ? FundingSource.member
        : FundingSource.fund;
    final qty = _nonNegativeInt(map['qtyMilli']);
    final unitPrice = _nonNegativeInt(map['unitPricePaisa']);
    return Expense(
      id: id,
      dateKey: dateKey,
      monthKey: monthKey,
      occurredAt: occurredAt,
      itemId: _nullableString(map['itemId']),
      itemName: _string(map['itemName']),
      categoryId: _string(map['categoryId']),
      qty: qty == null ? null : Quantity.milli(qty),
      unit: _unit(map['unit']),
      unitPrice: unitPrice == null ? null : Money.paisa(unitPrice),
      total: Money.paisa(totalPaisa > 0 ? totalPaisa : 1),
      funding: funding,
      paidByMemberId: funding == FundingSource.member ? payer : null,
      reimbursable:
          funding == FundingSource.member && _bool(map['reimbursable']),
      purchaserId: _nullableString(map['purchaserId']),
      tripId: _nullableString(map['tripId']),
      shop: _nullableString(map['shop']),
      note: _nullableString(map['note']),
      source: _source(map['source']),
      importBatchId: _nullableString(map['importBatchId']),
      deletedAt: meta.deletedAt,
      deletedBy: meta.deletedBy,
      createdBy: meta.createdBy,
      createdAt: meta.createdAt,
    );
  }

  /// Fields a content edit may change.  Immutable provenance (`createdAt`,
  /// `createdBy`, `source`, `importBatchId`, `tripId`) is deliberately absent.
  static Map<String, dynamic> expenseChangeMap(
    Expense e, {
    required String actorUid,
    required DateTime now,
  }) => <String, dynamic>{
    'dateKey': e.dateKey.toString(),
    'monthKey': e.monthKey.toString(),
    'occurredAt': BaseMapper.dateTimeToTimestamp(e.occurredAt),
    'itemId': e.itemId,
    'itemName': e.itemName,
    'categoryId': e.categoryId,
    'qtyMilli': e.qty?.milli,
    'unit': e.unit?.name,
    'unitPricePaisa': e.unitPrice?.paisa,
    'totalPaisa': e.total.paisa,
    'fundingSource': e.funding.name,
    'paidByMemberId': e.paidByMemberId,
    'reimbursable': e.reimbursable,
    'purchaserId': e.purchaserId,
    'shop': e.shop,
    'note': e.note,
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
    BaseMapper.keyUpdatedBy: actorUid,
  };

  /// The only four fields a soft delete/restore may touch.
  static Map<String, dynamic> expenseSoftDeleteMap(
    Expense e, {
    required String actorUid,
    required DateTime now,
  }) => <String, dynamic>{
    'deletedAt': BaseMapper.dateTimeToTimestamp(e.deletedAt),
    'deletedBy': e.deletedBy,
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
    BaseMapper.keyUpdatedBy: actorUid,
  };

  static Map<String, dynamic> revisionToMap(
    ExpenseRevision r,
    BaseDocumentMetadata m,
  ) => <String, dynamic>{
    'before': <String, dynamic>{...r.before},
    'changedFields': <String>[...r.changedFields],
    'reason': r.reason,
    ...BaseMapper.metadataToMap(m),
  };

  static ExpenseRevision revisionFromMap(String id, Map<String, dynamic> map) {
    final meta = BaseMapper.metadataFromMap(map);
    final before = map['before'];
    final fields = map['changedFields'];
    return ExpenseRevision(
      id: id,
      before: before is Map
          ? <String, Object?>{
              for (final entry in before.entries)
                entry.key.toString(): entry.value as Object?,
            }
          : const <String, Object?>{},
      changedFields: fields is List
          ? <String>[
              for (final value in fields)
                if (value is String) value,
            ]
          : const <String>[],
      reason: _nullableString(map['reason']),
      at: meta.createdAt,
      by: meta.createdBy,
    );
  }

  static Map<String, dynamic> tripToMap(Trip t, BaseDocumentMetadata m) =>
      <String, dynamic>{
        'dateKey': t.dateKey.toString(),
        'monthKey': t.monthKey.toString(),
        'shop': t.shop,
        'fundingSource': t.funding.name,
        'paidByMemberId': t.paidByMemberId,
        'reimbursable': t.reimbursable,
        'lineCount': t.lineCount,
        'totalPaisa': t.total.paisa,
        'note': t.note,
        ...BaseMapper.metadataToMap(m),
      };

  static DateKey _dateKeyFrom(Object? value, DateKey fallback) {
    if (value is String) {
      final parsed = DateKey.parse(value).valueOrNull;
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static MonthKey _monthKeyFrom(Object? value, MonthKey fallback) {
    if (value is String) {
      final parsed = MonthKey.parse(value).valueOrNull;
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static int? _nonNegativeInt(Object? value) =>
      value is num && value >= 0 ? value.toInt() : null;

  static String _string(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static bool _bool(Object? value) => value is bool ? value : false;

  static Unit? _unit(Object? value) {
    if (value is String) {
      for (final unit in Unit.values) {
        if (unit.name == value) return unit;
      }
    }
    return null;
  }

  static FundingSource _funding(Object? value) =>
      value == FundingSource.member.name
      ? FundingSource.member
      : FundingSource.fund;

  static ExpenseSource _source(Object? value) =>
      value == ExpenseSource.import.name
      ? ExpenseSource.import
      : ExpenseSource.manual;
}
