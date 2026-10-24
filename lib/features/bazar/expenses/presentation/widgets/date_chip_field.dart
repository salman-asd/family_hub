import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The date of an entry as a tappable chip; the picker never goes past today.
class DateChipField extends ConsumerWidget {
  const DateChipField({
    required this.date,
    required this.enabled,
    required this.onPicked,
    this.errorText,
    super.key,
  });

  final DateKey date;
  final bool enabled;
  final ValueChanged<DateKey> onPicked;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final today = ref.watch(currentDateKeyProvider);
    final formatters = ref.watch(appFormattersProvider);
    final label = formatters.fullDate(
      DateTime(date.year, date.month, date.day),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '${l10n.expenseDateLabel}: $label',
          excludeSemantics: true,
          child: ActionChip(
            key: const ValueKey('date-chip'),
            avatar: const Icon(Icons.event_outlined, size: 18),
            label: Text(label),
            onPressed: enabled ? () => _pick(context, today) : null,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.danger),
            ),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, DateKey today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(date.year, date.month, date.day),
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) {
      onPicked(DateKey(picked.year, picked.month, picked.day));
    }
  }
}
