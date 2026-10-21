import 'package:family_hub/features/family/data/relationship_mappers.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/family/domain/usecases/update_relationship_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

void main() {
  group('RelationshipId', () {
    test('valid, invalid and parse fall back to other', () {
      expect(RelationshipId.isValid('father'), isTrue);
      expect(RelationshipId.isValid('c0abc'), isTrue);
      expect(RelationshipId.isValid('Father'), isFalse);
      expect(RelationshipId.isValid('a'), isFalse);
      expect(RelationshipId.isValid(null), isFalse);
      expect(RelationshipId.parse('Bad id'), RelationshipId.other);
      expect(RelationshipId.parse('uncle'), const RelationshipId('uncle'));
    });
  });

  group('RelationshipCatalog', () {
    const base = RelationshipCatalog.defaults;

    test('defaults hold the ten built-ins; spouse only where it applies', () {
      expect(base.entries, hasLength(10));
      expect(base.canHaveSpouse(RelationshipId.father), isTrue);
      expect(base.canHaveSpouse(RelationshipId.other), isFalse);
    });

    test('add, rename, disable a custom entry', () {
      final added = base
          .add(id: 'uncle', labelBn: 'চাচা', labelEn: 'Uncle', spouseRelevant: true)
          .valueOrNull!;
      expect(added.selectable.any((e) => e.id.value == 'uncle'), isTrue);
      final renamed = added
          .rename(const RelationshipId('uncle'), labelBn: 'মামা', labelEn: 'Maternal uncle')
          .valueOrNull!;
      expect(renamed.labelOf(const RelationshipId('uncle'), 'en'), 'Maternal uncle');
      final off = renamed.setActive(const RelationshipId('uncle'), active: false).valueOrNull!;
      expect(off.selectable.any((e) => e.id.value == 'uncle'), isFalse);
      expect(off.find(const RelationshipId('uncle')), isNotNull);
    });

    test('built-ins cannot be renamed or disabled', () {
      expect(
        (base.rename(RelationshipId.father, labelBn: 'x', labelEn: 'x').failureOrNull!
                as Conflict)
            .code,
        'built_in',
      );
      expect(base.setActive(RelationshipId.other, active: false).failureOrNull,
          isA<Conflict>());
    });

    test('validation: bad id, empty or long label, duplicate, full list', () {
      expect(base.add(id: 'Bad', labelBn: 'a', labelEn: 'a').failureOrNull,
          isA<Validation>());
      expect(base.add(id: 'okid', labelBn: '', labelEn: ' ').failureOrNull,
          isA<Validation>());
      expect(base.add(id: 'okid', labelBn: 'x' * 41, labelEn: '').failureOrNull,
          isA<Validation>());
      expect(base.add(id: 'father', labelBn: 'a', labelEn: 'a').failureOrNull,
          isA<Conflict>());
      var full = base;
      for (var i = 0; full.entries.length < RelationshipCatalog.maxEntries; i++) {
        full = full.add(id: 'cx$i', labelBn: 'a', labelEn: 'a').valueOrNull!;
      }
      expect(full.add(id: 'cmore', labelBn: 'a', labelEn: 'a').failureOrNull,
          isA<Validation>());
    });

    test('an unknown id reads as Other', () {
      expect(base.labelOf(const RelationshipId('ghost'), 'en'), 'Other');
    });
  });

  group('mapper', () {
    test('round trip keeps custom entries', () {
      final c = RelationshipCatalog.defaults
          .add(id: 'uncle', labelBn: 'চাচা', labelEn: 'Uncle')
          .valueOrNull!;
      final map = {'items': RelationshipMappers.relationshipsChangeMap(c, actorUid: 'u', now: DateTime.utc(2026))['items']};
      expect(RelationshipMappers.relationshipsFromMap(map), c);
    });

    test('damaged data never loses the built-ins', () {
      final c = RelationshipMappers.relationshipsFromMap({
        'items': [
          'junk',
          {'id': 'Bad id'},
          {'id': 'father', 'labelEn': 'Hacked', 'builtIn': false},
          {'id': 'uncle', 'labelEn': 'Uncle'},
        ],
      });
      expect(c.find(RelationshipId.other), isNotNull);
      expect(c.labelOf(RelationshipId.father, 'en'), 'Father');
      expect(c.find(const RelationshipId('uncle')), isNotNull);
      expect(RelationshipMappers.relationshipsFromMap(null), RelationshipCatalog.defaults);
    });
  });

  group('UpdateRelationshipCatalog', () {
    late Fixture f;
    late UpdateRelationshipCatalog useCase;
    setUp(() {
      f = Fixture()
        ..seedFamily({
          'admin': (MemberRole.admin, MembershipStatus.active),
          'mod': (MemberRole.moderator, MembershipStatus.active),
        });
      useCase = UpdateRelationshipCatalog(
        families: f.backend,
        clock: f.clock,
        newId: f.ids.call,
      );
    });

    test('admin adds an entry with an audit event and a valid id', () async {
      final r = await useCase.add(
        actorUid: 'admin',
        familyId: 'fam',
        labelBn: 'চাচা',
        labelEn: 'Uncle',
      );
      final id = r.valueOrNull!.entries.last.id;
      expect(RelationshipId.isValid(id.value), isTrue);
      expect(f.backend.relationshipCatalogs['fam']!.entries, hasLength(11));
      expect(f.backend.events.last.type, 'family.updated');
    });

    test('a moderator is denied', () async {
      final r = await useCase.add(
        actorUid: 'mod',
        familyId: 'fam',
        labelBn: 'a',
        labelEn: 'a',
      );
      expect(r.failureOrNull, isA<PermissionDenied>());
      expect(f.backend.relationshipCatalogs['fam'], isNull);
    });
  });
}
