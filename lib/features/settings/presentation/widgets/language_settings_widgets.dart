import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:flutter/material.dart';

// ── Section label ─────────────────────────────────────────────────────────────

class LanguageSectionLabel extends StatelessWidget {
  const LanguageSectionLabel({required this.label, required this.tokens});
  final String label;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: tokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Language option tile ──────────────────────────────────────────────────────

class LanguageOptionTile extends StatelessWidget {
  const LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.tokens,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final AppTokens tokens;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? tokens.accent : tokens.divider;
    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection is shown with an icon + label, never colour alone.
                if (selected)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: tokens.accent,
                        size: 20,
                        semanticLabel: semanticsLabel,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bangla-digits tile ────────────────────────────────────────────────────────

class DigitsSwitchTile extends StatelessWidget {
  const DigitsSwitchTile({
    required this.value,
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final AppTokens tokens;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        onTap: () => onChanged(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.divider),
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pin_rounded,
                color: value ? tokens.accent : tokens.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: tokens.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live preview ──────────────────────────────────────────────────────────────

/// Shows a date and a money value formatted with the current settings so the
/// Bangla-digits switch has a visible effect without leaving the screen.
class LanguagePreviewCard extends StatelessWidget {
  const LanguagePreviewCard({
    required this.languageCode,
    required this.useBanglaDigits,
    required this.tokens,
  });

  final String languageCode;
  final bool useBanglaDigits;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final formatters = AppFormatters(
      languageCode: languageCode,
      useBanglaDigits: useBanglaDigits,
    );
    final now = DateTime(2026, 10, 14);
    final sample = formatters.money(
      const Money.paisa(1234567),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatters.fullDate(now),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatters.weekdayName(now.weekday),
            style: TextStyle(color: tokens.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            sample,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
