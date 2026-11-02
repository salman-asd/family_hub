import 'dart:async';

import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_motion.dart';
import 'package:flutter/material.dart';

/// How many months a person can swipe in either direction from the month the
/// calendar opened on.
const int kCalendarPagesEachWay = 120;

/// A horizontal pager of months (P3-22): page [kCalendarPagesEachWay] is
/// [epoch], one page is one month.
///
/// It owns no data. [month] is the focused month; a swipe reports the new month
/// through [onMonthChanged], and a change of [month] that did not come from a
/// swipe (the picker, the Today pill, a tap on a day of the next month) moves
/// the pager, animated unless [reduceMotion].
class MonthPager extends StatefulWidget {
  const MonthPager({
    required this.epoch,
    required this.month,
    required this.reduceMotion,
    required this.onMonthChanged,
    required this.pageBuilder,
    super.key,
  });

  final MonthKey epoch;
  final MonthKey month;
  final bool reduceMotion;
  final ValueChanged<MonthKey> onMonthChanged;
  final Widget Function(BuildContext context, MonthKey month) pageBuilder;

  /// The page of [month] (clamped to the pager's range).
  static int pageOf(MonthKey epoch, MonthKey month) {
    final months = (month.year - epoch.year) * 12 + (month.month - epoch.month);
    return (kCalendarPagesEachWay + months)
        .clamp(0, kCalendarPagesEachWay * 2)
        .toInt();
  }

  /// The month shown on [page].
  static MonthKey monthOf(MonthKey epoch, int page) =>
      epoch.addMonths(page - kCalendarPagesEachWay);

  @override
  State<MonthPager> createState() => _MonthPagerState();
}

class _MonthPagerState extends State<MonthPager> {
  late final PageController _controller = PageController(
    initialPage: MonthPager.pageOf(widget.epoch, widget.month),
  );

  /// True while this widget moves the pager itself: the pages it passes on the
  /// way must not be reported as swipes.
  bool _programmatic = false;

  @override
  void didUpdateWidget(MonthPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) unawaited(_follow());
  }

  Future<void> _follow() async {
    final target = MonthPager.pageOf(widget.epoch, widget.month);
    if (!_controller.hasClients || _controller.page?.round() == target) return;
    _programmatic = true;
    try {
      if (widget.reduceMotion) {
        _controller.jumpToPage(target);
      } else {
        await _controller.animateToPage(
          target,
          duration: kCalendarMotionLong,
          curve: kCalendarCurve,
        );
      }
    } finally {
      _programmatic = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: kCalendarPagesEachWay * 2 + 1,
      onPageChanged: (page) {
        if (_programmatic) return;
        widget.onMonthChanged(MonthPager.monthOf(widget.epoch, page));
      },
      itemBuilder: (context, page) {
        final child = widget.pageBuilder(
          context,
          MonthPager.monthOf(widget.epoch, page),
        );
        if (widget.reduceMotion) return child;
        // Shared-axis feel (B.5): the page slides with the finger and fades as
        // it leaves. No fade at all under reduced motion.
        return AnimatedBuilder(
          animation: _controller,
          child: child,
          builder: (context, child) {
            final position =
                _controller.hasClients && _controller.position.haveDimensions
                ? (_controller.page ?? page.toDouble())
                : page.toDouble();
            final away = (position - page).abs().clamp(0.0, 1.0).toDouble();
            return Opacity(opacity: 1 - 0.6 * away, child: child);
          },
        );
      },
    );
  }
}
