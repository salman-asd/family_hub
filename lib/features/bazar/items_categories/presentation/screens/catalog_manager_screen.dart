import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/categories_tab.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/category_edit_sheet.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/item_edit_sheet.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/widgets/items_tab.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Categories and items (`/bazar/catalog`).  Everybody can read it; only
/// people with `manageCatalogAndBudgets` can change anything.
class CatalogManagerScreen extends ConsumerStatefulWidget {
  const CatalogManagerScreen({super.key});

  @override
  ConsumerState<CatalogManagerScreen> createState() =>
      _CatalogManagerScreenState();
}

class _CatalogManagerScreenState extends ConsumerState<CatalogManagerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  final GlobalKey<ItemsTabState> _itemsKey = GlobalKey<ItemsTabState>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _add() {
    if (_tabs.index == 0) {
      showCategoryEditSheet(context);
    } else {
      showItemEditSheet(
        context,
        initialCategoryId: _itemsKey.currentState?.categoryId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final canManage = ref.can(Permission.manageCatalogAndBudgets);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.catalogTabCategories),
            Tab(text: l10n.catalogTabItems),
          ],
        ),
      ),
      floatingActionButton: PermissionGate(
        allowed: canManage,
        child: FloatingActionButton(
          key: const ValueKey('catalog-add'),
          tooltip: l10n.catalogAdd,
          onPressed: _add,
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          if (!canManage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FormBanner(
                icon: Icons.lock_outline,
                text: l10n.catalogReadOnly,
                color: t.textSecondary,
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                CategoriesTab(canManage: canManage),
                ItemsTab(key: _itemsKey, canManage: canManage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
