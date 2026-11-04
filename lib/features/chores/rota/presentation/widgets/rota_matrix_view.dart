import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/presentation/date_of_key.dart';
import 'package:family_hub/features/chores/presentation/member_names.dart';
import 'package:family_hub/features/chores/rota/domain/rota_matrix.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Members by days (P3-28). A cell shows the number of chores and, when all of
/// them are finished, a check icon: number + icon + a semantic label, never
/// colour alone. The grid scrolls sideways inside its own box; cells are 48dp.
class RotaMatrixView extends ConsumerWidget {
  const RotaMatrixView({
    required this.matrix,
    required this.memberIds,
    required this.members,
    required this.today,
    super.key,
  });

  final RotaMatrix matrix;
  final List<String> memberIds;
  final List<Member> members;
  final DateKey today;

  static const double _cell = 48;
  static const double _nameWidth = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final f = ref.watch(appFormattersProvider);
    return SingleChildScrollView(
      key: const Key('rota_matrix'),
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: _nameWidth),
              for (final day in matrix.days)
                SizedBox(
                  width: _cell,
                  height: _cell,
                  child: Center(
                    child: Text(
                      f.number(day.day),
                      style: TextStyle(
                        color: t.textSecondary,
                        fontWeight: day == today ? FontWeight.w800 : FontWeight.w400,
                        decoration: day == today ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final id in memberIds)
            Row(
              children: [
                SizedBox(
                  width: _nameWidth,
                  height: _cell,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      memberNameOf(members, id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                for (final day in matrix.days) _cellFor(context, l10n, f, id, day),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cellFor(
    BuildContext context,
    AppLocalizations l10n,
    AppFormatters f,
    String id,
    DateKey day,
  ) {
    final t = context.tokens;
    final count = matrix.cell(id, day).length;
    final done = matrix.isDone(id, day);
    final name = memberNameOf(members, id);
    return Semantics(
      label: l10n.rotaCellLabel(
        name,
        f.fullDate(dateOfKey(day)),
        f.number(count),
      ),
      excludeSemantics: true,
      child: SizedBox(
        width: _cell,
        height: _cell,
        child: count == 0
            ? null
            : Center(
                child: Container(
                  key: Key('rota_cell_${id}_${day.toString()}'),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: done ? t.statusCompletedContainer : t.surfaceRaised,
                    borderRadius: BorderRadius.circular(t.radiusSm),
                    border: Border.all(color: t.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (done) const Icon(Icons.check_rounded, size: 12),
                      Text(f.number(count), style: TextStyle(color: t.textPrimary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
