import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

/// An error line (icon + localized text, never colour alone).
class FailureBanner extends StatelessWidget {
  const FailureBanner({required this.failure, super.key});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: t.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.familyFailureMessage(failure),
              style: TextStyle(color: t.danger, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
