import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/family/domain/relationship_catalog.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/features/family/presentation/widgets/labels.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _relationshipsActionProvider = newActionProvider();

/// `/family/relationships` (H10): the admin edits the family's relationship
/// list.  Built-ins are shown but locked; custom entries can be added, renamed
/// and disabled.  Reached only through the `editFamilySettings` gate on the
/// Family tab; the use case and the rules check the permission again.
class RelationshipsScreen extends ConsumerWidget {
  const RelationshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final catalog = ref.watch(relationshipCatalogProvider);
    final action = ref.watch(_relationshipsActionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.relationshipsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('relationship_add'),
        onPressed: () => _editDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.relationshipsAdd),
      ),
      body: catalog.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: l10n.errorUnknown,
          onRetry: () => ref.invalidate(relationshipCatalogProvider),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              l10n.relationshipsHint,
              style: TextStyle(color: t.textSecondary, fontSize: 14),
            ),
            if (action.failure != null) ...[
              const SizedBox(height: 12),
              FailureBanner(failure: action.failure!),
            ],
            const SizedBox(height: 12),
            for (final e in value.entries)
              _EntryTile(
                entry: e,
                label: l10n.relationshipIdLabel(value, e.id),
                onEdit: () => _editDialog(context, ref, entry: e),
                onToggle: () => _toggle(ref, e),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, RelationshipEntry e) async {
    final uid = ref.read(currentUidProvider);
    final familyId = ref.read(currentFamilyIdProvider);
    if (uid == null || familyId == null) return;
    await ref.read(_relationshipsActionProvider.notifier).run(
          () => ref.read(updateRelationshipCatalogProvider).setActive(
                actorUid: uid,
                familyId: familyId,
                id: e.id,
                active: !e.active,
              ),
        );
  }

  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref, {
    RelationshipEntry? entry,
  }) async {
    final l10n = context.l10n;
    final bn = TextEditingController(text: entry?.labelBn ?? '');
    final en = TextEditingController(text: entry?.labelEn ?? '');
    var spouse = entry?.spouseRelevant ?? false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(entry == null ? l10n.relationshipsAdd : l10n.actionEdit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('relationship_label_bn'),
                  controller: bn,
                  maxLength: RelationshipCatalog.maxLabelLength,
                  decoration: InputDecoration(labelText: l10n.relationshipsLabelBn),
                ),
                TextField(
                  key: const Key('relationship_label_en'),
                  controller: en,
                  maxLength: RelationshipCatalog.maxLabelLength,
                  decoration: InputDecoration(labelText: l10n.relationshipsLabelEn),
                ),
                SwitchListTile(
                  key: const Key('relationship_spouse'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.relationshipsSpouseRelevant),
                  value: spouse,
                  onChanged: (v) => setState(() => spouse = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const Key('relationship_save'),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    final labelBn = bn.text;
    final labelEn = en.text;
    bn.dispose();
    en.dispose();
    if (saved != true) return;

    final uid = ref.read(currentUidProvider);
    final familyId = ref.read(currentFamilyIdProvider);
    if (uid == null || familyId == null) return;
    final useCase = ref.read(updateRelationshipCatalogProvider);
    await ref.read(_relationshipsActionProvider.notifier).run(
          () => entry == null
              ? useCase.add(
                  actorUid: uid,
                  familyId: familyId,
                  labelBn: labelBn,
                  labelEn: labelEn,
                  spouseRelevant: spouse,
                )
              : useCase.rename(
                  actorUid: uid,
                  familyId: familyId,
                  id: entry.id,
                  labelBn: labelBn,
                  labelEn: labelEn,
                  spouseRelevant: spouse,
                ),
        );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.label,
    required this.onEdit,
    required this.onToggle,
  });

  final RelationshipEntry entry;
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final status = entry.builtIn
        ? l10n.relationshipsBuiltIn
        : (entry.active ? l10n.relationshipsActive : l10n.relationshipsDisabled);
    return Card(
      key: Key('relationship_${entry.id.value}'),
      child: ListTile(
        minVerticalPadding: 12,
        leading: Icon(
          entry.builtIn
              ? Icons.lock_outline_rounded
              : (entry.active
                  ? Icons.check_circle_outline_rounded
                  : Icons.block_rounded),
          color: t.textSecondary,
        ),
        title: Text(label),
        subtitle: Text(status),
        trailing: entry.builtIn
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.actionEdit,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: entry.active
                        ? l10n.relationshipsDisable
                        : l10n.relationshipsEnable,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: Icon(
                      entry.active
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: onToggle,
                  ),
                ],
              ),
      ),
    );
  }
}
