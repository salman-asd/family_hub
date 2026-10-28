import 'package:family_hub/features/chores/templates/domain/chore_template.dart';

/// The result of `UpdateTemplate`: the saved template plus the scope the CALLER
/// (the editor controller, P3-16) must regenerate (P3-12). The use case itself
/// never touches occurrences, which keeps the domain steps independent.
final class TemplateSaved {
  const TemplateSaved({required this.template, required this.replanScope});

  final ChoreTemplate template;
  final ReplanScope replanScope;

  @override
  bool operator ==(Object other) =>
      other is TemplateSaved &&
      other.template == template &&
      other.replanScope == replanScope;

  @override
  int get hashCode => Object.hash(template, replanScope);

  @override
  String toString() => 'TemplateSaved(${template.id}, ${replanScope.id})';
}

/// How far a content edit is applied to occurrences already planned.
///
/// [futureOnly] (the default, D-P3-23) touches nothing already written;
/// [includeUpcoming] rewrites the future occurrences that have not started.
/// Started and completed occurrences are never touched by either.
enum ReplanScope {
  futureOnly('future_only'),
  includeUpcoming('include_upcoming');

  const ReplanScope(this.id);

  final String id;
}
