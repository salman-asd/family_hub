import 'package:family_hub/features/dashboard/domain/card_access.dart';

final class DashboardPrefs {
  DashboardPrefs({
    List<String> order = const <String>[],
    Set<String> hidden = const <String>{},
    Set<String> shown = const <String>{},
  }) : order = List<String>.unmodifiable(order),
       hidden = Set<String>.unmodifiable(hidden),
       shown = Set<String>.unmodifiable(shown);

  static final DashboardPrefs defaults = DashboardPrefs();

  final List<String> order;
  final Set<String> hidden;
  final Set<String> shown;

  DashboardPrefs copyWith({
    List<String>? order,
    Set<String>? hidden,
    Set<String>? shown,
  }) => DashboardPrefs(
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    shown: shown ?? this.shown,
  );

  DashboardPrefs moveCard(String id, int newIndex) {
    final next = List<String>.of(order);
    final oldIndex = next.indexOf(id);
    if (oldIndex < 0 || next.isEmpty) return this;

    next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), id);
    return DashboardPrefs(order: next, hidden: hidden, shown: shown);
  }

  DashboardPrefs setVisible(
    String id,
    bool visible, {
    required CardAccess access,
  }) {
    if (access == CardAccess.hidden || access == CardAccess.required) {
      return this;
    }

    final nextHidden = Set<String>.of(hidden)..remove(id);
    final nextShown = Set<String>.of(shown)..remove(id);
    if (visible && access == CardAccess.off) {
      nextShown.add(id);
    } else if (!visible && access == CardAccess.on) {
      nextHidden.add(id);
    }
    return DashboardPrefs(order: order, hidden: nextHidden, shown: nextShown);
  }

  DashboardPrefs reset() => DashboardPrefs();

  @override
  bool operator ==(Object other) =>
      other is DashboardPrefs &&
      _listsEqual(order, other.order) &&
      _setsEqual(hidden, other.hidden) &&
      _setsEqual(shown, other.shown);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(order),
    Object.hashAll(hidden.toList()..sort()),
    Object.hashAll(shown.toList()..sort()),
  );
}

bool _listsEqual(List<String> first, List<String> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

bool _setsEqual(Set<String> first, Set<String> second) =>
    first.length == second.length && first.containsAll(second);
