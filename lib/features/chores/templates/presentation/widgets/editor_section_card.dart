import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/field_error_text.dart';
import 'package:flutter/material.dart';

/// One numbered section of the template editor: a title, the section's own
/// content and, when the last save failed validation on one of its fields, the
/// message right under that content (P3-16).
class EditorSectionCard extends StatelessWidget {
  const EditorSectionCard({
    required this.title,
    required this.child,
    this.error,
    super.key,
  });

  final String title;
  final Widget child;

  /// The localized validation message for this section, or null.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.radiusMd),
          boxShadow: t.elevation1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              child,
              FieldErrorText(message: error),
            ],
          ),
        ),
      ),
    );
  }
}
