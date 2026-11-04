import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

String dashNameOf(BuildContext context, ChoreItem item) =>
    Localizations.localeOf(context).languageCode == 'bn'
    ? item.nameBn
    : (item.nameEn ?? item.nameBn);

/// The shared frame: a tappable [AppCard] with a title line.
class DashCard extends StatelessWidget {
  const DashCard({
    required this.cardKey,
    required this.title,
    required this.onTap,
    required this.child,
    super.key,
  });

  final Key cardKey;
  final String title;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        key: cardKey,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
