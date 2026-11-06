import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';

enum DashboardCardMode { content, loading, error }

class DashboardCardFrame extends StatelessWidget {
  const DashboardCardFrame({
    required this.title,
    required this.icon,
    required this.child,
    this.mode = DashboardCardMode.content,
    this.errorMessage,
    this.loadingLabel,
    this.onRetry,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    super.key,
  }) : assert(
         mode != DashboardCardMode.error || errorMessage != null,
         'errorMessage is required in error mode',
       );

  final String title;
  final IconData icon;
  final Widget child;
  final DashboardCardMode mode;
  final String? errorMessage;
  final String? loadingLabel;
  final VoidCallback? onRetry;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final body = switch (mode) {
      DashboardCardMode.content => child,
      DashboardCardMode.loading => LoadingView(
        lines: 2,
        semanticLabel: loadingLabel,
      ),
      DashboardCardMode.error => ErrorView(
        message: errorMessage!,
        onRetry: onRetry,
      ),
    };

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel ?? title,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: tokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}
