import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/unit_labels.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_validation.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/controllers/catalog_controllers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/alias_editor.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Add (`existing == null`) or edit an item.  [initialCategoryId] preselects
/// the category when the manager added from a filtered list.
Future<void> showItemEditSheet(
  BuildContext context, {
  Item? existing,
  String? initialCategoryId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      ItemEditSheet(existing: existing, initialCategoryId: initialCategoryId),
);

/// Names, category, default unit, aliases, emoji and the active switch.
/// (No image upload in Phase 2: D-P2-13.)
class ItemEditSheet extends ConsumerStatefulWidget {
  const ItemEditSheet({this.existing, this.initialCategoryId, super.key});

  final Item? existing;
  final String? initialCategoryId;

  @override
  ConsumerState<ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends ConsumerState<ItemEditSheet> {
  late final TextEditingController _nameBn;
  late final TextEditingController _nameEn;
  late final TextEditingController _emoji;
  final TextEditingController _alias = TextEditingController();
  late List<String> _aliases;
  String? _categoryId;
  late Unit _unit;
  late bool _active;
  String? _nameError;
  String? _categoryError;
  String? _aliasError;

  @override
  void initState() {
    super.initState();
    final i = widget.existing;
    _nameBn = TextEditingController(text: i?.nameBn ?? '');
    _nameEn = TextEditingController(text: i?.nameEn ?? '');
    _emoji = TextEditingController(text: i?.emoji ?? '');
    _aliases = <String>[...?i?.aliases];
    _categoryId = i?.categoryId ?? widget.initialCategoryId;
    _unit = i?.defaultUnit ?? Unit.piece;
    _active = i?.active ?? true;
  }

  @override
  void dispose() {
    _nameBn.dispose();
    _nameEn.dispose();
    _emoji.dispose();
    _alias.dispose();
    super.dispose();
  }

  void _addAlias() {
    final l10n = context.l10n;
    final text = _alias.text.trim();
    if (text.isEmpty) return;
    if (_aliases.length >= maxCatalogAliases) {
      setState(() => _aliasError = l10n.catalogAliasLimit);
      return;
    }
    if (text.runes.length > maxCatalogAliasLength) {
      setState(() => _aliasError = l10n.bazarErrTooLong);
      return;
    }
    setState(() {
      if (!_aliases.contains(text)) _aliases = <String>[..._aliases, text];
      _alias.clear();
      _aliasError = null;
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final nameMissing = _nameBn.text.trim().isEmpty;
    final categoryMissing = (_categoryId ?? '').isEmpty;
    if (nameMissing || categoryMissing) {
      setState(() {
        _nameError = nameMissing ? l10n.bazarErrRequired : null;
        _categoryError = categoryMissing ? l10n.bazarErrCategoryRequired : null;
      });
      return;
    }
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return;
    final existing = widget.existing;
    final saved = await ref.read(itemSheetActionProvider.notifier).run<Item>(
      () async {
        if (existing == null) {
          return ref.read(addItemProvider)(
            actorUid: uid,
            familyId: familyId,
            nameBn: _nameBn.text,
            nameEn: _nameEn.text,
            categoryId: _categoryId!,
            defaultUnit: _unit,
            aliases: _aliases,
            emoji: _emoji.text,
          );
        }
        final updated = await ref.read(updateItemProvider)(
          actorUid: uid,
          familyId: familyId,
          itemId: existing.id,
          nameBn: _nameBn.text,
          nameEn: _nameEn.text,
          categoryId: _categoryId!,
          defaultUnit: _unit,
          aliases: _aliases,
          emoji: _emoji.text,
          imageData: existing.imageData,
        );
        if (updated.failureOrNull != null || _active == existing.active) {
          return updated;
        }
        return _active
            ? ref.read(reactivateItemProvider)(
                actorUid: uid,
                familyId: familyId,
                itemId: existing.id,
              )
            : ref.read(deactivateItemProvider)(
                actorUid: uid,
                familyId: familyId,
                itemId: existing.id,
              );
      },
    );
    if (saved != null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final action = ref.watch(itemSheetActionProvider);
    final failure = action.failure;
    final index = ref.watch(catalogIndexProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final editing = widget.existing != null;
    final label = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: t.textSecondary);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? l10n.catalogEditItem : l10n.catalogAddItem,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('item-name-bn'),
              controller: _nameBn,
              onChanged: (_) => setState(() => _nameError = null),
              decoration: InputDecoration(
                labelText: l10n.catalogNameBn,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('item-name-en'),
              controller: _nameEn,
              decoration: InputDecoration(labelText: l10n.catalogNameEn),
            ),
            const SizedBox(height: 16),
            Text(l10n.expenseCategoryLabel, style: label),
            const SizedBox(height: 8),
            ChoiceWrap<String>(
              selected: _categoryId,
              onChanged: (id) => setState(() {
                _categoryId = id;
                _categoryError = null;
              }),
              options: [
                for (final c in index.activeCategories)
                  ChoiceOption(c.id, c.displayName(bangla: bangla)),
              ],
            ),
            if (_categoryError != null)
              Text(
                _categoryError!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.danger),
              ),
            const SizedBox(height: 16),
            Text(l10n.catalogDefaultUnit, style: label),
            const SizedBox(height: 8),
            ChoiceWrap<Unit>(
              selected: _unit,
              onChanged: (u) => setState(() => _unit = u),
              options: [
                for (final u in Unit.values) ChoiceOption(u, l10n.unitLabel(u)),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.catalogAliases, style: label),
            const SizedBox(height: 8),
            AliasEditor(
              aliases: _aliases,
              controller: _alias,
              errorText: _aliasError,
              onAdd: _addAlias,
              onRemove: (alias) => setState(
                () => _aliases = <String>[
                  for (final a in _aliases)
                    if (a != alias) a,
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('item-emoji'),
              controller: _emoji,
              decoration: InputDecoration(labelText: l10n.catalogEmoji),
            ),
            if (editing)
              SwitchListTile(
                key: const ValueKey('item-active'),
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: Text(l10n.catalogActive),
                subtitle: Text(l10n.catalogActiveHint),
              ),
            if (failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.bazarFailureMessage(failure),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: t.danger),
                ),
              ),
            const SizedBox(height: 16),
            BusyButton(
              key: const ValueKey('item-save'),
              label: l10n.actionSave,
              busy: action.busy,
              busyLabel: l10n.loadingSemantics,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
