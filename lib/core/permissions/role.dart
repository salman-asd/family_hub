/// Role inside a family (roadmap 2.2).
///
/// This is the *single* role type of the app.  Step 10 moved it from
/// `features/family/domain/member_role.dart` to `core/` so that
/// [PermissionPolicy] can use it without importing a feature (`core/` must
/// never depend on `features/`).  The historical name `MemberRole` survives as
/// a typedef in that file, so the family feature and its Step 9 tests are
/// unchanged.
enum Role {
  admin,
  moderator,
  member;

  static Role parse(String? value) => Role.values.firstWhere(
        (r) => r.name == value,
        orElse: () => Role.member,
      );

  /// Admins and moderators.
  bool get canManageMembers => this != Role.member;
}
