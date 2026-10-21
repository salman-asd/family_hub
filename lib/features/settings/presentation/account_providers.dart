import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/settings/domain/account_repository.dart';
import 'package:family_hub/features/settings/domain/usecases/delete_account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => throw UnimplementedError(
    'accountRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

final deleteAccountProvider = Provider<DeleteAccount>(
  (ref) => DeleteAccount(
    auth: ref.watch(authRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    leaveFamily: ref.watch(leaveFamilyProvider),
    cancelJoinRequest: ref.watch(cancelJoinRequestProvider),
  ),
);

/// True when a previous deletion marked the account deleted but the Auth user
/// still exists (the last step failed): the Security screen offers to finish.
final accountDeletionPendingProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(accountRepositoryProvider).watchMarkedDeleted(uid);
});
