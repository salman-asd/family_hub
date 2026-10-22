import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _joinActionProvider = newActionProvider();

/// `/family-choice/join`.  A valid code creates a *pending* membership; the
/// router then shows the pending screen by itself.
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _code = TextEditingController();

  // One event id per screen: a retry reuses it (rule 15).
  final String _eventId = randomId();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref
        .read(_joinActionProvider.notifier)
        .run(
          () => ref.read(joinWithCodeProvider)(
            actorUid: uid,
            rawCode: _code.text,
            eventId: _eventId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final action = ref.watch(_joinActionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyJoinAction)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.joinHint,
              style: TextStyle(color: t.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('join_code'),
              controller: _code,
              enabled: !action.busy,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.joinCodeLabel),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            if (action.failure != null) ...[
              FailureBanner(failure: action.failure!),
              const SizedBox(height: 12),
            ],
            BusyButton(
              key: const Key('join_submit'),
              label: l10n.joinSubmit,
              busy: action.busy,
              onPressed: _code.text.trim().isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
