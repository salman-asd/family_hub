import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:flutter/widgets.dart';

/// [bn] for Bangla readers; everybody else gets [en] when there is one.
String localizedName(BuildContext context, String bn, String? en) =>
    Localizations.localeOf(context).languageCode == 'bn' ? bn : (en ?? bn);

/// The sentence for how a chore is assigned.
String strategyLabel(AppLocalizations l10n, AssigneeStrategy strategy) =>
    switch (strategy) {
      AssigneeStrategy.rotation => l10n.choreStrategyRotation,
      AssigneeStrategy.fixed => l10n.choreStrategyFixed,
      AssigneeStrategy.manual => l10n.choreStrategyManual,
    };

String difficultyLabel(AppLocalizations l10n, Difficulty difficulty) =>
    switch (difficulty) {
      Difficulty.easy => l10n.choreDifficultyEasy,
      Difficulty.normal => l10n.choreDifficultyNormal,
      Difficulty.hard => l10n.choreDifficultyHard,
    };
