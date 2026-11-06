import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/features/activity/data/activity_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 6, 4, 36);

  test('maps machine activity fields and filters malformed params', () {
    final entry = ActivityMappers.fromDoc('event-1', <String, dynamic>{
      'type': 'future.changed',
      'actorId': 'member-1',
      'params': <Object, Object>{'name': 'Rina', 'count': 3},
      'refType': 'futureRef',
      'refId': 'record-1',
      'createdAt': Timestamp.fromDate(createdAt),
    });

    expect(entry, isNotNull);
    expect(entry!.id, 'event-1');
    expect(entry.type, 'future.changed');
    expect(entry.params, {'name': 'Rina'});
    expect(entry.createdAt, createdAt);
  });

  test('skips records missing required fields or a usable timestamp', () {
    expect(ActivityMappers.fromDoc('bad', <String, dynamic>{}), isNull);
    expect(
      ActivityMappers.fromDoc('bad', <String, dynamic>{
        'type': 'x',
        'actorId': 'member-1',
        'refType': 'family',
        'refId': 'family-1',
        'createdAt': 'not-a-date',
      }),
      isNull,
    );
  });
}
