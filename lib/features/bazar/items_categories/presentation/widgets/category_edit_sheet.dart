import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/controllers/catalog_controllers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/color_swatch_grid.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Add (`existing == null`) or edit a category.
Future<void> showCategoryEditSheet(BuildContext context, {Category? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CategoryEditSheet(existing: existing),
    );

/// Names, palette colour, emoji and the active switch of one category.
class CategoryEditSheet extends ConsumerStatefulWidget {
  const CategoryEditSheet({this.existing, super.key});

  final Category? existing;

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _nameBn;
  late final TextEditingController _nameEn;
  late final TextEditingController _emoji;
  late int _color;
  late bool _active;
  bool _missingName = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameBn = TextEditingController(text: c?.nameBn ?? '');
    _nameEn = TextEditingController(text: c?.nameEn ?? '');
    _emoji = TextEditingController(text: c?.emoji ?? '');
    _color = c?.colorIndex ?? 0;
    _active = c?.active ?? true;
  }

  @override
  void dispose() {
    _nameBn.dispose();
    _nameEn.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameBn.text.trim().isEmpty) {
      setState(() => _missingName = true);
      return;
    }
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return;
    final existing = widget.existing;
    final saved = await ref.read(categorySheetActionProvider.notifier).run<Category>(() async {
      if (existing == null) {
        return ref.read(addCategoryProvider)(
          actorUid: uid,
          familyId: familyId,
          nameBn: _nameBn.text,
          nameEn: _nameEn.text,
          colorIndex: _color,
          emoji: _emoji.text,
        );
      }
      final updated = await ref.read(updateCategoryProvider)(
        actorUid: uid,
        familyId: familyId,
        categoryId: existing.id,
        nameBn: _nameBn.text,
        nameEn: _nameEn.text,
        colorIndex: _color,
        emoji: _emoji.text,
        imageData: existing.imageData,
      );
      if (updated.failureOrNull != null || _active == existing.active) {
        return updated;
      }
      return _active
          ? ref.read(reactivateCategoryProvider)(
              actorUid: uid,
              familyId: familyId,
              categoryId: existing.id,
            )
          : ref.read(deactivateCategoryProvider)(
              actorUid: uid,
              familyId: familyId,
              categoryId: existing.id,
            );
    });
    if (saved != null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final action = ref.watch(categorySheetActionProvider);
    final failure = action.failure;
    final editing = widget.existing != null;
    final preview = _nameBn.text.trim().isEmpty
        ? l10n.catalogCategoryName
        : _nameBn.text.trim();

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
              editing ? l10n.catalogEditCategory : l10n.catalogAddCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('category-name-bn'),
              controller: _nameBn,
              onChanged: (_) => setState(() => _missingName = false),
              decoration: InputDecoration(
                labelText: l10n.catalogNameBn,
                errorText: _missingName ? l10n.bazarErrRequired : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('category-name-en'),
              controller: _nameEn,
              decoration: InputDecoration(labelText: l10n.catalogNameEn),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('category-emoji'),
              controller: _emoji,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.catalogEmoji),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.catalogColour,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
            ),
            ColorSwatchGrid(
              selected: _color,
              onChanged: (i) => setState(() => _color = i),
              semanticLabel: l10n.catalogColourSemantics,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CategoryBadge(
                name: preview,
                colorIndex: _color,
                emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
              ),
            ),
            if (editing)
              SwitchListTile(
                key: const ValueKey('category-active'),
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
              key: const ValueKey('category-save'),
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
