/// The permission matrix (Step 10).
///
/// Pure Dart: `core/permissions` imports nothing but Dart core, so every layer
/// (domain use cases, presentation widgets, tests) can use it.  A single
/// barrel keeps the import list short at the call sites.
library;

export 'package:family_hub/core/permissions/permission.dart';
export 'package:family_hub/core/permissions/permission_actor.dart';
export 'package:family_hub/core/permissions/permission_policy.dart';
export 'package:family_hub/core/permissions/permission_settings.dart';
export 'package:family_hub/core/permissions/role.dart';
