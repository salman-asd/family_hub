import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/failure_banner.dart';
import 'package:family_hub/features/family/presentation/widgets/labels.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _profileActionProvider = newActionProvider();

/// Profile setup (first sign-in) and profile editing (`editing: true`).
///
/// Setup: avatar, full name, nickname, optional gender, relationship.  When
/// editing inside a family the spouse picker also appears, for relationships
/// where it makes sense; it can be left empty.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({this.editing = false, super.key});

  final bool editing;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  Relationship _relationship = Relationship.other;
  Gender? _gender;
  String? _avatarKey;
  String? _spouseId;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(_profileActionProvider.notifier).reset());
    if (widget.editing) {
      ref.listenManual(userProfileProvider, (_, next) {
        final p = next.value;
        if (p == null || _prefilled) return;
        _prefilled = true;
        setState(() {
          _name.text = p.fullName;
          _nickname.text = p.nickname ?? '';
          _relationship = p.relationship;
          _gender = p.gender;
          _avatarKey = p.avatarKey;
          _spouseId = p.spouseId;
        });
      }, fireImmediately: true);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(_profileActionProvider.notifier).run(
          () => ref.read(saveProfileProvider)(
            actorUid: uid,
            familyId: widget.editing ? ref.read(currentFamilyIdProvider) : null,
            profile: UserProfile(
              uid: uid,
              fullName: _name.text,
              nickname: _nickname.text,
              relationship: _relationship,
              gender: _gender,
              avatarKey: _avatarKey,
              spouseId: _relationship.canHaveSpouse ? _spouseId : null,
            ),
          ),
        );
    // Setup: the router moves on by itself once the profile exists.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final action = ref.watch(_profileActionProvider);
    final members = widget.editing
        ? (ref.watch(membersProvider).value ?? const <Member>[])
        : const <Member>[];
    final uid = ref.watch(currentUidProvider) ?? '';
    final spouseCandidates =
        members.where((m) => m.uid != uid && m.isActive).toList();

    ref.listen(_profileActionProvider, (prev, next) {
      final wasBusy = prev?.busy ?? false;
      if (widget.editing && wasBusy && !next.busy && next.failure == null) {
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing ? l10n.memberEditProfile : l10n.profileSetupTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!widget.editing) ...[
              Text(
                l10n.profileSetupMessage,
                style: TextStyle(color: t.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 20),
            ],
            _Label(l10n.profileAvatar),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < AppAvatar.presetCount; i++)
                  _AvatarChoice(
                    index: i,
                    name: _name.text,
                    selected: _avatarKey == 'p$i',
                    label: l10n.avatarOption('${i + 1}'),
                    onTap: () => setState(() => _avatarKey = 'p$i'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('profile_full_name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.profileFullName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('profile_nickname'),
              controller: _nickname,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.profileNickname),
            ),
            const SizedBox(height: 20),
            _Label(l10n.profileRelationship),
            ChoiceWrap<Relationship>(
              options: [
                for (final r in Relationship.values)
                  ChoiceOption(r, l10n.relationshipLabel(r), key: Key('rel_${r.name}')),
              ],
              selected: _relationship,
              onChanged: (r) => setState(() => _relationship = r),
            ),
            const SizedBox(height: 20),
            _Label(l10n.profileGender),
            ChoiceWrap<Gender?>(
              options: [
                ChoiceOption<Gender?>(null, l10n.genderNone),
                for (final g in Gender.values)
                  ChoiceOption<Gender?>(g, l10n.genderLabel(g)),
              ],
              selected: _gender,
              onChanged: (g) => setState(() => _gender = g),
            ),
            if (widget.editing &&
                _relationship.canHaveSpouse &&
                spouseCandidates.isNotEmpty) ...[
              const SizedBox(height: 20),
              _Label(l10n.profileSpouse),
              ChoiceWrap<String?>(
                options: [
                  ChoiceOption<String?>(null, l10n.profileSpouseNone),
                  for (final m in spouseCandidates)
                    ChoiceOption<String?>(m.uid, m.displayName),
                ],
                selected: _spouseId,
                onChanged: (v) => setState(() => _spouseId = v),
              ),
            ],
            const SizedBox(height: 24),
            if (action.failure != null) ...[
              FailureBanner(failure: action.failure!),
              const SizedBox(height: 12),
            ],
            BusyButton(
              key: const Key('profile_save'),
              label: l10n.profileSave,
              busy: action.busy,
              onPressed: _name.text.trim().isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: context.tokens.textSecondary),
        ),
      );
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.index,
    required this.name,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int index;
  final String name;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        key: Key('avatar_$index'),
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppAvatar(id: 'p$index', name: name, avatarKey: 'p$index', size: 44),
              if (selected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.check_circle, size: 18, color: t.accentStrong),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
