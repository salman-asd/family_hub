import 'package:family_hub/features/family/presentation/action_controller.dart';

/// One busy/failure controller per catalog sheet, auto-disposed with it, so a
/// failure in one sheet never shows in another (CLAUDE.md H10).
final ActionProvider categorySheetActionProvider = newActionProvider();
final ActionProvider itemSheetActionProvider = newActionProvider();

/// The list-level actions (reorder, show/hide) of the manager screen.
final ActionProvider catalogListActionProvider = newActionProvider();
