import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a semantics walk found: how many nodes it read, how many of them are
/// tappable, and which tappables carry no label.
typedef TapTargetAudit = ({
  List<String> unlabeled,
  int nodes,
  int tappableNodes,
});

/// Tappable nodes in the live semantics tree, and those among them that
/// TalkBack would read out as an unlabeled button.
///
/// This is the same walk Material's `labeledTapTargetGuideline` does - merged,
/// invisible, hidden and text-field nodes are skipped - but instead of failing
/// it reports per offender, so a screen can carry a small, written-down
/// allow-list (P4-23) rather than losing the check altogether. [nodes] lets the
/// caller prove the walk read the screen, [tappableNodes] how much of it is
/// interactive.
///
/// An offender is described by the widget chain that owns the node, e.g.
/// `RichText ← Text ← Icon ← IconButton ← Padding ← Center`, which is what a
/// fix has to be found under.
TapTargetAudit auditTapTargets(WidgetTester tester) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  var nodes = 0;
  var tappableNodes = 0;
  final unlabeled = <String>[];
  void visit(SemanticsNode node) {
    nodes++;
    if (!node.isMergedIntoParent &&
        !node.isInvisible &&
        !node.flagsCollection.isHidden &&
        !node.flagsCollection.isTextField) {
      final data = node.getSemanticsData();
      final isTappable =
          data.hasAction(SemanticsAction.tap) ||
          data.hasAction(SemanticsAction.longPress);
      if (isTappable) {
        tappableNodes++;
        if (data.label.isEmpty && data.tooltip.isEmpty) {
          unlabeled.add(_ownerAt(tester, node.rect));
        }
      }
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return (unlabeled: unlabeled, nodes: nodes, tappableNodes: tappableNodes);
}

String _ownerAt(WidgetTester tester, Rect rect) {
  final result = tester.hitTestOnBinding(rect.center);
  String? fallback;
  for (final entry in result.path) {
    final target = entry.target;
    if (target is! RenderObject) continue;
    final creator = target.debugCreator;
    if (creator is! DebugCreator) continue;
    final owner = _interactiveOwner(creator.element);
    if (owner != null) return owner;
    fallback ??= creator.element.debugGetCreatorChain(6);
  }
  return fallback ?? 'node at $rect';
}

/// The widget a human would fix: the closest control on the element's own
/// ancestor chain, since the ink layers a tap lands on are not its children.
String? _interactiveOwner(Element element) {
  String? found;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    final isControl =
        widget is ButtonStyleButton ||
        widget is IconButton ||
        widget is InkResponse ||
        widget is ListTile ||
        widget is Switch ||
        widget is Checkbox ||
        widget is RadioListTile ||
        widget is PopupMenuButton ||
        widget is Slider ||
        widget is Tab ||
        widget is GestureDetector;
    if (!isControl) return true;
    final key = widget.key;
    found = key == null ? widget.toStringShort() : '$widget';
    return false;
  });
  return found;
}
