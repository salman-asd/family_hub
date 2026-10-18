import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Family tab.  Step 8 only hosts the Settings entry (Theme, Language) and
/// sign-out; members, invitations and roles arrive with Step 9.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final flavor = ref.watch(flavorProvider);
    final membership = ref.watch(membershipProvider).value;
    final canManage = membership?.canManageMembers ?? false;
    final isAdmin = membership?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navFamily)),
      body: ListView(
        key: const PageStorageKey<String>('family_tab_list'),
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsTile(
            key: const Key('family_members'),
            icon: Icons.people_outline_rounded,
            label: l10n.membersTitle,
            onTap: () => context.push(AppRoutes.familyMembers),
          ),
          if (canManage) ...[
            const SizedBox(height: 8),
            _SettingsTile(
              key: const Key('family_invitations'),
              icon: Icons.mail_outline_rounded,
              label: l10n.invitationsTitle,
              onTap: () => context.push(AppRoutes.familyInvitations),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 8),
            _SettingsTile(
              key: const Key('family_roles'),
              icon: Icons.admin_panel_settings_outlined,
              label: l10n.rolesTitle,
              onTap: () => context.push(AppRoutes.familyRoles),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              key: const Key('family_settings'),
              icon: Icons.tune_rounded,
              label: l10n.familySettingsTitle,
              onTap: () => context.push(AppRoutes.familySettings),
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              l10n.settingsTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: t.textSecondary),
            ),
          ),
          _SettingsTile(
            key: const Key('family_settings_theme'),
            icon: Icons.palette_outlined,
            label: l10n.settingsThemeTitle,
            onTap: () => context.push(AppRoutes.settingsTheme),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            key: const Key('family_settings_language'),
            icon: Icons.translate_rounded,
            label: l10n.settingsLanguageTitle,
            onTap: () => context.push(AppRoutes.settingsLanguage),
          ),
          if (flavor == Flavor.dev) ...[
            const SizedBox(height: 8),
            _SettingsTile(
              key: const Key('family_dev_tokens'),
              icon: Icons.color_lens_outlined,
              label: l10n.homeViewThemeTokens,
              onTap: () => context.push(AppRoutes.devTokens),
            ),
            const SizedBox(height: 8),
            // The component gallery (Step 11).  A route alone is not reachable
            // on a phone, so the dev flavor gets an entry next to the tokens.
            _SettingsTile(
              key: const Key('family_dev_gallery'),
              icon: Icons.widgets_outlined,
              label: l10n.devGalleryTitle,
              onTap: () => context.push(AppRoutes.devGallery),
            ),
          ],
          const SizedBox(height: 24),
          _SettingsTile(
            key: const Key('family_sign_out'),
            icon: Icons.logout_rounded,
            label: l10n.authSignOut,
            onTap: () => ref.read(signOutProvider).call(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusMd),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: t.accentStrong),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: t.textPrimary),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: t.textSecondary,
                  textDirection: Directionality.of(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
