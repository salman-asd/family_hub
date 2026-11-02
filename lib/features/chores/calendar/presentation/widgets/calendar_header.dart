import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_motion.dart';
import 'package:flutter/material.dart';

/// The month title, the previous / next arrows and the Today pill (B.2).
///
/// Tapping the title opens the month and year picker. The Today pill is only
/// there while the person is away from today ([showToday]). Wraps instead of
/// overflowing at large text.
class CalendarHeader extends StatelessWidget {
  const CalendarHeader({
    required this.title,
    required this.showToday,
    required this.showArrows,
    required this.previousLabel,
    required this.nextLabel,
    required this.onTitle,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    super.key,
  });

  final String title;
  final bool showToday;

  /// The agenda scrolls, so it has no previous / next.
  final bool showArrows;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback onTitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Semantics(
          button: true,
          label: '$title, ${l10n.calendarPickMonth}',
          excludeSemantics: true,
          child: InkWell(
            key: const Key('calendar_title'),
            onTap: onTitle,
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: t.textSecondary),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The pill slides in from the side and out again (B.5); with
            // reduced motion the duration is zero and it just appears.
            AnimatedSwitcher(
              duration: calendarMotion(context),
              switchInCurve: kCalendarCurve,
              switchOutCurve: kCalendarCurve,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.4, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: showToday
                  ? Padding(
                      key: const ValueKey<bool>(true),
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: ActionChip(
                        key: const Key('calendar_today_pill'),
                        avatar: const Icon(Icons.today_rounded, size: 18),
                        label: Text(l10n.calendarToday),
                        onPressed: onToday,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey<bool>(false)),
            ),
            if (showArrows) ...[
              IconButton(
                key: const Key('calendar_previous'),
                tooltip: previousLabel,
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                key: const Key('calendar_next'),
                tooltip: nextLabel,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
