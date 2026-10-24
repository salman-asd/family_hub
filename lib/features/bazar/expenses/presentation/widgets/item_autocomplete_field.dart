import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/shared/widgets/item_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A text field with the family's matching items listed right under it.
///
/// Results come from `catalogIndexProvider.search` (frequent items first on an
/// empty query).  When nothing matches, one row offers to use the typed text as
/// a new item.  The list is inline, not an overlay, so it scrolls with the form
/// and survives large text and a software keyboard.
class ItemAutocompleteField extends ConsumerStatefulWidget {
  const ItemAutocompleteField({
    required this.controller,
    required this.selected,
    required this.onTextChanged,
    required this.onSelected,
    required this.onNewItem,
    this.errorText,
    this.categoryId,
    this.enabled = true,
    this.autofocus = false,
    this.label,
    this.maxResults = 5,
    this.allowNew = true,
    super.key,
  });

  final TextEditingController controller;

  /// The catalog item already chosen; the suggestion list hides then.
  final Item? selected;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<Item> onSelected;
  final ValueChanged<String> onNewItem;
  final String? errorText;

  /// Restricts the suggestions to one category (the list filter sheet).
  final String? categoryId;
  final bool enabled;
  final bool autofocus;
  final String? label;
  final int maxResults;

  /// Offer "add as a new item" (off in the filter sheet).
  final bool allowNew;

  @override
  ConsumerState<ItemAutocompleteField> createState() =>
      _ItemAutocompleteFieldState();
}

class _ItemAutocompleteFieldState extends ConsumerState<ItemAutocompleteField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final index = ref.watch(catalogIndexProvider);
    final query = widget.controller.text.trim();
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final showList = widget.enabled && widget.selected == null && _focus.hasFocus;
    final results = showList
        ? index.search.search(
            query,
            categoryId: widget.categoryId,
            limit: widget.maxResults,
          )
        : const <Item>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          onChanged: widget.onTextChanged,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: widget.label ?? l10n.expenseItemLabel,
            hintText: l10n.expenseItemHint,
            errorText: widget.errorText,
            errorMaxLines: 3,
            suffixIcon: widget.selected == null
                ? null
                : const Icon(Icons.check_circle_outline),
          ),
        ),
        if (showList)
          for (final item in results)
            _ResultRow(
              item: item,
              title: item.displayName(bangla: bangla),
              subtitle: index.categoryOf(item)?.displayName(bangla: bangla),
              onTap: () => widget.onSelected(item),
            ),
        if (showList && query.isNotEmpty && widget.allowNew)
          _NewItemRow(
            label: l10n.expenseAddNewItem(query),
            onTap: () => widget.onNewItem(query),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Item item;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 48,
      contentPadding: EdgeInsets.zero,
      leading: ItemThumb(id: item.id, name: title, size: 36),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

class _NewItemRow extends StatelessWidget {
  const _NewItemRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 48,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.add_circle_outline, color: context.tokens.accent),
      title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
