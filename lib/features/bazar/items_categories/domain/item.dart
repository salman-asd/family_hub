import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';

/// A bazar item (`families/{f}/bazarItems/{id}`).
///
/// Seeded items are `builtIn` and keep their `seedKey`; custom items do not.
/// Items are deactivated, never deleted.  Prices are integer paisa.
final class Item {
  const Item({
    required this.id,
    required this.nameBn,
    this.nameEn,
    required this.categoryId,
    required this.defaultUnit,
    this.aliases = const <String>[],
    this.emoji,
    this.imageData,
    this.useCount = 0,
    this.lastPrice,
    this.lastUnitPrice,
    this.lastUsedAt,
    this.active = true,
    this.builtIn = false,
    this.seedKey,
  });

  final String id;
  final String nameBn;
  final String? nameEn;
  final String categoryId;
  final Unit defaultUnit;

  /// Alternative spellings searched by `ItemSearch` (at most 10, each ≤ 40).
  final List<String> aliases;
  final String? emoji;

  /// Base64 image data, at most 24 000 characters (enforced by the rules).
  final String? imageData;
  final int useCount;
  final Money? lastPrice;
  final Money? lastUnitPrice;
  final DateTime? lastUsedAt;
  final bool active;
  final bool builtIn;
  final String? seedKey;

  /// The label for the current language, falling back to the other one.
  String displayName({required bool bangla}) {
    final bn = nameBn.trim();
    final en = (nameEn ?? '').trim();
    if (bangla) return bn.isNotEmpty ? bn : en;
    return en.isNotEmpty ? en : bn;
  }

  Item copyWith({
    String? nameBn,
    String? nameEn,
    String? categoryId,
    Unit? defaultUnit,
    List<String>? aliases,
    String? emoji,
    String? imageData,
    int? useCount,
    Money? lastPrice,
    Money? lastUnitPrice,
    DateTime? lastUsedAt,
    bool? active,
    bool? builtIn,
    String? seedKey,
  }) => Item(
    id: id,
    nameBn: nameBn ?? this.nameBn,
    nameEn: nameEn ?? this.nameEn,
    categoryId: categoryId ?? this.categoryId,
    defaultUnit: defaultUnit ?? this.defaultUnit,
    aliases: aliases ?? this.aliases,
    emoji: emoji ?? this.emoji,
    imageData: imageData ?? this.imageData,
    useCount: useCount ?? this.useCount,
    lastPrice: lastPrice ?? this.lastPrice,
    lastUnitPrice: lastUnitPrice ?? this.lastUnitPrice,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    active: active ?? this.active,
    builtIn: builtIn ?? this.builtIn,
    seedKey: seedKey ?? this.seedKey,
  );

  @override
  bool operator ==(Object other) =>
      other is Item &&
      other.id == id &&
      other.nameBn == nameBn &&
      other.nameEn == nameEn &&
      other.categoryId == categoryId &&
      other.defaultUnit == defaultUnit &&
      _sameAliases(other.aliases, aliases) &&
      other.emoji == emoji &&
      other.imageData == imageData &&
      other.useCount == useCount &&
      other.lastPrice == lastPrice &&
      other.lastUnitPrice == lastUnitPrice &&
      other.lastUsedAt == lastUsedAt &&
      other.active == active &&
      other.builtIn == builtIn &&
      other.seedKey == seedKey;

  @override
  int get hashCode => Object.hash(
    id,
    nameBn,
    nameEn,
    categoryId,
    defaultUnit,
    Object.hashAll(aliases),
    emoji,
    imageData,
    useCount,
    lastPrice,
    lastUnitPrice,
    lastUsedAt,
    active,
    builtIn,
    seedKey,
  );

  @override
  String toString() => 'Item($id, $nameBn)';
}

bool _sameAliases(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
