import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// Pure functions between `monthClosings/{yyyy-MM}` and its Firestore map.
abstract final class MonthClosingMappers {
  static Map<String, dynamic> closingToMap(
    MonthClosing c,
    BaseDocumentMetadata m,
  ) => <String, dynamic>{
    'monthKey': c.monthKey.toString(),
    'status': c.status.name,
    'closedAt': BaseMapper.dateTimeToTimestamp(c.closedAt),
    'closedBy': c.closedBy,
    'closingBalancePaisa': c.closingBalance?.paisa,
    'reopenedAt': BaseMapper.dateTimeToTimestamp(c.reopenedAt),
    'reopenedBy': c.reopenedBy,
    'reopenNote': c.reopenNote,
    'reopenCount': c.reopenCount,
    ...BaseMapper.metadataToMap(m),
  };

  static MonthClosing closingFromMap(String id, Map<String, dynamic> map) {
    final fallback = MonthKey.parse(id).valueOrNull;
    final parsed =
        MonthKey.parse(
          map['monthKey'] is String ? map['monthKey'] as String : '',
        ).valueOrNull ??
        fallback ??
        MonthKey(1970, 1);
    final balance = map['closingBalancePaisa'];
    final reopenCount = map['reopenCount'];
    return MonthClosing(
      monthKey: parsed,
      status: map['status'] == MonthStatus.closed.name
          ? MonthStatus.closed
          : MonthStatus.open,
      closedAt: BaseMapper.timestampToDateTime(map['closedAt']),
      closedBy: _nullableString(map['closedBy']),
      closingBalance: balance is num ? Money.paisa(balance.toInt()) : null,
      reopenedAt: BaseMapper.timestampToDateTime(map['reopenedAt']),
      reopenedBy: _nullableString(map['reopenedBy']),
      reopenNote: _nullableString(map['reopenNote']),
      reopenCount: reopenCount is num ? reopenCount.toInt() : 0,
    );
  }

  static String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
