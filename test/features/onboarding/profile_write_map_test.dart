import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/onboarding/data/firestore_profile_repository.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = UserProfile(
    uid: 'u1',
    fullName: 'Rina',
    relationship: RelationshipId.mother,
  );
  final now = DateTime.utc(2026, 10, 21);

  test('first save writes the creation stamp', () {
    final m = FirestoreProfileRepository.profileWriteMap(profile, null, now);
    expect(m[BaseMapper.keyCreatedAt], isNotNull);
    expect(m[BaseMapper.keyCreatedBy], 'u1');
    expect(m['relationship'], 'mother');
  });

  test('a document that only holds preferences still gets its first stamp', () {
    final m = FirestoreProfileRepository.profileWriteMap(
      profile,
      {'preferences': {'language': 'bn'}},
      now,
    );
    expect(m.containsKey(BaseMapper.keyCreatedAt), isTrue);
  });

  test('a later save never rewrites createdAt / createdBy', () {
    final m = FirestoreProfileRepository.profileWriteMap(
      profile,
      {BaseMapper.keyCreatedAt: 'earlier'},
      now,
    );
    expect(m.containsKey(BaseMapper.keyCreatedAt), isFalse);
    expect(m.containsKey(BaseMapper.keyCreatedBy), isFalse);
    expect(m[BaseMapper.keyUpdatedAt], isNotNull);
    expect(m[BaseMapper.keyUpdatedBy], 'u1');
  });
}
