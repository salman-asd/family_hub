import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/badges/badge_catalog.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/chores/achievements/domain/scoring/score_spec.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';

// PLACEHOLDER — owner may change.
const int defaultEasyBasePoints = 10;

// PLACEHOLDER — owner may change.
const int defaultNormalBasePoints = 20;

// PLACEHOLDER — owner may change.
const int defaultHardBasePoints = 30;

// PLACEHOLDER — owner may change.
const int defaultLatePermille = 600;

// PLACEHOLDER — owner may change.
const int defaultVerifiedPermille = 1200;

// PLACEHOLDER — owner may change.
const int defaultCoverBonusPermille = 500;

// PLACEHOLDER — owner may change.
const int defaultConsistentDays = 7;

// PLACEHOLDER — owner may change.
const int defaultReliablePercent = 90;

// PLACEHOLDER — owner may change.
const int defaultReliableMinDone = 10;

// PLACEHOLDER — owner may change.
const int defaultHelperCovers = 3;

// PLACEHOLDER — owner may change.
const int defaultDetailCount = 10;

// PLACEHOLDER — owner may change.
const int defaultSeedMinPoints = 0;

// PLACEHOLDER — owner may change.
const int defaultSproutMinPoints = 100;

// PLACEHOLDER — owner may change.
const int defaultSeedlingMinPoints = 250;

// PLACEHOLDER — owner may change.
const int defaultSaplingMinPoints = 500;

// PLACEHOLDER — owner may change.
const int defaultYoungTreeMinPoints = 900;

// PLACEHOLDER — owner may change.
const int defaultFloweringMinPoints = 1400;

// PLACEHOLDER — owner may change.
const int defaultFruitingMinPoints = 2000;

// PLACEHOLDER — owner may change.
const int defaultGrandTreeMinPoints = 3000;

EngagementSettings defaultEngagementSettings({
  required DateKey startedOn,
  required int graceMinutes,
}) => EngagementSettings(
  enabled: true,
  startedOn: startedOn,
  celebrationEnabled: true,
  showHelpersHighlight: false,
  statsVisibility: StatsVisibility.private,
  scoreSpec: ScoreSpec(
    pointBases: const <Difficulty, int>{
      Difficulty.easy: defaultEasyBasePoints,
      Difficulty.normal: defaultNormalBasePoints,
      Difficulty.hard: defaultHardBasePoints,
    },
    latePermille: defaultLatePermille,
    verifiedPermille: defaultVerifiedPermille,
    coverBonusPermille: defaultCoverBonusPermille,
    graceMinutes: graceMinutes,
    version: 1,
  ),
  levels: <EngagementLevel>[
    const EngagementLevel(
      id: 'seed',
      minPoints: defaultSeedMinPoints,
      nameBn: 'বীজ',
      nameEn: 'Seed',
    ),
    const EngagementLevel(
      id: 'sprout',
      minPoints: defaultSproutMinPoints,
      nameBn: 'অঙ্কুর',
      nameEn: 'Sprout',
    ),
    const EngagementLevel(
      id: 'seedling',
      minPoints: defaultSeedlingMinPoints,
      nameBn: 'চারা',
      nameEn: 'Seedling',
    ),
    const EngagementLevel(
      id: 'sapling',
      minPoints: defaultSaplingMinPoints,
      nameBn: 'ছোট গাছ',
      nameEn: 'Sapling',
    ),
    const EngagementLevel(
      id: 'young_tree',
      minPoints: defaultYoungTreeMinPoints,
      nameBn: 'তরুণ গাছ',
      nameEn: 'Young tree',
    ),
    const EngagementLevel(
      id: 'flowering',
      minPoints: defaultFloweringMinPoints,
      nameBn: 'ফুলের গাছ',
      nameEn: 'Flowering',
    ),
    const EngagementLevel(
      id: 'fruiting',
      minPoints: defaultFruitingMinPoints,
      nameBn: 'ফলের গাছ',
      nameEn: 'Fruiting',
    ),
    const EngagementLevel(
      id: 'grand_tree',
      minPoints: defaultGrandTreeMinPoints,
      nameBn: 'বড় গাছ',
      nameEn: 'Grand tree',
    ),
  ],
  badgeThresholds: const BadgeThresholds(
    consistentDays: defaultConsistentDays,
    reliablePercent: defaultReliablePercent,
    reliableMinDone: defaultReliableMinDone,
    helperCovers: defaultHelperCovers,
    detailCount: defaultDetailCount,
  ),
);
