import 'package:flutter/widgets.dart';

Duration engagementMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 600);

/// The confetti run (P4-22 specifies 1.8 s), zero under reduced motion
/// (rule 61: engagement animation lengths come from this file only).
Duration engagementMotionConfetti(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 1800);
