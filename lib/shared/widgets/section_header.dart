import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// A section title row with an optional 'See all' action on the trailing edge.
///
/// The action is a text button so it meets the 48dp touch target; the header
/// itself is plain text and never conveys meaning by colour alone.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.seeAllLabel,
    this.onSeeAll,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 8, 8),
    super.key,
  });

  final String title;

  /// Localized 'See all' text.  Ignored unless [onSeeAll] is also provided.
  final String? seeAllLabel;

  final VoidCallback? onSeeAll;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final action = onSeeAll;
    final actionLabel = seeAllLabel;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (action != null && actionLabel != null)
            TextButton(
              onPressed: action,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
