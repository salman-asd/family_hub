import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/bazar_entries.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Bazar tab: one tile per feature that is switched on and permitted.
///
/// [entries] is a seam for widget tests; production reads the shared
/// [bazarEntries] list that each Phase 2 step appends to.
class BazarHomeScreen extends ConsumerWidget {
  const BazarHomeScreen({super.key, this.entries});

  final List<BazarEntry>? entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = entries ?? bazarEntries;
    final visible = <BazarEntry>[
      for (final entry in all)
        if (entry.requires == null || ref.can(entry.requires!)) entry,
    ];
    final categories = ref.watch(categoriesProvider);
    final needsSetup = categories.hasValue && categories.value!.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navBazar)),
      floatingActionButton: !needsSetup && ref.can(Permission.addOwnExpense)
          ? FloatingActionButton(
              key: const ValueKey('bazar-add-expense'),
              tooltip: l10n.expenseAddTitle,
              onPressed: () => context.go(AppRoutes.bazarExpenseNew),
              child: const Icon(Icons.add),
            )
          : null,
      body: needsSetup
          ? const _CatalogSetupView()
          : visible.isEmpty
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: l10n.bazarHomeEmptyTitle,
              message: l10n.bazarHomeEmptyMessage,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: visible.length,
              itemBuilder: (context, index) =>
                  _BazarEntryCard(entry: visible[index]),
            ),
    );
  }
}

/// The two empty-catalog states: a one-tap seed for managers, and an
/// explanation for everybody else.  Seeding is never silent (P2-06).
class _CatalogSetupView extends ConsumerWidget {
  const _CatalogSetupView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!ref.can(Permission.manageCatalogAndBudgets)) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: l10n.bazarCatalogAskAdminTitle,
        message: l10n.bazarCatalogAskAdminMessage,
      );
    }

    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          raised: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: tokens.accentStrong,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bazarCatalogSetupTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bazarCatalogSetupMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              const _SeedCatalogButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeedCatalogButton extends ConsumerStatefulWidget {
  const _SeedCatalogButton();

  @override
  ConsumerState<_SeedCatalogButton> createState() => _SeedCatalogButtonState();
}

class _SeedCatalogButtonState extends ConsumerState<_SeedCatalogButton> {
  bool _busy = false;
  AppFailure? _failure;

  Future<void> _seed() async {
    final familyId = ref.read(currentFamilyIdProvider);
    final actorUid = ref.read(currentUidProvider);
    if (familyId == null || actorUid == null) {
      setState(() => _failure = const PermissionDenied());
      return;
    }

    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(ensureCatalogSeededProvider)(
      actorUid: actorUid,
      familyId: familyId,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = result.failureOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    return Column(
      children: [
        BusyButton(
          label: l10n.bazarCatalogSetupAction,
          busy: _busy,
          busyLabel: l10n.bazarCatalogSetupBusy,
          onPressed: _seed,
        ),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.bazarFailureMessage(failure),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.tokens.danger),
            ),
          ),
      ],
    );
  }
}

class _BazarEntryCard extends StatelessWidget {
  const _BazarEntryCard({required this.entry});

  final BazarEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.go(entry.route),
      child: Row(
        children: [
          Icon(entry.icon, color: tokens.accentStrong),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              entry.label(l10n),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: tokens.textPrimary),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
        ],
      ),
    );
  }
}
