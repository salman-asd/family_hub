import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_access_controller.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_card_labels.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_policy_card.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:family_hub/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardAccessScreen extends ConsumerStatefulWidget {
  const DashboardAccessScreen({super.key});

  @override
  ConsumerState<DashboardAccessScreen> createState() =>
      _DashboardAccessScreenState();
}

class _DashboardAccessScreenState extends ConsumerState<DashboardAccessScreen> {
  DashboardPolicy? _draft;
  Role _previewRole = Role.member;
  bool _saving = false;
  bool _offline = false;

  bool _isDirty(DashboardPolicy policy) => _draft != null && _draft != policy;

  void _setAccess(Role role, String cardId, CardAccess access) {
    final draft = _draft;
    if (draft == null) return;
    final roles = <Role, Map<String, CardAccess>>{
      for (final entry in draft.roles.entries)
        entry.key: Map<String, CardAccess>.of(entry.value),
    };
    (roles[role] ??= <String, CardAccess>{})[cardId] = access;
    setState(
      () => _draft = DashboardPolicy(roles: roles, version: draft.version),
    );
  }

  Future<void> _save(String familyId) async {
    final draft = _draft;
    final uid = ref.read(currentUidProvider);
    if (_saving || draft == null || uid == null) return;
    setState(() {
      _saving = true;
      _offline = false;
    });
    final result = await ref
        .read(dashboardAccessControllerProvider)
        .save(actorUid: uid, familyId: familyId, policy: draft);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure == null) {
      setState(() {
        _draft = result.valueOrNull;
        _saving = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
      return;
    }
    setState(() {
      _saving = false;
      _offline = failure is Network;
    });
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure is Network
                ? l10n.dashboardAccessOffline
                : l10n.errorUnknown,
          ),
        ),
      );
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.dashboardDiscardTitle),
            content: Text(l10n.dashboardDiscardMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.dashboardDiscard),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _resetRecommended() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dashboardResetRecommendedTitle),
        content: Text(l10n.dashboardResetRecommendedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dashboardResetRecommended),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _draft = DashboardPolicy(version: _draft?.version ?? 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final familyId = ref.watch(currentFamilyIdProvider);
    final canManage = ref.can(Permission.manageDashboardLayout);
    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardAccess)),
        body: Center(child: Text(l10n.errorUnknown)),
      );
    }
    final policy = ref.watch(dashboardPolicyProvider(familyId));
    final current = policy.value;
    if (current != null &&
        (_draft == null || (!_saving && !_isDirty(current)))) {
      _draft ??= current;
      if (_draft!.version != current.version && !_isDirty(current)) {
        _draft = current;
      }
    }
    final draft = _draft;
    return PermissionGate(
      allowed: canManage,
      mode: PermissionGateMode.disable,
      deniedMessage: l10n.dashboardAccessDenied,
      child: PopScope<void>(
        canPop: !(_isDirty(current ?? DashboardPolicy.defaults) || _saving),
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop &&
              !_saving &&
              _isDirty(current ?? DashboardPolicy.defaults) &&
              await _confirmDiscard() &&
              context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.dashboardAccess)),
          body: Column(
            children: [
              SyncBanner(pendingWrites: _offline ? 1 : 0, offline: _offline),
              Expanded(
                child: policy.when(
                  loading: () => const LoadingView(),
                  error: (_, _) => ErrorView(
                    message: l10n.errorUnknown,
                    onRetry: () =>
                        ref.invalidate(dashboardPolicyProvider(familyId)),
                  ),
                  data: (value) =>
                      draft == null ? const LoadingView() : _content(draft),
                ),
              ),
              _saveBar(familyId, draft, current),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(DashboardPolicy draft) {
    final l10n = context.l10n;
    final settings = ref.watch(permissionSettingsProvider);
    final flags = ref.watch(moduleFlagsProvider);
    final modules = <String, bool>{
      'bazar': flags.isEnabled('bazar'),
      'chores': flags.isEnabled('chores'),
    };
    final preview = DashboardAccessController.preview(
      role: _previewRole,
      policy: draft,
      modulesEnabled: modules,
      settings: settings,
    );
    final previewIds = preview.visible
        .map((card) => card.definition.id)
        .toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.dashboardAccessInfo),
        const SizedBox(height: 16),
        Text(l10n.dashboardAdminAlways),
        const SizedBox(height: 12),
        for (final card in CardCatalog.cards)
          DashboardPolicyCard(
            cardId: card.id,
            policy: draft,
            settings: settings,
            busy: _saving,
            onAccessChanged: _setAccess,
          ),
        const SizedBox(height: 24),
        Text(
          l10n.dashboardPreviewTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<Role>(
          segments: [
            ButtonSegment<Role>(
              value: Role.moderator,
              label: Text(l10n.roleModerator),
            ),
            ButtonSegment<Role>(
              value: Role.member,
              label: Text(l10n.roleMember),
            ),
          ],
          selected: <Role>{_previewRole},
          onSelectionChanged: (roles) =>
              setState(() => _previewRole = roles.first),
        ),
        const SizedBox(height: 12),
        if (previewIds.isEmpty)
          Text(l10n.dashboardPreviewEmpty)
        else
          for (final card in preview.visible)
            ListTile(
              key: Key('dashboard_preview_${card.definition.id}'),
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(dashboardCardTitle(l10n, card.definition.id)),
            ),
      ],
    );
  }

  Widget _saveBar(
    String familyId,
    DashboardPolicy? draft,
    DashboardPolicy? current,
  ) {
    final l10n = context.l10n;
    final dirty = draft != null && current != null && draft != current;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _saving ? null : _resetRecommended,
              child: Text(l10n.dashboardResetRecommended),
            ),
            FilledButton(
              key: const Key('dashboard_access_save'),
              onPressed: dirty && !_saving ? () => _save(familyId) : null,
              child: Text(_saving ? l10n.dashboardSaving : l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
