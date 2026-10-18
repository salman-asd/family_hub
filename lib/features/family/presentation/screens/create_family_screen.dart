import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _createFamilyActionProvider = newActionProvider();

/// `/family-choice/create`.  On success the membership stream makes the router
/// open the app; this screen does not navigate.
class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(_createFamilyActionProvider.notifier).reset(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(_createFamilyActionProvider.notifier).run(
          () => ref.read(createFamilyProvider)(actorUid: uid, name: _name.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final action = ref.watch(_createFamilyActionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyCreateAction)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              key: const Key('family_name'),
              controller: _name,
              enabled: !action.busy,
              autofocus: true,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.familyNameLabel),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            if (action.failure != null) ...[
              FailureBanner(failure: action.failure!),
              const SizedBox(height: 12),
            ],
            BusyButton(
              key: const Key('family_create_submit'),
              label: l10n.familyCreateSubmit,
              busy: action.busy,
              onPressed: _name.text.trim().isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
