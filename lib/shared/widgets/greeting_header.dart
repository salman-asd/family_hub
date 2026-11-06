import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    required this.greeting,
    required this.name,
    this.subtitle,
    super.key,
  });

  final String greeting;
  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
        ],
      ),
    );
  }
}
