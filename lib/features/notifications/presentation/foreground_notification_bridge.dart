import 'package:family_hub/core/notifications/domain/planned_notification.dart';
import 'package:family_hub/core/notifications/domain/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows at most one foreground notification per inbox id on this device.
final class ForegroundNotificationBridge {
  const ForegroundNotificationBridge({
    required this._scheduler,
    required this._preferences,
    required this._viewerId,
  });

  final ReminderScheduler _scheduler;
  final SharedPreferences _preferences;
  final String _viewerId;
  static final Set<String> _inFlight = <String>{};

  String get _key => 'foreground_inbox_notified.$_viewerId';

  Future<bool> showOnce(
    String inboxId,
    PlannedNotification notification,
  ) async {
    if (!_inFlight.add('$_key.$inboxId')) return false;
    try {
      final ids = _preferences.getStringList(_key) ?? <String>[];
      if (ids.contains(inboxId)) return false;

      await _scheduler.showNow(notification);
      ids.add(inboxId);
      final saved = await _preferences.setStringList(_key, ids);
      if (!saved) {
        throw StateError('Could not save foreground notification state.');
      }
      return true;
    } finally {
      _inFlight.remove('$_key.$inboxId');
    }
  }
}
