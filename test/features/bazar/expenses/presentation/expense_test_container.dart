import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/advances/presentation/advance_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bazar_test_helpers.dart';

/// The provider overrides that point every Bazar port at one in-memory
/// backend, signed in as [uid] with [role].  Shared by the controller tests
/// and the screen test so both run the real use cases.
List<Override> bazarOverrides(
  BazarFixture fx, {
  String uid = 'alice',
  Role role = Role.admin,
}) => [
  clockProvider.overrideWithValue(fx.clock),
  idGeneratorProvider.overrideWithValue(fx.ids.call),
  currentFamilyIdProvider.overrideWithValue(BazarFixture.familyId),
  currentUidProvider.overrideWithValue(uid),
  currentActorProvider.overrideWithValue(
    PermissionActor(uid: uid, role: role, isActive: true),
  ),
  permissionSettingsProvider.overrideWithValue(PermissionSettings.defaults),
  bazarSettingsProvider.overrideWithValue(
    BazarSettings.defaults.copyWith(fundStartMonth: MonthKey(2026, 9)),
  ),
  familyRepositoryProvider.overrideWithValue(fx.backend),
  catalogRepositoryProvider.overrideWithValue(fx.backend),
  expenseRepositoryProvider.overrideWithValue(fx.backend),
  fundRepositoryProvider.overrideWithValue(fx.backend),
  advanceRepositoryProvider.overrideWithValue(fx.backend),
];
