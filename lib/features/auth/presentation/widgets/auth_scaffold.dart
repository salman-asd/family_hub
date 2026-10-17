import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Shared page shell for every auth screen.
///
/// Provides the three things all five screens need identically, so they cannot
/// drift apart:
///
/// 1. a token-driven background,
/// 2. a scrollable, keyboard-safe body capped to a comfortable reading width on
///    tablets (the app is phone-first but must not stretch to a metre wide),
/// 3. an [AppBar] that is only shown when there is something to navigate back
///    to.
///
/// Accessibility: the content column is wrapped in a
/// [SafeArea] so nothing hides under a notch or the keyboard, and the
/// [SingleChildScrollView] keeps the submit button reachable when the software
/// keyboard is open at large font scales.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.children,
    this.showBackButton = true,
    this.subtitle,
    super.key,
  });

  final String title;

  /// Optional line under the title (the "subtitle" copy for each screen).
  final String? subtitle;

  final List<Widget> children;
  final bool showBackButton;

  /// Maximum content width; keeps long Bangla lines readable on wide screens.
  static const double maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final subtitleText = subtitle;

    return Scaffold(
      backgroundColor: t.background,
      appBar: showBackButton ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!showBackButton) ...[
                    Text(
                      title,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (subtitleText != null) ...[
                    Text(
                      subtitleText,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
