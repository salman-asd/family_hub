import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_write_plan.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';

/// Builds a shape-checked [NewInboxItem] (P3-26).
///
/// The same limits as the rules (`inboxItemOk`): a type from the closed list,
/// at most six parameters, every key and value a short string. A caller that
/// breaks them gets a `Validation` instead of a write the server would deny.
abstract final class InboxWriter {
  static const int maxParams = 6;
  static const int maxValueLength = 200;

  static Result<NewInboxItem> create({
    required String toMemberId,
    required String type,
    required String refType,
    required String refId,
    Map<String, String> params = const <String, String>{},
    String id = '',
  }) {
    if (toMemberId.isEmpty) {
      return const Failure<NewInboxItem>(Validation('toMemberId', 'required'));
    }
    if (!InboxType.all.contains(type)) {
      return const Failure<NewInboxItem>(Validation('type', 'required'));
    }
    if (refId.isEmpty) {
      return const Failure<NewInboxItem>(Validation('refId', 'required'));
    }
    if (params.length > maxParams) {
      return const Failure<NewInboxItem>(
        Validation('params', 'too_many_items'),
      );
    }
    for (final entry in params.entries) {
      if (entry.key.isEmpty ||
          entry.key.length > 32 ||
          entry.value.length > maxValueLength) {
        return const Failure<NewInboxItem>(Validation('params', 'too_long'));
      }
    }
    return Success<NewInboxItem>(
      NewInboxItem(
        id: id,
        toMemberId: toMemberId,
        type: type,
        refType: refType,
        refId: refId,
        params: params,
      ),
    );
  }
}
