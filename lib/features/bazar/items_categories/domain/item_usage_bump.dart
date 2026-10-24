import 'package:family_hub/core/utils/money.dart';

/// How one shopping event changes an item's usage counters.
///
/// The repository stages this as a single `update` on the item document; the
/// count is an increment, so two devices buying the same item offline cannot
/// overwrite each other (P2-09 builds these and P2-10 stages them).
final class ItemUsageBump {
  const ItemUsageBump({
    required this.itemId,
    required this.increments,
    required this.at,
    this.lastPrice,
    this.lastUnitPrice,
  }) : assert(increments > 0, 'increments must be positive');

  final String itemId;
  final int increments;
  final Money? lastPrice;
  final Money? lastUnitPrice;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is ItemUsageBump &&
      other.itemId == itemId &&
      other.increments == increments &&
      other.lastPrice == lastPrice &&
      other.lastUnitPrice == lastUnitPrice &&
      other.at == at;

  @override
  int get hashCode =>
      Object.hash(itemId, increments, lastPrice, lastUnitPrice, at);

  @override
  String toString() => 'ItemUsageBump($itemId, +$increments)';
}
