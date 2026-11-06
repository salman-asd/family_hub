import 'package:flutter/widgets.dart';

Duration engagementMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 600);
