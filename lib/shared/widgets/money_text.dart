import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders [Money] through the single [MoneyFormatter] implementation, honouring
/// the active locale and the 'Use Bangla digits' switch.
///
/// Two ways to use it:
/// * inside a [ConsumerWidget] tree, read the locale from [appFormattersProvider]
///   by passing [formatter] as null (the default) — the normal case;
/// * in a pure test or a widget without Riverpod, pass an explicit [formatter].
///
/// The widget never formats money itself; it only asks [MoneyFormatter] and
/// paints the result, so there is exactly one place money becomes text.
class MoneyText extends StatelessWidget {
  const MoneyText({
    required this.value,
    this.formatter,
    this.style,
    this.hideZeroFraction = false,
    this.semanticsLabel,
    super.key,
  });

  final Money value;

  /// Explicit formatter; when null the widget resolves one from the provider.
  final MoneyFormatter? formatter;

  final TextStyle? style;

  /// Drops the '.00' when the amount is whole (compact lists, summaries).
  final bool hideZeroFraction;

  /// Optional localized label for screen readers, e.g. "Total ৳১,২৫০".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final explicit = formatter;
    if (explicit != null) {
      return _text(context, explicit.format(value));
    }
    return _ConsumerMoneyText(
      value: value,
      style: style,
      hideZeroFraction: hideZeroFraction,
      semanticsLabel: semanticsLabel,
    );
  }

  Widget _text(BuildContext context, String text) {
    final widget = Text(text, style: style, textAlign: TextAlign.end);
    final label = semanticsLabel;
    if (label == null) return widget;
    // excludeSemantics: the label is what a screen reader should say, not the
    // digits *and* the label.
    return Semantics(label: label, excludeSemantics: true, child: widget);
  }
}

/// Reads the active locale from [appFormattersProvider] and formats [value].
class _ConsumerMoneyText extends ConsumerWidget {
  const _ConsumerMoneyText({
    required this.value,
    required this.style,
    required this.hideZeroFraction,
    required this.semanticsLabel,
  });

  final Money value;
  final TextStyle? style;
  final bool hideZeroFraction;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref
        .watch(appFormattersProvider)
        .money(value, hideZeroFraction: hideZeroFraction);
    final widget = Text(text, style: style, textAlign: TextAlign.end);
    final label = semanticsLabel;
    if (label == null) return widget;
    // excludeSemantics: the label is what a screen reader should say, not the
    // digits *and* the label.
    return Semantics(label: label, excludeSemantics: true, child: widget);
  }
}
