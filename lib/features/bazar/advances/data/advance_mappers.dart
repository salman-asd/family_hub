import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';

/// Pure functions between advances/settlements and their Firestore maps.
abstract final class AdvanceMappers {
  static Map<String, dynamic> advanceToMap(
    MemberAdvance a,
    BaseDocumentMetadata m,
  ) => <String, dynamic>{
    'expenseId': a.expenseId,
    'memberId': a.memberId,
    'amountPaisa': a.amount.paisa,
    'settledPaisa': a.settled.paisa,
    'status': a.status.name,
    'dateKey': a.dateKey.toString(),
    'monthKey': a.monthKey.toString(),
    ...BaseMapper.metadataToMap(m),
  };

  /// Tolerant read; a stored status that contradicts the two amounts is
  /// recomputed, while `voided` (an explicit lifecycle state) is preserved.
  static MemberAdvance advanceFromMap(
    String expenseId,
    Map<String, dynamic> map,
  ) {
    final meta = BaseMapper.metadataFromMap(map);
    final at = meta.createdAt;
    final dateKey = _dateKeyFrom(
      map['dateKey'],
      DateKey(at.year, at.month, at.day),
    );
    final monthKey = _monthKeyFrom(map['monthKey'], dateKey.monthKey);
    final amountPaisa = _nonNegativeInt(map['amountPaisa']);
    final settledPaisa = _nonNegativeInt(map['settledPaisa']);
    final amount = Money.paisa(amountPaisa ?? 0);
    final settled = Money.paisa(
      settledPaisa != null && settledPaisa <= amount.paisa ? settledPaisa : 0,
    );
    final stored = _status(map['status']);
    return MemberAdvance(
      expenseId:
          map['expenseId'] is String && (map['expenseId'] as String).isNotEmpty
          ? map['expenseId'] as String
          : expenseId,
      memberId: _string(map['memberId']),
      amount: amount,
      settled: settled,
      status: stored == AdvanceStatus.voided
          ? AdvanceStatus.voided
          : MemberAdvance.statusFor(amount, settled),
      dateKey: dateKey,
      monthKey: monthKey,
    );
  }

  /// The only mutable fields: settlement progress and the edit/void state.
  static Map<String, dynamic> advanceChangeMap(
    MemberAdvance a, {
    required String actorUid,
    required DateTime now,
  }) => <String, dynamic>{
    'memberId': a.memberId,
    'amountPaisa': a.amount.paisa,
    'settledPaisa': a.settled.paisa,
    'status': a.status.name,
    'dateKey': a.dateKey.toString(),
    'monthKey': a.monthKey.toString(),
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(now),
    BaseMapper.keyUpdatedBy: actorUid,
  };

  static Map<String, dynamic> settlementToMap(
    Settlement s,
    BaseDocumentMetadata m,
  ) => <String, dynamic>{
    'advanceId': s.advanceId,
    'memberId': s.memberId,
    'amountPaisa': s.amount.paisa,
    'dateKey': s.dateKey.toString(),
    'monthKey': s.monthKey.toString(),
    'method': s.method,
    'note': s.note,
    'fundTxId': s.fundTxId,
    ...BaseMapper.metadataToMap(m),
  };

  static Settlement settlementFromMap(String id, Map<String, dynamic> map) {
    final meta = BaseMapper.metadataFromMap(map);
    final at = meta.createdAt;
    final dateKey = _dateKeyFrom(
      map['dateKey'],
      DateKey(at.year, at.month, at.day),
    );
    final amount = _nonNegativeInt(map['amountPaisa']) ?? 1;
    return Settlement(
      id: id,
      advanceId: _string(map['advanceId']),
      memberId: _string(map['memberId']),
      amount: Money.paisa(amount == 0 ? 1 : amount),
      dateKey: dateKey,
      monthKey: _monthKeyFrom(map['monthKey'], dateKey.monthKey),
      fundTxId:
          map['fundTxId'] is String && (map['fundTxId'] as String).isNotEmpty
          ? map['fundTxId'] as String
          : 'stl_$id',
      method: _nullableString(map['method']),
      note: _nullableString(map['note']),
    );
  }

  static AdvanceStatus _status(Object? value) {
    for (final status in AdvanceStatus.values) {
      if (status.name == value) return status;
    }
    return AdvanceStatus.pending;
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

  static int? _nonNegativeInt(Object? value) =>
      value is num && value >= 0 ? value.toInt() : null;

  static String _string(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
