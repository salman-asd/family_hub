import 'package:family_hub/core/permissions/permission.dart';

enum DashboardCardSize { full, half, strip }

final class DashboardCardDef {
  DashboardCardDef({
    required this.id,
    required this.moduleId,
    required this.defaultOrder,
    required this.size,
    this.requiredPermission,
    List<Permission> anyRequiredPermissions = const <Permission>[],
  }) : anyRequiredPermissions = List<Permission>.unmodifiable(
         anyRequiredPermissions,
       );

  final String id;
  final String moduleId;
  final int defaultOrder;
  final DashboardCardSize size;
  final Permission? requiredPermission;

  /// At least one permission in this list is required when the card has
  /// multiple independent ways to be actionable.
  final List<Permission> anyRequiredPermissions;

  DashboardCardDef copyWith({
    String? id,
    String? moduleId,
    int? defaultOrder,
    DashboardCardSize? size,
    Permission? requiredPermission,
    List<Permission>? anyRequiredPermissions,
  }) => DashboardCardDef(
    id: id ?? this.id,
    moduleId: moduleId ?? this.moduleId,
    defaultOrder: defaultOrder ?? this.defaultOrder,
    size: size ?? this.size,
    requiredPermission: requiredPermission ?? this.requiredPermission,
    anyRequiredPermissions:
        anyRequiredPermissions ?? this.anyRequiredPermissions,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardCardDef &&
      other.id == id &&
      other.moduleId == moduleId &&
      other.defaultOrder == defaultOrder &&
      other.size == size &&
      other.requiredPermission == requiredPermission &&
      _permissionsEqual(other.anyRequiredPermissions, anyRequiredPermissions);

  @override
  int get hashCode => Object.hash(
    id,
    moduleId,
    defaultOrder,
    size,
    requiredPermission,
    Object.hashAll(anyRequiredPermissions),
  );
}

abstract final class CardCatalog {
  static final List<DashboardCardDef> cards =
      List<DashboardCardDef>.unmodifiable(<DashboardCardDef>[
        DashboardCardDef(
          id: 'budget_alert',
          moduleId: 'bazar',
          defaultOrder: 10,
          size: DashboardCardSize.strip,
        ),
        DashboardCardDef(
          id: 'approvals',
          moduleId: 'core',
          defaultOrder: 15,
          size: DashboardCardSize.full,
          anyRequiredPermissions: <Permission>[
            Permission.approveMembers,
            Permission.recordContribution,
          ],
        ),
        DashboardCardDef(
          id: 'chores_today',
          moduleId: 'chores',
          defaultOrder: 20,
          size: DashboardCardSize.full,
        ),
        DashboardCardDef(
          id: 'chores_overdue',
          moduleId: 'chores',
          defaultOrder: 30,
          size: DashboardCardSize.half,
        ),
        DashboardCardDef(
          id: 'chores_verify',
          moduleId: 'chores',
          defaultOrder: 40,
          size: DashboardCardSize.half,
          requiredPermission: Permission.verifyChore,
        ),
        DashboardCardDef(
          id: 'bazar_month',
          moduleId: 'bazar',
          defaultOrder: 50,
          size: DashboardCardSize.full,
        ),
        DashboardCardDef(
          id: 'bazar_fund',
          moduleId: 'bazar',
          defaultOrder: 60,
          size: DashboardCardSize.full,
        ),
        DashboardCardDef(
          id: 'upcoming',
          moduleId: 'core',
          defaultOrder: 70,
          size: DashboardCardSize.full,
        ),
        DashboardCardDef(
          id: 'chores_week',
          moduleId: 'chores',
          defaultOrder: 80,
          size: DashboardCardSize.full,
        ),
        DashboardCardDef(
          id: 'hub_level',
          moduleId: 'chores',
          defaultOrder: 90,
          size: DashboardCardSize.half,
        ),
        DashboardCardDef(
          id: 'recent_activity',
          moduleId: 'core',
          defaultOrder: 100,
          size: DashboardCardSize.full,
        ),
      ]);

  static final Map<String, DashboardCardDef> byId =
      Map<String, DashboardCardDef>.unmodifiable(<String, DashboardCardDef>{
        for (final card in cards) card.id: card,
      });

  static DashboardCardDef? find(String id) => byId[id];
}

bool _permissionsEqual(List<Permission> first, List<Permission> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
