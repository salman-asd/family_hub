import 'package:family_hub/core/utils/layout_class.dart';
import 'package:flutter/widgets.dart';

/// The responsive layout bucket the current window falls into (P4-24).
///
/// Screens and the shell read this instead of comparing raw widths, so one
/// change to the thresholds moves every layout together.  Routes never change
/// between buckets: the same screen simply arranges itself differently.
extension ResponsiveLayout on BuildContext {
  LayoutClass get layoutClass {
    final size = MediaQuery.sizeOf(this);
    return LayoutClass.of(size.width, size.shortestSide);
  }
}
