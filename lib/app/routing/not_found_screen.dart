import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown for a path no route matches.  Routes leave through `/home`; the guard
/// sends signed-out or not-yet-active users onwards from there.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        actionLabel: l10n.notFoundAction,
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
