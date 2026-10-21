import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _settingsActionProvider = newActionProvider();

/// Admin-only family settings: name, time zone, currency and module switches.
class FamilySettingsScreen extends ConsumerStatefulWidget {
  const FamilySettingsScreen({super.key});

  @override
  ConsumerState<FamilySettingsScreen> createState() =>
      _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends ConsumerState<FamilySettingsScreen> {
  static const _timezones = [
    'Asia/Dhaka',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Asia/Riyadh',
    'Europe/London',
    'America/New_York',
  ];
  static const _currencies = ['BDT', 'USD', 'GBP', 'SAR', 'AED'];

  final _name = TextEditingController();
  Family? _draft;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    final draft = _draft;
    if (uid == null || draft == null) return;
    final saved = await ref.read(_settingsActionProvider.notifier).run(
          () => ref.read(updateFamilySettingsProvider)(
            actorUid: uid,
            family: draft.copyWith(name: _name.text),
          ),
        );
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final action = ref.watch(_settingsActionProvider);
    final family = ref.watch(familyProvider);
    final registry = ref.watch(moduleRegistryProvider);

    final loaded = family.value;
    if (loaded != null && _draft == null) {
      _draft = loaded;
      _name.text = loaded.name;
    }
    final draft = _draft;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familySettingsTitle)),
      body: draft == null
          ? (family.hasError
              ? EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.errorUnknown,
                  actionLabel: l10n.actionRetry,
                  onAction: () => ref.invalidate(familyProvider),
                )
              : const LoadingView())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  key: const Key('settings_name'),
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.familyNameLabel),
                ),
                const SizedBox(height: 20),
                _title(l10n.settingsTimezone, t),
                ChoiceWrap<String>(
                  options: [for (final z in _timezones) ChoiceOption(z, z)],
                  selected: draft.timezone,
                  onChanged: (z) =>
                      setState(() => _draft = draft.copyWith(timezone: z)),
                ),
                const SizedBox(height: 20),
                _title(l10n.settingsCurrency, t),
                ChoiceWrap<String>(
                  options: [for (final c in _currencies) ChoiceOption(c, c)],
                  selected: draft.currency,
                  onChanged: (c) =>
                      setState(() => _draft = draft.copyWith(currency: c)),
                ),
                const SizedBox(height: 20),
                _title(l10n.settingsModules, t),
                for (final m in registry.modules)
                  SwitchListTile(
                    key: Key('module_switch_${m.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.label(l10n)),
                    value: draft.modules.isEnabled(m.id),
                    onChanged: (on) => setState(
                      () => _draft = draft.copyWith(
                        modules: draft.modules.withFlag(m.id, enabled: on),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (action.failure != null) ...[
                  FailureBanner(failure: action.failure!),
                  const SizedBox(height: 12),
                ],
                BusyButton(
                  key: const Key('settings_save'),
                  label: l10n.profileSave,
                  busy: action.busy,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }

  Widget _title(String text, AppTokens t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: t.textSecondary),
        ),
      );
}
