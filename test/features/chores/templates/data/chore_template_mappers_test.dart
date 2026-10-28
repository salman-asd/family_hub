import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/templates/data/chore_template_mappers.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// P3-08: the template map round-trips, and the reader is tolerant (an unknown
/// schedule is shown as "invalid", never crashes the list).
void main() {
  final meta = BaseMapper.createMetadata(
    uid: 'alice',
    clock: FakeClock(DateTime.utc(2026, 10, 24, 9)),
  );
  DateKey d(String iso) => DateKey.parse(iso).valueOrNull!;

  ChoreTemplate aStored({TemplateDraft? draft, int revision = 1}) =>
      ChoreTemplate(
        id: 'tpl_1',
        draft: draft ?? aTemplate(),
        revision: revision,
        sortOrder: 3,
      );

  group('round trip', () {
    test('a plain template survives toMap -> fromMap', () {
      final template = aStored();
      final record = ChoreTemplateMappers.fromMap(
        template.id,
        ChoreTemplateMappers.toMap(template, meta),
      );
      expect(record.template, template);
      expect(record.invalidSchedule, isFalse);
    });

    test('a fully populated template survives', () {
      final draft = aTemplate(
        nameBn: 'থালা-বাসন',
        nameEn: 'Dishes',
        groupId: 'kitchen',
        recurrence: EveryNWeeksRecurrence(
          n: 2,
          anchor: d('2026-10-03'),
          weekdays: const [6],
          weekStart: 6,
        ),
        slots: <TemplateSlot>[
          aSlot(dueMinutes: 540),
          aSlot(key: 'noon', labelBn: 'দুপুর', dueMinutes: 840),
          aSlot(key: 'night', labelBn: 'রাত', dueMinutes: null),
        ],
        assignee: AssigneeSpec(
          strategy: AssigneeStrategy.rotation,
          rotation: Rotation(
            versions: <RotationVersion>[
              RotationVersion(
                from: d('2026-10-01'),
                members: const ['alice', 'bob', 'cara'],
                anchorDate: d('2026-10-01'),
                anchorIndex: 1,
                cycleUnit: CycleUnit.week,
                weekStartDay: 6,
              ),
            ],
          ),
        ),
        instructions: '# নিয়ম\n- **সাবধানে** ধোয়া',
        subtasks: <TemplateSubtask>[
          aSubtask(
            id: 'rinse',
            title: 'ধোয়া',
            required: true,
            hint: 'গরম পানি',
          ),
          aSubtask(id: 'dry', title: 'মুছা'),
        ],
        estimatedMinutes: 45,
        difficulty: Difficulty.hard,
        verification: VerificationMode.required,
        reminders: const ReminderConfig(
          enabled: true,
          offsetsMinutes: [10, 30],
          overdueEnabled: true,
          overdueAfterMinutes: 90,
        ),
        startDate: d('2026-10-01'),
        endDate: d('2027-03-31'),
        colorIndex: 9,
        iconKey: 'dishes',
      );
      final template = aStored(draft: draft, revision: 7).copyWith(
        sortOrder: 4,
        builtIn: true,
        seedKey: 'dishes',
        archivedAt: DateTime.utc(2026, 11, 1),
      );
      final map = ChoreTemplateMappers.toMap(template, meta);
      final back = ChoreTemplateMappers.fromMap(template.id, map);
      expect(back.template, template);
      expect(back.invalidSchedule, isFalse);
    });

    test('the map carries the identity fields the rules check', () {
      final template = aStored(revision: 4);
      final map = ChoreTemplateMappers.toMap(template, meta);
      expect(map['revision'], 4);
      expect(map['seedKey'], isNull);
      expect(map['builtIn'], false);
      expect(map['sortOrder'], 3);
      expect(map['schemaVersion'], 1);
    });

    test('a missing document reads as null', () {
      expect(ChoreTemplateMappers.fromDoc('tpl_1', null), isNull);
    });
  });

  group('tolerant read', () {
    test('an unknown recurrence kind is flagged, not dropped', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['recurrence'] = <String, Object?>{'kind': 'hourly_from_2027'};
      final record = ChoreTemplateMappers.fromMap('tpl_1', map);
      expect(record.invalidSchedule, isTrue);
      expect(record.template.draft.nameBn, 'বাসন ধোয়া');
    });

    test('a missing recurrence is flagged', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta)
        ..remove('recurrence');
      expect(
        ChoreTemplateMappers.fromMap('tpl_1', map).invalidSchedule,
        isTrue,
      );
    });

    test('an out-of-range colour falls back to the group colour', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['colorIndex'] = 99;
      expect(
        ChoreTemplateMappers.fromMap('tpl_1', map).template.draft.colorIndex,
        isNull,
      );
    });

    test('a missing main slot is repaired on read', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['slots'] = <Object?>[
        <String, Object?>{'key': 'noon', 'labelBn': 'দুপুর'},
      ];
      final slots = ChoreTemplateMappers.fromMap(
        'tpl_1',
        map,
      ).template.draft.slots;
      expect(slots.first.key, TemplateLimits.mainSlotKey);
      expect(slots, hasLength(2));
    });

    test('a malformed subtask row is skipped', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['subtasks'] = <Object?>[
        <String, Object?>{'id': 'a', 'title': 'ok'},
        'not a row',
        <String, Object?>{'id': 'BAD', 'title': 'x'},
        <String, Object?>{'id': 'b', 'title': ''},
        <String, Object?>{'id': 'a', 'title': 'duplicate'},
      ];
      final subtasks = ChoreTemplateMappers.fromMap(
        'tpl_1',
        map,
      ).template.draft.subtasks;
      expect(subtasks.map((s) => s.id), ['a']);
    });

    test('an unknown strategy reads as manual', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['assignee'] = <String, Object?>{'strategy': 'lottery'};
      expect(
        ChoreTemplateMappers.fromMap(
          'tpl_1',
          map,
        ).template.draft.assignee.strategy,
        AssigneeStrategy.manual,
      );
    });

    test('an unknown difficulty or verification falls back', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta)
        ..['difficulty'] = 'impossible'
        ..['verification'] = 'sometimes';
      final draft = ChoreTemplateMappers.fromMap('tpl_1', map).template.draft;
      expect(draft.difficulty, Difficulty.normal);
      expect(draft.verification, VerificationMode.off);
    });

    test('a revision below 1 is repaired to 1', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['revision'] = 0;
      expect(ChoreTemplateMappers.fromMap('tpl_1', map).template.revision, 1);
    });

    test('an over-long name and instructions are cut to the limits', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta)
        ..['nameBn'] = 'ক' * 200
        ..['instructions'] = 'x' * 9000;
      final draft = ChoreTemplateMappers.fromMap('tpl_1', map).template.draft;
      expect(draft.nameBn.length, TemplateLimits.maxNameLength);
      expect(draft.instructions.length, TemplateLimits.maxInstructionsLength);
    });

    test('an unknown rotation version is skipped, the rest kept', () {
      final map = ChoreTemplateMappers.toMap(
        aStored(
          draft: aTemplate(
            assignee: AssigneeSpec(
              strategy: AssigneeStrategy.rotation,
              rotation: Rotation(
                versions: <RotationVersion>[
                  RotationVersion(
                    from: d('2026-10-01'),
                    members: const ['alice', 'bob'],
                    anchorDate: d('2026-10-01'),
                    anchorIndex: 0,
                    cycleUnit: CycleUnit.day,
                    weekStartDay: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
        meta,
      );
      final assignee = map['assignee'] as Map<String, Object?>;
      final rotation = assignee['rotation'] as Map<String, Object?>;
      rotation['versions'] = <Object?>[
        <String, Object?>{'from': 'not a date'},
        <String, Object?>{
          'from': '2026-10-01',
          'anchorDate': '2026-10-01',
          'members': <String>['alice', 'bob'],
          'anchorIndex': 0,
          'cycleUnit': 'day',
          'weekStartDay': 6,
        },
      ];
      final parsed = ChoreTemplateMappers.fromMap(
        'tpl_1',
        map,
      ).template.draft.assignee.rotation;
      expect(parsed!.versions, hasLength(1));
    });

    test('reminders tolerate junk offsets', () {
      final map = ChoreTemplateMappers.toMap(aStored(), meta);
      map['reminders'] = <String, Object?>{
        'enabled': true,
        'atDue': false,
        'offsetsMinutes': <Object?>[10, 'soon', 0, 5000, 30],
        'overdueEnabled': true,
        'overdueAfterMinutes': 99999,
      };
      final reminders = ChoreTemplateMappers.fromMap(
        'tpl_1',
        map,
      ).template.draft.reminders;
      expect(reminders.enabled, isTrue);
      expect(reminders.offsetsMinutes, [10, 30]);
      expect(reminders.overdueAfterMinutes, 60, reason: 'out of range -> 60');
    });
  });
}
