/// Role inside a family (roadmap 2.2).
enum MemberRole {
  admin,
  moderator,
  member;

  static MemberRole parse(String? value) => MemberRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => MemberRole.member,
      );

  /// Admins and moderators.
  bool get canManageMembers => this != MemberRole.member;
}
