import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A closed-month notice, shared by Add/Edit Expense, contribution and settle
/// sheets (P2-23).
///
/// Renders nothing while [month] is open, so a caller can place it
/// unconditionally.  The reason is an icon + a localized sentence, never colour
/// alone.
class LockedMonthBanner extends ConsumerWidget {
  const LockedMonthBanner({required this.month, super.key});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(monthLockedProvider(month))) {
      return const SizedBox.shrink();
    }
    return FormBanner(
      key: const ValueKey('locked-month-banner'),
      icon: Icons.lock_outline,
      text: context.l10n.bazarErrMonthLocked,
      color: context.tokens.textSecondary,
    );
  }
}
