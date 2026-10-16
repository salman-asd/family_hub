import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/dev_tokens_screen.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder app shell (Step 1-3).
/// Step 4 will replace with MaterialApp.router + theme controller.
/// Step 8 will add the full route table.
class FamilyHubApp extends StatelessWidget {
  const FamilyHubApp({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => _HomeScreen(flavor: flavor),
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
      theme: buildThemeData(modernLightSpec),
      darkTheme: buildThemeData(modernDarkSpec),
      // themeMode controlled by ThemeController from Step 4 onward
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.flavor});
  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: Text(flavor.label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flavor.name,
              key: const Key('flavor_name'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: t.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/dev/tokens'),
              child: const Text('View Theme Tokens'),
            ),
          ],
        ),
      ),
    );
  }
}
