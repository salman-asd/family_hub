import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/templates/domain/template_saved.dart';
import 'package:flutter/material.dart';

/// Asks what an edit should do to chores that are already planned (D-P3-23):
/// change only future ones (the default), or also rewrite the upcoming ones
/// nobody has started. Returns null when the user backs out.
Future<ReplanScope?> showReplanScopeDialog(BuildContext context) =>
    showDialog<ReplanScope>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SimpleDialog(
          title: Text(l10n.choreReplanTitle),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l10n.choreReplanMessage),
            ),
            SimpleDialogOption(
              key: const ValueKey<String>('replan_future_only'),
              onPressed: () => Navigator.of(ctx).pop(ReplanScope.futureOnly),
              child: Text(l10n.choreReplanFutureOnly),
            ),
            SimpleDialogOption(
              key: const ValueKey<String>('replan_include_upcoming'),
              onPressed: () =>
                  Navigator.of(ctx).pop(ReplanScope.includeUpcoming),
              child: Text(l10n.choreReplanIncludeUpcoming),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.actionCancel),
            ),
          ],
        );
      },
    );
