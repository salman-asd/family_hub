import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/controllers/catalog_controllers.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/category_edit_sheet.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every category (hidden ones dimmed and labelled), in display order.  A
/// manager can drag to reorder and tap to edit; everybody else just reads.
class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({required this.canManage, super.key});

  final bool canManage;

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab> {
  /// The order shown while a reorder is being saved.
  List<String>? _pending;

  List<Category> _ordered(Iterable<Category> all) {
    final list = all.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        final name = a.nameBn.compareTo(b.nameBn);
        return name != 0 ? name : a.id.compareTo(b.id);
      });
    final pending = _pending;
    if (pending == null) return list;
    final byId = <String, Category>{for (final c in list) c.id: c};
    return <Category>[
      for (final id in pending)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> _reorder(List<Category> current, int oldIndex, int newIndex) async {
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return;
    final ids = <String>[for (final c in current) c.id];
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    ids.insert(target, ids.removeAt(oldIndex));
    setState(() => _pending = ids);
    await ref.read(catalogListActionProvider.notifier).run<void>(
      () => ref.read(reorderCategoriesProvider)(
        actorUid: uid,
        familyId: familyId,
        orderedIds: ids,
      ),
    );
    if (mounted) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final index = ref.watch(catalogIndexProvider);
    final failure = ref.watch(catalogListActionProvider).failure;
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final categories = _ordered(index.categoriesById.values);

    if (categories.isEmpty) {
      return EmptyState(
        icon: Icons.category_outlined,
        title: l10n.catalogCategoriesEmpty,
      );
    }
    return Column(
      children: [
        if (failure != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.bazarFailureMessage(failure),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.danger),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            key: const ValueKey('categories-list'),
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: categories.length,
            onReorder: (from, to) => _reorder(categories, from, to),
            itemBuilder: (context, i) {
              final c = categories[i];
              return Opacity(
                key: ValueKey('category-${c.id}'),
                opacity: c.active ? 1 : 0.6,
                child: ListTile(
                  minTileHeight: 56,
                  onTap: widget.canManage
                      ? () => showCategoryEditSheet(context, existing: c)
                      : null,
                  title: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CategoryBadge(
                      name: c.displayName(bangla: bangla),
                      colorIndex: c.colorIndex,
                      emoji: c.emoji,
                    ),
                  ),
                  subtitle: c.active
                      ? null
                      : Row(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 14,
                              color: t.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(l10n.catalogHidden),
                          ],
                        ),
                  trailing: widget.canManage
                      ? ReorderableDragStartListener(
                          index: i,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Tooltip(
                              message: l10n.catalogReorder,
                              child: const Icon(Icons.drag_handle),
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
