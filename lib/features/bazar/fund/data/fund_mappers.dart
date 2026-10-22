import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// Pure functions between the append-only ledger rows and Firestore maps.
///
/// `amountPaisa` is signed; the sign rules live in [FundTransaction] and are
/// repeated by `firebase/firestore.rules`.
abstract final class FundMappers {
  static Map<String, dynamic> fundTxToMap(
    FundTransaction t,
    BaseDocumentMetadata m,
  ) => <String, dynamic>{
    'type': t.type.name,
    'amountPaisa': t.amount.paisa,
    'dateKey': t.dateKey.toString(),
    'monthKey': t.monthKey.toString(),
    'refType': t.refType.name,
    'refId': t.refId,
    'note': t.note,
    ...BaseMapper.metadataToMap(m),
  };

  /// Tolerant read.  A stored zero is impossible for a healthy document; a
  /// malformed one is read as a one-paisa adjustment so the entity invariant
  /// still holds and the integrity checker can report the mismatch.
  static FundTransaction fundTxFromMap(String id, Map<String, dynamic> map) {
    final meta = BaseMapper.metadataFromMap(map);
    final at = meta.createdAt;
    final dateKey = _dateKeyFrom(
      map['dateKey'],
      DateKey(at.year, at.month, at.day),
    );
    final monthKey = _monthKeyFrom(map['monthKey'], dateKey.monthKey);
    final type = _type(map['type']);
    final paisa = _int(map['amountPaisa']);
    return FundTransaction(
      id: id,
      type: type,
      amount: Money.paisa(paisa == 0 ? _fallbackAmount(type) : paisa),
      dateKey: dateKey,
      monthKey: monthKey,
      refType: _refType(map['refType']),
      refId: _string(map['refId']),
      createdBy: meta.createdBy,
      createdAt: at,
      note: _nullableString(map['note']),
    );
  }

  static FundTxType _type(Object? value) {
    for (final type in FundTxType.values) {
      if (type.name == value) return type;
    }
    return FundTxType.adjustment;
  }

  static int _fallbackAmount(FundTxType type) => switch (type) {
    FundTxType.contribution => 1,
    FundTxType.expense || FundTxType.reimbursement => -1,
    FundTxType.opening || FundTxType.adjustment => 1,
  };

  static FundRefType _refType(Object? value) {
    for (final type in FundRefType.values) {
      if (type.name == value) return type;
    }
    return FundRefType.manual;
  }

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

  static String _string(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
