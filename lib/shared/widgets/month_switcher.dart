import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "‹ October 2026 ›": steps through months with two 48dp arrows; tapping the
/// label opens a month picker.
///
/// [min] and [max] bound the selectable months (inclusive); an arrow that would
/// leave the range is disabled, not hidden, so the layout never jumps.  The
/// widget holds no state: the caller owns [month] and reacts to [onChanged].
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({
    required this.month,
    required this.onChanged,
    this.min,
    this.max,
    super.key,
  });

  final MonthKey month;
  final ValueChanged<MonthKey> onChanged;
  final MonthKey? min;
  final MonthKey? max;

  bool get _canGoBack => min == null || month.compareTo(min!) > 0;

  bool get _canGoForward => max == null || month.compareTo(max!) < 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final label = ref.watch(appFormattersProvider).monthLabel(month);

    return Row(
      children: [
        IconButton(
          tooltip: l10n.monthSwitcherPrevious,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _canGoBack ? () => onChanged(month.addMonths(-1)) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Semantics(
            button: true,
            label: '${l10n.monthSwitcherPick}: $label',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(t.radiusSm),
              onTap: () => _pick(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.monthSwitcherNext,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _canGoForward ? () => onChanged(month.addMonths(1)) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<MonthKey>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _MonthPickerSheet(month: month, min: min, max: max),
    );
    if (picked != null && picked != month) onChanged(picked);
  }
}

class _MonthPickerSheet extends ConsumerStatefulWidget {
  const _MonthPickerSheet({required this.month, this.min, this.max});

  final MonthKey month;
  final MonthKey? min;
  final MonthKey? max;

  @override
  ConsumerState<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends ConsumerState<_MonthPickerSheet> {
  late int _year = widget.month.year;

  bool _selectable(MonthKey m) =>
      (widget.min == null || m.compareTo(widget.min!) >= 0) &&
      (widget.max == null || m.compareTo(widget.max!) <= 0);

  bool get _canPreviousYear =>
      widget.min == null || _year > widget.min!.year;

  bool get _canNextYear => widget.max == null || _year < widget.max!.year;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.monthPickerPreviousYear,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: _canPreviousYear
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    formatters.number(_year).replaceAll(',', ''),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.monthPickerNextYear,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: _canNextYear
                      ? () => setState(() => _year++)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var m = 1; m <= 12; m++)
                  ChoiceChip(
                    label: Text(formatters.monthName(m)),
                    selected:
                        widget.month.year == _year && widget.month.month == m,
                    onSelected: _selectable(MonthKey(_year, m))
                        ? (_) => Navigator.of(context).pop(MonthKey(_year, m))
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
