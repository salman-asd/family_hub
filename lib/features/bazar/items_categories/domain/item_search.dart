import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/text_normalizer.dart';

/// In-memory search over the family's catalog.
///
/// Ranking key: match tier ascending, then `useCount` descending, then
/// built-in items first, then `nameBn` (and finally `id` for determinism).
///
/// Tiers are 0 = exact name/alias, 1 = name/alias prefix, 2 = any word
/// prefix, 3 = contains.  There is no romanizer: Latin queries match the
/// seeded aliases and every item's `nameEn`.
final class ItemSearch {
  ItemSearch(Iterable<Item> items) : _entries = _buildEntries(items);

  final List<_Entry> _entries;

  static List<_Entry> _buildEntries(Iterable<Item> items) {
    final entries = <_Entry>[];
    for (final item in items) {
      if (item.active) {
        entries.add(_Entry(item, _fields(item), entries.length));
      }
    }
    return entries;
  }

  static List<String> _fields(Item item) {
    final fields = <String>[
      normalizeSearch(item.nameBn),
      if (item.nameEn != null) normalizeSearch(item.nameEn!),
      for (final alias in item.aliases) normalizeSearch(alias),
    ];
    fields.removeWhere((field) => field.isEmpty);
    return fields;
  }

  /// Best [limit] matches for [query], optionally restricted to one category.
  ///
  /// An empty query shows the frequently used items first (`useCount > 0`,
  /// highest first), then the built-in items in the order they were supplied
  /// (the seed order), and nothing else.
  List<Item> search(String query, {String? categoryId, int limit = 8}) {
    if (limit <= 0) return const <Item>[];
    final normalized = normalizeSearch(query);

    if (normalized.isEmpty) {
      final frequent = <_Entry>[];
      final builtIns = <_Entry>[];
      for (final entry in _entries) {
        if (categoryId != null && entry.item.categoryId != categoryId) {
          continue;
        }
        if (entry.item.useCount > 0) {
          frequent.add(entry);
        } else if (entry.item.builtIn) {
          builtIns.add(entry);
        }
      }
      frequent.sort(_byFrequency);
      builtIns.sort((a, b) => a.order.compareTo(b.order));
      return <Item>[
        for (final entry in [...frequent, ...builtIns].take(limit)) entry.item,
      ];
    }

    final matches = <_Ranked>[];
    for (final entry in _entries) {
      if (categoryId != null && entry.item.categoryId != categoryId) continue;
      var tier = -1;
      for (final field in entry.fields) {
        final candidate = _tier(field, normalized);
        if (candidate >= 0 && (tier < 0 || candidate < tier)) tier = candidate;
      }
      if (tier >= 0) matches.add(_Ranked(entry.item, tier));
    }
    matches.sort(_byRank);
    return <Item>[for (final match in matches.take(limit)) match.item];
  }

  static int _tier(String field, String query) {
    if (field == query) return 0;
    if (field.startsWith(query)) return 1;
    if (field.split(' ').any((word) => word.startsWith(query))) return 2;
    if (field.contains(query)) return 3;
    return -1;
  }

  static int _byFrequency(_Entry a, _Entry b) {
    final use = b.item.useCount.compareTo(a.item.useCount);
    if (use != 0) return use;
    final builtIn = _builtInFirst(a.item, b.item);
    if (builtIn != 0) return builtIn;
    return _byName(a.item, b.item);
  }

  static int _byRank(_Ranked a, _Ranked b) {
    final tier = a.tier.compareTo(b.tier);
    if (tier != 0) return tier;
    final use = b.item.useCount.compareTo(a.item.useCount);
    if (use != 0) return use;
    final builtIn = _builtInFirst(a.item, b.item);
    if (builtIn != 0) return builtIn;
    return _byName(a.item, b.item);
  }

  static int _builtInFirst(Item a, Item b) =>
      (b.builtIn ? 1 : 0).compareTo(a.builtIn ? 1 : 0);

  static int _byName(Item a, Item b) {
    final name = a.nameBn.compareTo(b.nameBn);
    return name != 0 ? name : a.id.compareTo(b.id);
  }
}

final class _Entry {
  const _Entry(this.item, this.fields, this.order);

  final Item item;
  final List<String> fields;

  /// Position in the supplied list, used to keep built-ins in seed order.
  final int order;
}

final class _Ranked {
  const _Ranked(this.item, this.tier);

  final Item item;
  final int tier;
}
