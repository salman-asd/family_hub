import 'package:flutter/widgets.dart';

/// The one length of a small calendar animation (B.5: 150-300 ms).
const Duration kCalendarMotion = Duration(milliseconds: 180);

/// The length of a larger move (month jump, view change).
const Duration kCalendarMotionLong = Duration(milliseconds: 250);

/// The one curve of the calendar.
const Curve kCalendarCurve = Curves.easeOutCubic;

/// [duration], or [Duration.zero] when the person asked the system to reduce
/// motion (`MediaQuery.disableAnimations`, B.5). EVERY animation of the
/// calendar takes its length from here, so "reduced motion" has one test and
/// one switch.
Duration calendarMotion(
  BuildContext context, [
  Duration duration = kCalendarMotion,
]) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
