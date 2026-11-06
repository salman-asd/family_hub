import 'package:family_hub/core/utils/time_zones.dart';

enum PlannedNotificationKind {
  due,
  before,
  overdue,
  nudge,
  summary,
  contributionDue,
  monthEnd,
}

enum NotificationChannelId {
  choresDue('chores_due'),
  choresOverdue('chores_overdue'),
  dailySummary('daily_summary'),
  bazar('bazar'),
  family('family'),
  pushEvents('push_events');

  const NotificationChannelId(this.id);

  final String id;
}

final class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
    required this.refId,
    required this.channelId,
    this.familyTimezone = defaultTimezone,
  });

  final int id;
  final PlannedNotificationKind kind;

  /// Always a UTC instant.
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
  final String refId;
  final NotificationChannelId channelId;
  final String familyTimezone;

  PlannedNotification copyWith({
    int? id,
    PlannedNotificationKind? kind,
    DateTime? scheduledAt,
    String? title,
    String? body,
    String? payload,
    String? refId,
    NotificationChannelId? channelId,
    String? familyTimezone,
  }) => PlannedNotification(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    title: title ?? this.title,
    body: body ?? this.body,
    payload: payload ?? this.payload,
    refId: refId ?? this.refId,
    channelId: channelId ?? this.channelId,
    familyTimezone: familyTimezone ?? this.familyTimezone,
  );

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.kind == kind &&
      other.scheduledAt == scheduledAt &&
      other.title == title &&
      other.body == body &&
      other.payload == payload &&
      other.refId == refId &&
      other.channelId == channelId &&
      other.familyTimezone == familyTimezone;

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    scheduledAt,
    title,
    body,
    payload,
    refId,
    channelId,
    familyTimezone,
  );
}
