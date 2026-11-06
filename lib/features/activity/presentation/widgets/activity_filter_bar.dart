import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/activity/domain/activity_filter.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:flutter/material.dart';

class ActivityFilterBar extends StatelessWidget {
  const ActivityFilterBar({
    required this.filter,
    required this.members,
    required this.onModuleChanged,
    required this.onActorChanged,
    super.key,
  });

  final ActivityFilter filter;
  final List<Member> members;
  final ValueChanged<ActivityModuleFilter> onModuleChanged;
  final ValueChanged<String?> onActorChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moduleLabel = <ActivityModuleFilter, String>{
      ActivityModuleFilter.all: l10n.activityModuleAll,
      ActivityModuleFilter.bazar: l10n.activityModuleBazar,
      ActivityModuleFilter.chores: l10n.activityModuleChores,
      ActivityModuleFilter.family: l10n.activityModuleFamily,
      ActivityModuleFilter.engagement: l10n.activityModuleEngagement,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140, maxWidth: 230),
            child: DropdownButtonFormField<ActivityModuleFilter>(
              key: const Key('activity_module_filter'),
              initialValue: filter.module,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.activityModuleFilter,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                for (final module in ActivityModuleFilter.values)
                  DropdownMenuItem(
                    value: module,
                    child: Text(
                      moduleLabel[module]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onModuleChanged(value);
              },
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
            child: DropdownButtonFormField<String>(
              key: const Key('activity_actor_filter'),
              initialValue: filter.actorId ?? '',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.activityMemberFilter,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(l10n.activityMemberAll),
                ),
                for (final member in members)
                  DropdownMenuItem(
                    value: member.uid,
                    child: Text(
                      member.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  onActorChanged(value == null || value.isEmpty ? null : value),
            ),
          ),
        ],
      ),
    );
  }
}
