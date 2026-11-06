import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/presentation/chores_failure_messages.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_repository.dart';
import 'package:family_hub/features/chores/templates/presentation/template_labels.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/chores/templates/presentation/template_status_filter.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/template_list_row.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

part 'template_list_screen_parts.dart';

/// All chore templates, grouped by chore group (P3-16).
///
/// Groups collapse; the search box matches both names; the chips filter by
/// Active / Paused / Archived. A manager swipes a row for Pause/Resume,
/// Duplicate and Archive (the same three actions are on the row's long-press
/// sheet, because TalkBack has no swipe), and has a "New chore" button.
class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  String _query = '';
  TemplateStatusFilter _filter = TemplateStatusFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stream = ref.watch(templatesStreamProvider);
    final canManage = ref.can(Permission.manageChoreTemplates);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.choreTemplatesTitle)),
      floatingActionButton: PermissionGate(
        allowed: canManage,
        child: FloatingActionButton.extended(
          key: const ValueKey<String>('template_new'),
          onPressed: () => context.push(AppRoutes.choresTemplateNew),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.choreListNew),
        ),
      ),
      body: stream.when(
        loading: () => const LoadingView(lines: 5),
        error: (_, _) => ErrorView(
          message: l10n.choresFailure_unknown,
          onRetry: () => ref.invalidate(templatesStreamProvider),
          retryLabel: l10n.actionRetry,
        ),
        data: (_) => _content(context, canManage),
      ),
    );
  }

  Widget _content(BuildContext context, bool canManage) {
    final l10n = context.l10n;
    final records = ref.watch(templatesProvider);
    final catalogs = ref.watch(choreCatalogsProvider);
    final formatters = ref.watch(appFormattersProvider);
    final today = ref.watch(familyDateKeysProvider).today();
    final truncated = ref.watch(templatesTruncatedProvider);

    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: l10n.choreListEmptyTitle,
        message: l10n.choreListEmptyMessage,
      );
    }

    final q = _query.trim().toLowerCase();
    final shown = <TemplateRecord>[
      for (final r in records)
        if (_filter.matches(r.template) &&
            (q.isEmpty ||
                r.template.draft.nameBn.toLowerCase().contains(q) ||
                (r.template.draft.nameEn ?? '').toLowerCase().contains(q)))
          r,
    ];
    // Group order follows the settings catalog; an unknown group id falls
    // back to the "other" group (`groupOf`).
    final byGroup = <String, List<TemplateRecord>>{};
    for (final r in shown) {
      byGroup
          .putIfAbsent(catalogs.groupOf(r.template.draft.groupId).id, () => [])
          .add(r);
    }
    final invalid = ref.watch(invalidScheduleIdsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        TextField(
          key: const ValueKey<String>('template_search'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: l10n.choreListSearch,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        ChoiceWrap<TemplateStatusFilter>(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
          options: [
            for (final f in TemplateStatusFilter.values)
              ChoiceOption<TemplateStatusFilter>(
                f,
                _filterLabel(context, f),
                key: ValueKey<String>('filter_${f.name}'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (truncated)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.choreListTruncated),
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              l10n.choreListEmptyFiltered,
              textAlign: TextAlign.center,
            ),
          ),
        for (final group in catalogs.groups)
          if (byGroup[group.id] case final rows?)
            _GroupSection(
              group: group,
              rows: rows,
              canManage: canManage,
              today: today,
              formatters: formatters,
              invalid: invalid,
              onAction: _run,
            ),
      ],
    );
  }

  String _filterLabel(BuildContext context, TemplateStatusFilter f) =>
      switch (f) {
        TemplateStatusFilter.active => context.l10n.choreStatusActive,
        TemplateStatusFilter.paused => context.l10n.choreStatusPaused,
        TemplateStatusFilter.archived => context.l10n.choreStatusArchived,
      };

  /// Runs one row action and reports a failure in a snackbar.
  Future<void> _run(TemplateRowAction action, ChoreTemplate template) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(currentUidProvider);
    final familyId = ref.read(currentFamilyIdProvider);
    if (uid == null || familyId == null) return;

    if (action == TemplateRowAction.archive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.choreArchiveConfirmTitle),
          content: Text(l10n.choreArchiveConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const ValueKey<String>('archive_confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.choreActionArchive),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final Result<ChoreTemplate> result = switch (action) {
      TemplateRowAction.pause => await ref.read(pauseTemplateProvider)(
        actorUid: uid,
        familyId: familyId,
        templateId: template.id,
      ),
      TemplateRowAction.resume => await ref.read(resumeTemplateProvider)(
        actorUid: uid,
        familyId: familyId,
        templateId: template.id,
      ),
      TemplateRowAction.archive => await ref.read(archiveTemplateProvider)(
        actorUid: uid,
        familyId: familyId,
        templateId: template.id,
      ),
      TemplateRowAction.duplicate => await ref.read(duplicateTemplateProvider)(
        actorUid: uid,
        familyId: familyId,
        templateId: template.id,
        nameSuffix: l10n.choreDuplicateSuffix,
      ),
    };
    final failure = result.failureOrNull;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure != null
                ? l10n.choresFailureMessage(failure)
                : (action == TemplateRowAction.duplicate
                      ? l10n.choreDuplicated
                      : l10n.choreListUpdated),
          ),
        ),
      );
  }
}

/// What a manager can do to a template from the list.
enum TemplateRowAction { pause, resume, duplicate, archive }
