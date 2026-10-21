import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/cancel_join_request.dart';
import 'package:family_hub/features/family/domain/usecases/leave_family.dart';
import 'package:family_hub/features/settings/domain/account_repository.dart';
import 'package:family_hub/features/settings/domain/usecases/delete_account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../family/family_test_helpers.dart';

class _FakeAccounts implements AccountRepository {
  final Set<String> deleted = <String>{};
  AppFailure? failure;

  @override
  Future<Result<void>> markDeleted(String uid) async {
    if (failure != null) return Failure<void>(failure!);
    deleted.add(uid);
    return const Success<void>(null);
  }

  @override
  Stream<bool> watchMarkedDeleted(String uid) => Stream.value(deleted.contains(uid));
}

void main() {
  late Fixture f;
  late FakeAuthRepository auth;
  late _FakeAccounts accounts;

  DeleteAccount build() => DeleteAccount(
        auth: auth,
        accounts: accounts,
        families: f.backend,
        leaveFamily: LeaveFamily(families: f.backend, clock: f.clock, newId: f.ids.call),
        cancelJoinRequest:
            CancelJoinRequest(families: f.backend, clock: f.clock, newId: f.ids.call),
      );

  void signIn(String uid) {
    auth = FakeAuthRepository(
      signedInAs: AppUser(uid: uid, email: '$uid@x.com', emailVerified: true),
    );
  }

  setUp(() => accounts = _FakeAccounts());
  tearDown(() => auth.dispose());

  test('a plain member leaves, is marked deleted, then the auth user goes', () async {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      });
    signIn('kid');
    final r = await build()(uid: 'kid', password: 'pass1234', familyId: 'fam');
    expect(r.isSuccess, isTrue);
    expect(f.backend.members['fam']!['kid']!.isRemoved, isTrue);
    expect(accounts.deleted, {'kid'});
    expect(auth.calls, ['reauthenticate', 'deleteAuthUser']);
  });

  test('the only admin of a family with members must transfer admin first', () async {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      });
    signIn('admin');
    final r = await build()(uid: 'admin', password: 'pass1234', familyId: 'fam');
    expect((r.failureOrNull! as Conflict).code, 'last_admin_has_members');
    expect(accounts.deleted, isEmpty);
    expect(auth.calls, ['reauthenticate']);
  });

  test('a solo admin may delete; the family stays dormant', () async {
    f = Fixture()..seedFamily({'admin': (MemberRole.admin, MembershipStatus.active)});
    signIn('admin');
    final r = await build()(uid: 'admin', password: 'pass1234', familyId: 'fam');
    expect(r.isSuccess, isTrue);
    expect(f.backend.members['fam']!['admin']!.isRemoved, isFalse);
    expect(accounts.deleted, {'admin'});
  });

  test('a pending request is withdrawn', () async {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'wait': (MemberRole.member, MembershipStatus.pending),
      });
    signIn('wait');
    final r = await build()(uid: 'wait', password: 'pass1234', familyId: 'fam');
    expect(r.isSuccess, isTrue);
    expect(f.backend.members['fam']!['wait']!.isRemoved, isTrue);
  });

  test('a wrong password changes nothing', () async {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      });
    signIn('kid');
    auth.reauthenticateFailure = const InvalidCredentials();
    final r = await build()(uid: 'kid', password: 'bad', familyId: 'fam');
    expect(r.failureOrNull, isA<InvalidCredentials>());
    expect(f.backend.members['fam']!['kid']!.isRemoved, isFalse);
    expect(accounts.deleted, isEmpty);
  });

  test('resume: auth deletion failed once, the retry skips finished steps', () async {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
      });
    signIn('kid');
    auth.deleteAuthUserFailure = const Network();
    final first = await build()(uid: 'kid', password: 'pass1234', familyId: 'fam');
    expect(first.failureOrNull, isA<Network>());
    expect(accounts.deleted, {'kid'});

    auth.deleteAuthUserFailure = null;
    final retry = await build()(uid: 'kid', password: 'pass1234', familyId: 'fam');
    expect(retry.isSuccess, isTrue);
    // Leaving happened once: one leave event, not two.
    expect(f.backend.events.where((e) => e.type == 'member.left'), hasLength(1));
  });

  test('a user with no family can delete the account', () async {
    f = Fixture();
    signIn('solo');
    final r = await build()(uid: 'solo', password: 'pass1234');
    expect(r.isSuccess, isTrue);
    expect(accounts.deleted, {'solo'});
  });
}
