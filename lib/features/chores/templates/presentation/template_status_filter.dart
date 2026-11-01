import 'package:family_hub/features/chores/templates/domain/chore_template.dart';

/// The filter chips of the template list (P3-16). An enum, so the options are
/// never strings typed into a widget.
enum TemplateStatusFilter {
  /// Generating occurrences: not paused, not archived.
  active,

  /// Switched off but kept.
  paused,

  /// Archived: kept for history, never generating again.
  archived;

  /// True when [template] belongs to this filter.
  bool matches(ChoreTemplate template) => switch (this) {
    TemplateStatusFilter.active => template.isGenerating,
    TemplateStatusFilter.paused => !template.active && !template.isArchived,
    TemplateStatusFilter.archived => template.isArchived,
  };
}
