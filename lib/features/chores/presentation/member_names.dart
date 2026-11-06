import 'package:family_hub/features/family/domain/member.dart';

/// The display name of [uid] in [members], else [fallback] (a removed member
/// must not break a screen).
String memberNameOf(List<Member> members, String? uid, {String fallback = ''}) {
  if (uid == null) return fallback;
  for (final member in members) {
    if (member.uid == uid) return member.displayName;
  }
  return fallback;
}
