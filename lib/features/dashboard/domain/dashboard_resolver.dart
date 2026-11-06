import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';

typedef DashboardCan = bool Function(Permission permission);

abstract final class DashboardResolver {
  static DashboardLayout resolve({
    required Role role,
    required DashboardPolicy policy,
    required DashboardPrefs prefs,
    required Map<String, bool> modulesEnabled,
    required DashboardCan can,
  }) {
    final visible = <ResolvedCard>[];
    final optionalHidden = <ResolvedCard>[];
    final required = <ResolvedCard>[];

    for (final card in CardCatalog.cards) {
      if (!_moduleEnabled(card.moduleId, modulesEnabled) ||
          !_hasRequiredPermissions(card, can)) {
        continue;
      }

      final access = policy.accessFor(role, card.id);
      if (access == CardAccess.hidden) continue;

      final resolved = ResolvedCard(
        definition: card,
        access: access,
        canHide: access != CardAccess.required,
      );
      final isVisible = switch (access) {
        CardAccess.hidden => false,
        CardAccess.required => true,
        CardAccess.on => !prefs.hidden.contains(card.id),
        CardAccess.off => prefs.shown.contains(card.id),
      };

      if (access == CardAccess.required) required.add(resolved);
      if (isVisible) {
        visible.add(resolved);
      } else {
        optionalHidden.add(resolved);
      }
    }

    return DashboardLayout(
      visible: _ordered(visible, prefs, requiredFirst: true),
      optionalHidden: _ordered(optionalHidden, prefs),
      required: _ordered(required, prefs),
    );
  }

  static bool _moduleEnabled(
    String moduleId,
    Map<String, bool> modulesEnabled,
  ) => moduleId == 'core' || modulesEnabled[moduleId] == true;

  static bool _hasRequiredPermissions(DashboardCardDef card, DashboardCan can) {
    final single = card.requiredPermission;
    if (single != null && !can(single)) return false;
    final alternatives = card.anyRequiredPermissions;
    return alternatives.isEmpty || alternatives.any(can);
  }

  static List<ResolvedCard> _ordered(
    List<ResolvedCard> cards,
    DashboardPrefs prefs, {
    bool requiredFirst = false,
  }) {
    final byId = <String, ResolvedCard>{
      for (final card in cards) card.definition.id: card,
    };
    final ordered = <ResolvedCard>[];
    final added = <String>{};

    if (requiredFirst) {
      for (final card in cards) {
        if (card.access == CardAccess.required &&
            !prefs.order.contains(card.definition.id)) {
          ordered.add(card);
          added.add(card.definition.id);
        }
      }
    }
    for (final id in prefs.order) {
      final card = byId[id];
      if (card != null && added.add(id)) ordered.add(card);
    }

    final remaining =
        cards.where((card) => !added.contains(card.definition.id)).toList()
          ..sort(
            (first, second) => first.definition.defaultOrder.compareTo(
              second.definition.defaultOrder,
            ),
          );
    ordered.addAll(remaining);
    return ordered;
  }
}

final class ResolvedCard {
  const ResolvedCard({
    required this.definition,
    required this.access,
    required this.canHide,
  });

  final DashboardCardDef definition;
  final CardAccess access;
  final bool canHide;

  ResolvedCard copyWith({
    DashboardCardDef? definition,
    CardAccess? access,
    bool? canHide,
  }) => ResolvedCard(
    definition: definition ?? this.definition,
    access: access ?? this.access,
    canHide: canHide ?? this.canHide,
  );

  @override
  bool operator ==(Object other) =>
      other is ResolvedCard &&
      other.definition.id == definition.id &&
      other.access == access &&
      other.canHide == canHide;

  @override
  int get hashCode => Object.hash(definition.id, access, canHide);
}

final class DashboardLayout {
  DashboardLayout({
    required List<ResolvedCard> visible,
    required List<ResolvedCard> optionalHidden,
    required List<ResolvedCard> required,
  }) : visible = List<ResolvedCard>.unmodifiable(visible),
       optionalHidden = List<ResolvedCard>.unmodifiable(optionalHidden),
       required = List<ResolvedCard>.unmodifiable(required);

  final List<ResolvedCard> visible;
  final List<ResolvedCard> optionalHidden;
  final List<ResolvedCard> required;

  DashboardLayout copyWith({
    List<ResolvedCard>? visible,
    List<ResolvedCard>? optionalHidden,
    List<ResolvedCard>? required,
  }) => DashboardLayout(
    visible: visible ?? this.visible,
    optionalHidden: optionalHidden ?? this.optionalHidden,
    required: required ?? this.required,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardLayout &&
      _cardsEqual(visible, other.visible) &&
      _cardsEqual(optionalHidden, other.optionalHidden) &&
      _cardsEqual(required, other.required);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(visible),
    Object.hashAll(optionalHidden),
    Object.hashAll(required),
  );
}

bool _cardsEqual(List<ResolvedCard> first, List<ResolvedCard> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
