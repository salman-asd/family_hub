import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/features/dashboard/presentation/customize_dashboard_controller.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_card_labels.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/reorderable_card_tile.dart';
import 'package:family_hub/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomizeDashboardScreen extends ConsumerStatefulWidget {
  const CustomizeDashboardScreen({super.key});

  @override
  ConsumerState<CustomizeDashboardScreen> createState() =>
      _CustomizeDashboardScreenState();
}

class _CustomizeDashboardScreenState
    extends ConsumerState<CustomizeDashboardScreen> {
  bool _saving = false;
  bool _offline = false;

  Future<void> _save(DashboardPrefs next) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _offline = false;
    });
    final result = await ref
        .read(customizeDashboardControllerProvider)
        .save(next);
    if (!mounted) return;
    final failure = result.failureOrNull;
    setState(() {
      _saving = false;
      _offline = failure is Network;
    });
    if (failure != null) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              failure is Network
                  ? l10n.dashboardPrefsSyncPending
                  : l10n.errorUnknown,
            ),
          ),
        );
    }
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dashboardResetTitle),
        content: Text(l10n.dashboardResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('dashboard_reset_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dashboardReset),
          ),
        ],
      ),
    );
    if (confirmed == true) await _save(DashboardPrefs.defaults);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final layout = ref.watch(dashboardLayoutProvider);
    final prefs = ref.watch(dashboardPrefsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardCustomize),
        actions: [
          IconButton(
            tooltip: l10n.dashboardReset,
            onPressed: _saving ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          SyncBanner(pendingWrites: _offline ? 1 : 0, offline: _offline),
          Expanded(
            child: layout.when(
              loading: () => const LoadingView(),
              error: (_, _) => ErrorView(
                message: l10n.errorUnknown,
                onRetry: () => ref.invalidate(dashboardLayoutProvider),
              ),
              data: (value) => _content(value, prefs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(DashboardLayout layout, DashboardPrefs prefs) {
    final l10n = context.l10n;
    final visible = layout.visible;
    final hidden = layout.optionalHidden;
    final controller = ref.read(customizeDashboardControllerProvider);
    final visibleIds = <String>[for (final card in visible) card.definition.id];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.dashboardPersonalLayoutNote),
        const SizedBox(height: 12),
        if (visible.isNotEmpty)
          ReorderableListView.builder(
            key: const Key('dashboard_visible_cards'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: visible.length,
            onReorderItem: _saving
                ? (_, _) {}
                : (oldIndex, newIndex) => _save(
                    controller.reorder(prefs, visibleIds, oldIndex, newIndex),
                  ),
            itemBuilder: (context, index) {
              final card = visible[index];
              final id = card.definition.id;
              final required = card.access == CardAccess.required;
              return Padding(
                key: ValueKey<String>('dashboard_card_$id'),
                padding: const EdgeInsets.only(bottom: 8),
                child: ReorderableCardTile(
                  index: index,
                  title: dashboardCardTitle(l10n, id),
                  dragLabel: l10n.dashboardDragCard(
                    dashboardCardTitle(l10n, id),
                  ),
                  moveUpLabel: l10n.dashboardMoveUp,
                  moveDownLabel: l10n.dashboardMoveDown,
                  value: required ? null : true,
                  onChanged: required || _saving
                      ? null
                      : (value) => _save(
                          controller.setVisibility(
                            prefs,
                            id,
                            value,
                            card.access,
                          ),
                        ),
                  locked: required,
                  lockedReason: required ? l10n.dashboardRequired : null,
                  onMoveUp: !_saving && index > 0
                      ? () =>
                            _save(controller.move(prefs, visibleIds, index, -1))
                      : null,
                  onMoveDown: !_saving && index < visible.length - 1
                      ? () =>
                            _save(controller.move(prefs, visibleIds, index, 1))
                      : null,
                ),
              );
            },
          ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              icon: Icons.dashboard_customize_outlined,
              title: l10n.dashboardEmptyTitle,
              message: l10n.dashboardEmptyMessage,
            ),
          ),
        if (hidden.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.dashboardHiddenCards,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final card in hidden)
            ListTile(
              key: Key('dashboard_hidden_${card.definition.id}'),
              title: Text(dashboardCardTitle(l10n, card.definition.id)),
              trailing: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => _save(
                        controller.setVisibility(
                          prefs,
                          card.definition.id,
                          true,
                          card.access,
                        ),
                      ),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.dashboardAddBack),
              ),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _saving ? null : _reset,
          child: Text(l10n.dashboardReset),
        ),
      ],
    );
  }
}
