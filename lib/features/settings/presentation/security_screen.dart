import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/settings/presentation/account_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _passwordActionProvider = newActionProvider();
final _deleteActionProvider = newActionProvider();

/// Localized text for the failures of the security use cases (H9).
String securityFailureMessage(AppLocalizations l10n, AppFailure failure) =>
    switch (failure) {
      Validation(field: 'current_password' || 'password', code: 'required') =>
        l10n.securityCurrentPasswordRequired,
      Validation(code: 'password_same') => l10n.securityPasswordSame,
      Conflict(code: 'last_admin_has_members') =>
        l10n.accountDeleteLastAdminHasMembers,
      InvalidCredentials() => l10n.securityCurrentPasswordWrong,
      _ => l10n.authFailureMessage(authFailureCode(failure)),
    };

/// `/settings/security`: change password and delete account.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _deletePassword = TextEditingController();
  String? _mismatch;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    _deletePassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final l10n = context.l10n;
    if (_new.text != _confirm.text) {
      setState(() => _mismatch = l10n.authFailureValidationPasswordMismatch);
      return;
    }
    setState(() => _mismatch = null);
    final done = await ref.read(_passwordActionProvider.notifier).run(
          () => ref.read(changePasswordProvider)(
            currentPassword: _current.text,
            newPassword: _new.text,
          ),
        );
    if (!mounted) return;
    if (done == null && ref.read(_passwordActionProvider).failure == null) {
      _current.clear();
      _new.clear();
      _confirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.securityPasswordChanged)),
      );
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.securityDeleteConfirmTitle),
        content: Text(l10n.securityDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('security_delete_confirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.securityDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final familyId = ref.read(currentFamilyIdProvider);
    final afterSignOut = ref.read(afterSignOutProvider);
    final result = await ref.read(_deleteActionProvider.notifier).run(
          () => ref.read(deleteAccountProvider)(
            uid: uid,
            password: _deletePassword.text,
            familyId: familyId,
          ),
        );
    // The Auth user is gone: the router moves to /welcome by itself; make the
    // next sign-in on this phone start with an empty Firestore cache.
    if (result == null && ref.read(_deleteActionProvider).failure == null) {
      await afterSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final pw = ref.watch(_passwordActionProvider);
    final del = ref.watch(_deleteActionProvider);
    final pending = ref.watch(accountDeletionPendingProvider).value ?? false;

    Widget field(String key, TextEditingController c, String label) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            key: Key(key),
            controller: c,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: label),
            onChanged: (_) => setState(() {}),
          ),
        );

    Widget error(AppFailure f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: t.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    securityFailureMessage(l10n, f),
                    style: TextStyle(color: t.danger, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.securityChangePassword,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            field('security_current', _current, l10n.securityCurrentPassword),
            field('security_new', _new, l10n.securityNewPassword),
            field('security_confirm', _confirm, l10n.authPasswordConfirmLabel),
            if (_mismatch != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_mismatch!, style: TextStyle(color: t.danger)),
              ),
            if (pw.failure != null) error(pw.failure!),
            BusyButton(
              key: const Key('security_change_password'),
              label: l10n.securityChangePassword,
              busy: pw.busy,
              onPressed: _current.text.isEmpty ||
                      _new.text.length < AuthCredentials.minPasswordLength
                  ? null
                  : _changePassword,
            ),
            const SizedBox(height: 32),
            Divider(color: t.divider),
            const SizedBox(height: 16),
            Text(
              l10n.securityDeleteTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: t.danger),
            ),
            const SizedBox(height: 8),
            Text(
              pending ? l10n.securityDeletePending : l10n.securityDeleteBody,
              style: TextStyle(color: t.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            field('security_delete_password', _deletePassword,
                l10n.securityCurrentPassword),
            if (del.failure != null) error(del.failure!),
            BusyButton(
              key: const Key('security_delete'),
              label: pending
                  ? l10n.securityDeleteFinish
                  : l10n.securityDeleteAction,
              busy: del.busy,
              onPressed: _deletePassword.text.isEmpty ? null : _delete,
            ),
          ],
        ),
      ),
    );
  }
}
