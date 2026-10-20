/// Role inside a family, under the name the family feature already uses.
///
/// Step 10 moved the canonical enum to `core/permissions/role.dart` so that the
/// permission policy can use it without `core/` importing a feature.  This file
/// keeps `MemberRole` as a typedef (and re-exports `Role`), so every Step 9 call
/// site — including `MemberRole.parse(...)` and `MemberRole.values` — still
/// compiles unchanged.
///
/// The `import` is needed as well as the `export`: `export` only affects the
/// libraries that import this file, it does not put `Role` in scope here.
library;

import 'package:family_hub/core/permissions/role.dart';

export 'package:family_hub/core/permissions/role.dart' show Role;

typedef MemberRole = Role;

/// The roles an admin may hand out from the roles screen (admin is moved with
/// "transfer admin", never assigned directly).  Domain data, so no widget has
/// to name a role.
const List<MemberRole> assignableRoles = <MemberRole>[
  Role.moderator,
  Role.member,
];
