import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// The five statuses a chip can represent (roadmap 5.3).
///
/// [overdue] is a *derived* state in the domain; here it is just a visual
/// choice so the chip can render it without importing a feature.
enum WidgetStatus { scheduled, inProgress, completed, verified, overdue }

/// A compact, accessible status badge: icon + label + colour, so status is
/// never conveyed by colour alone (CLAUDE.md rule 13).
///
/// Colours come from [AppTokens]; the label is localized by the caller via
/// [label] or, when omitted, resolved from [status] through [AppLocalizations].
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.status,
    this.label,
    this.compact = false,
    super.key,
  });

  final WidgetStatus status;

  /// Overrides the default localized label (for example "2 of 3" for a
  /// partially-completed task).
  final String? label;

  /// Dense variant for list rows and calendar cells.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = label ?? _defaultLabel(context.l10n);
    final colors = _colors(t);

    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(t.radiusPill),
          border: Border.all(color: colors.foreground.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: compact ? 12 : 14,
              color: colors.foreground,
            ),
            SizedBox(width: compact ? 4 : 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (status) {
        WidgetStatus.scheduled => Icons.schedule_rounded,
        WidgetStatus.inProgress => Icons.timelapse_rounded,
        WidgetStatus.completed => Icons.check_circle_outline_rounded,
        WidgetStatus.verified => Icons.verified_rounded,
        WidgetStatus.overdue => Icons.warning_amber_rounded,
      };

  String _defaultLabel(AppLocalizations l10n) => switch (status) {
        WidgetStatus.scheduled => l10n.statusScheduled,
        WidgetStatus.inProgress => l10n.statusInProgress,
        WidgetStatus.completed => l10n.statusCompleted,
        WidgetStatus.verified => l10n.statusVerified,
        WidgetStatus.overdue => l10n.statusOverdue,
      };

  _StatusColors _colors(AppTokens t) => switch (status) {
        WidgetStatus.scheduled => _StatusColors(
            t.statusScheduledContainer,
            t.statusScheduledOn,
          ),
        WidgetStatus.inProgress => _StatusColors(
            t.statusInProgressContainer,
            t.statusInProgressOn,
          ),
        WidgetStatus.completed => _StatusColors(
            t.statusCompletedContainer,
            t.statusCompletedOn,
          ),
        WidgetStatus.verified => _StatusColors(
            t.statusVerifiedContainer,
            t.statusVerifiedOn,
          ),
        WidgetStatus.overdue => _StatusColors(
            t.statusOverdueContainer,
            t.statusOverdueOn,
          ),
      };
}

class _StatusColors {
  const _StatusColors(this.container, this.foreground);
  final Color container;
  final Color foreground;
}
