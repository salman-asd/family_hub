import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/dev_tokens_screen.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/features/settings/presentation/theme_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App shell.  Step 8 will replace the ad-hoc GoRouter with the full route
/// table; for now only the placeholder home, /dev/tokens and /settings/theme
/// are wired.
class FamilyHubApp extends ConsumerWidget {
  const FamilyHubApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themeControllerProvider);
    final specs = resolveThemeSpecs(prefs);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => _HomeScreen(flavor: flavor),
        ),
        GoRoute(
          path: '/settings/theme',
          builder: (context, state) => const ThemeSettingsScreen(),
        ),
        GoRoute(
          path: '/dev/tokens',
          builder: (context, state) => const DevTokensScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: flavor.label,
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(specs.light),
      darkTheme: buildThemeData(specs.dark),
      themeMode: prefs.themeMode,
      routerConfig: router,
    );
  }
}

// ── Placeholder home ──────────────────────────────────────────────────────────

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen({required this.flavor});
  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final prefs = ref.watch(themeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(flavor.label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flavor.name,
              key: const Key('flavor_name'),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Theme: ${prefs.themeId} · ${_modeLabel(prefs)}',
              style: TextStyle(color: t.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/settings/theme'),
              child: const Text('Appearance'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/dev/tokens'),
              child: const Text('View Theme Tokens'),
            ),
          ],
        ),
      ),
    );
  }

  static String _modeLabel(ThemePrefs p) => switch (p.themeMode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };
}
