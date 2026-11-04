import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/rota/domain/workload_summary.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One member's share of the load (P3-28): avatar, name, a bar AND the number
/// beside it, then the counts in words (chores, done, covers, days away).
class MemberShareRow extends ConsumerWidget {
  const MemberShareRow({
    required this.workload,
    required this.name,
    this.avatarKey,
    super.key,
  });

  final MemberWorkload workload;
  final String name;
  final String? avatarKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final f = ref.watch(appFormattersProvider);
    final percent = f.number((workload.share * 100).round());
    final lines = <String>[
      l10n.rotaMemberStats(f.number(workload.assigned), f.number(workload.done)),
      if (workload.coversGiven > 0 || workload.coversReceived > 0)
        l10n.rotaCovers(
          f.number(workload.coversGiven),
          f.number(workload.coversReceived),
        ),
      if (workload.unavailableDays > 0)
        l10n.rotaAway(f.number(workload.unavailableDays)),
    ];
    return Semantics(
      container: true,
      label: '$name, ${l10n.rotaShareValue(percent)}, ${lines.join(', ')}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AppAvatar(id: workload.memberId, name: name, avatarKey: avatarKey, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        l10n.rotaShareValue(percent),
                        key: Key('rota_share_${workload.memberId}'),
                        style: TextStyle(color: t.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: workload.share.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: t.surfaceSunken,
                    color: t.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lines.join(' · '),
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
