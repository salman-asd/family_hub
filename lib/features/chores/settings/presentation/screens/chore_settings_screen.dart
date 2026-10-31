import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/calendar_defaults_section.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/catalog_sections.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/generation_section.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/house_rules_section.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/policies_section.dart';
import 'package:family_hub/features/family/domain/usecases/update_permission_settings.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:family_hub/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _actionProvider = newActionProvider();

/// Settings hub for the Chores module (P3-17).
///
/// Every field of [ChoreSettings] is editable here: calendar defaults,
/// generation/timing, the three catalogs (groups, due-time presets, absence
/// reasons), policies, and house rules. Nothing else in the app hard-codes
/// these values (D-P3-4).
///
/// The write is INTEGRITY (server required) so it shows "needs internet" when
/// offline (road map 3.4). The screen holds a full draft in state; a single
/// Save applies all sections in one [UpdateChoreSettings] call.
class ChoreSettingsScreen extends ConsumerStatefulWidget {
  const ChoreSettingsScreen({super.key});

  @override
  ConsumerState<ChoreSettingsScreen> createState() =>
      _ChoreSettingsScreenState();
}

class _ChoreSettingsScreenState extends ConsumerState<ChoreSettingsScreen> {
  /// Local draft of settings/chores.
  late ChoreSettings _draft;

  /// Local draft of the absence policy (settings/rotationPolicy).
  late AbsencePolicy _policy;

  /// Local draft of settings/permissions.membersCanCompleteForOthers.
  late bool _membersCanComplete;

  /// Whether we have seeded the draft from Firestore once.
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(choreSettingsProvider);
    _policy = ref.read(rotationPolicyProvider);
    _membersCanComplete =
        ref.read(permissionSettingsProvider).membersCanCompleteForOthers;

    ref.listenManual<ChoreSettings>(choreSettingsProvider, (_, next) {
      if (_loaded) return;
      setState(() {
        _draft = next;
        _loaded = true;
      });
    });
    ref.listenManual<AbsencePolicy>(rotationPolicyProvider, (_, next) {
      if (_loaded) return;
      setState(() => _policy = next);
    });
  }

  bool get _dirty {
    final s = ref.read(choreSettingsProvider);
    final p = ref.read(rotationPolicyProvider);
    final m = ref.read(permissionSettingsProvider).membersCanCompleteForOthers;
    return _draft != s || _policy != p || _membersCanComplete != m;
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.choresSettingsDiscardTitle),
        content: Text(l10n.choresSettingsDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDiscard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final familyId = ref.read(currentFamilyIdProvider);
    final uid = ref.read(currentUidProvider);
    if (familyId == null || uid == null) return;

    _loaded = true;
    final settingsUc = ref.read(updateChoreSettingsProvider);
    final policyUc = ref.read(updateRotationPolicyProvider);
    final permUc = ref.read(updatePermissionSettingsProvider);

    final currentPolicy = ref.read(rotationPolicyProvider);
    final currentPerm =
        ref.read(permissionSettingsProvider).membersCanCompleteForOthers;

    // Run all needed writes in parallel.
    final futs = <Future<Result<dynamic>>>[
      settingsUc(
        actorUid: uid,
        familyId: familyId,
        settings: _draft,
      ),
      if (_policy != currentPolicy)
        policyUc(
          actorUid: uid,
          familyId: familyId,
          policy: _policy,
        ),
      if (_membersCanComplete != currentPerm)
        permUc(
          actorUid: uid,
          familyId: familyId,
          settings: ref.read(permissionSettingsProvider).copyWith(
            membersCanCompleteForOthers: _membersCanComplete,
          ),
        ),
    ];

    final results = await Future.wait(futs);
    final failure = results.whereType<Failure<dynamic>>().firstOrNull?.failure;

    if (!mounted) return;
    if (failure != null) {
      ref.read(_actionProvider.notifier).setFailure(failure);
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.choresSettingsSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final canManage = ref.can(Permission.manageChoreTemplates);
    final action = ref.watch(_actionProvider);
    final failure = action.failure;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (ok && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.choresSettingsTitle)),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (!canManage)
              _ReadOnlyBanner(message: l10n.choresSettingsNotAllowed),
            PermissionGate(
              allowed: canManage,
              mode: PermissionGateMode.disable,
              deniedMessage: l10n.choresSettingsNotAllowed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.choresSettingsCalendarTitle,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  ),
                  CalendarDefaultsSection(
                    draft: _draft,
                    onChanged: (s) => setState(() => _draft = s),
                  ),
                  const Divider(),
                  SectionHeader(
                    title: l10n.choresSettingsGenerationTitle,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  ),
                  GenerationSection(
                    draft: _draft,
                    onChanged: (s) => setState(() => _draft = s),
                  ),
                  const Divider(),
                  SectionHeader(
                    title: l10n.choresSettingsCatalogsTitle,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  ),
                  CatalogSections(
                    draft: _draft,
                    onChanged: (s) => setState(() => _draft = s),
                  ),
                  const Divider(),
                  SectionHeader(
                    title: l10n.choresSettingsPoliciesTitle,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  ),
                  PoliciesSection(
                    draft: _draft,
                    policy: _policy,
                    membersCanCompleteForOthers: _membersCanComplete,
                    onSettingsChanged: (s) => setState(() => _draft = s),
                    onPolicyChanged: (p) => setState(() => _policy = p),
                    onCompleteForOthersChanged: (v) =>
                        setState(() => _membersCanComplete = v),
                  ),
                  const Divider(),
                  SectionHeader(
                    title: l10n.choresSettingsHouseRulesTitle,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  ),
                  HouseRulesSection(
                    houseRules: _draft.houseRules,
                    onChanged: (rules) => setState(
                      () => _draft = _draft.copyWith(houseRules: rules),
                    ),
                  ),
                ],
              ),
            ),
            if (failure != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  l10n.choresFailureMessage(failure),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: t.danger),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BusyButton(
                key: const ValueKey('chore-settings-save'),
                label: l10n.choresSettingsSave,
                busy: action.busy,
                busyLabel: l10n.loadingSemantics,
                onPressed: canManage ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: t.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A read-only card that shows house rules on the Manage hub (P3-29).
///
/// Navigates to the full settings screen when tapped. Kept here so the hub
/// and the settings screen share the route logic.
class HouseRulesCard extends ConsumerWidget {
  const HouseRulesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final settings = ref.watch(choreSettingsProvider);
    final rules = settings.houseRules.trim();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => context.push(AppRoutes.choresSettings),
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rule_folder_outlined, color: t.accentStrong),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.choresSettingsHouseRulesTitle,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: t.textPrimary),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: t.textSecondary),
                ],
              ),
              if (rules.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rules.length > 120 ? '${rules.substring(0, 120)}…' : rules,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: t.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.choresSettingsHouseRulesEmpty,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: t.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
