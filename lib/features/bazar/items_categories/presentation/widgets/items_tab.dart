import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/text_normalizer.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/item_edit_sheet.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/item_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All items (hidden ones included for managers), with a search box and a
/// category filter.  Tap to edit when [canManage].
class ItemsTab extends ConsumerStatefulWidget {
  const ItemsTab({required this.canManage, super.key});

  final bool canManage;

  @override
  ConsumerState<ItemsTab> createState() => ItemsTabState();
}

/// Public so the screen's FAB can read the current category filter.
class ItemsTabState extends ConsumerState<ItemsTab> {
  final TextEditingController _query = TextEditingController();
  String? categoryId;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Item item, String key) {
    if (key.isEmpty) return true;
    final fields = <String>[item.nameBn, item.nameEn ?? '', ...item.aliases];
    return fields.any((f) => normalizeSearch(f).contains(key));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final index = ref.watch(catalogIndexProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final key = normalizeSearch(_query.text);
    final items = <Item>[
      for (final item in index.itemsById.values)
        if ((categoryId == null || item.categoryId == categoryId) &&
            _matches(item, key))
          item,
    ]..sort((a, b) {
        final name = a.nameBn.compareTo(b.nameBn);
        return name != 0 ? name : a.id.compareTo(b.id);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const ValueKey('items-search'),
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.catalogSearch,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ChoiceWrap<String?>(
              selected: categoryId,
              onChanged: (id) => setState(() => categoryId = id),
              options: [
                ChoiceOption<String?>(null, l10n.catalogAllCategories),
                for (final c in index.activeCategories)
                  ChoiceOption<String?>(c.id, c.displayName(bangla: bangla)),
              ],
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_outlined,
                  title: l10n.catalogItemsEmpty,
                )
              : ListView.builder(
                  key: const ValueKey('items-list'),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final category = index.categoryOf(item);
                    return Opacity(
                      opacity: item.active ? 1 : 0.6,
                      child: ListTile(
                        minTileHeight: 56,
                        onTap: widget.canManage
                            ? () => showItemEditSheet(context, existing: item)
                            : null,
                        leading: ItemThumb(
                          id: item.id,
                          name: item.displayName(bangla: bangla),
                        ),
                        title: Text(
                          item.displayName(bangla: bangla),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            if (category != null)
                              category.displayName(bangla: bangla),
                            if (!item.active) l10n.catalogHidden,
                          ].join(' · '),
                        ),
                        trailing: item.active
                            ? null
                            : Icon(
                                Icons.visibility_off_outlined,
                                color: t.textSecondary,
                                semanticLabel: l10n.catalogHidden,
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
