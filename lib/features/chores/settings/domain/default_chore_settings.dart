import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';

/// The built-in catalogs (Appendix A.3) — **the only file in the app that may
/// contain a seed id** as a string literal.
///
/// D-P3-4: groups, due-time presets and absence reasons are data, not code.
/// These constants are only the starting point an absent `settings/chores`
/// document falls back to; the family renames, deactivates and extends them in
/// the settings screen (P3-17). `test/architecture/no_hardcoded_options_test.dart`
/// (P3-07) reads [seedOptionIds] from here, so a widget can never re-introduce
/// a hard-coded list.

/// The seven built-in groups, in display order.
const List<ChoreGroup> defaultGroups = <ChoreGroup>[
  ChoreGroup(
    id: 'kitchen',
    nameBn: 'রান্নাঘর',
    nameEn: 'Kitchen',
    colorIndex: 0,
    iconKey: 'kitchen',
    sortOrder: 0,
    builtIn: true,
  ),
  ChoreGroup(
    id: 'cooking',
    nameBn: 'রান্না',
    nameEn: 'Cooking',
    colorIndex: 1,
    iconKey: 'cooking',
    sortOrder: 1,
    builtIn: true,
  ),
  ChoreGroup(
    id: 'cleaning',
    nameBn: 'পরিষ্কার-পরিচ্ছন্নতা',
    nameEn: 'Cleaning',
    colorIndex: 2,
    iconKey: 'cleaning',
    sortOrder: 2,
    builtIn: true,
  ),
  ChoreGroup(
    id: 'water',
    nameBn: 'পানি',
    nameEn: 'Water',
    colorIndex: 3,
    iconKey: 'water',
    sortOrder: 3,
    builtIn: true,
  ),
  ChoreGroup(
    id: 'fridge',
    nameBn: 'ফ্রিজ',
    nameEn: 'Fridge',
    colorIndex: 4,
    iconKey: 'fridge',
    sortOrder: 4,
    builtIn: true,
  ),
  ChoreGroup(
    id: 'living',
    nameBn: 'বসার ঘর',
    nameEn: 'Living room',
    colorIndex: 5,
    iconKey: 'living',
    sortOrder: 5,
    builtIn: true,
  ),
  ChoreGroup(
    id: 'other',
    nameBn: 'অন্যান্য',
    nameEn: 'Other',
    colorIndex: 6,
    iconKey: 'other',
    sortOrder: 6,
    builtIn: true,
  ),
];

/// The five due-time presets (minutes after midnight).
const List<DueTimePreset> defaultDueTimePresets = <DueTimePreset>[
  DueTimePreset(
    id: 'morning',
    labelBn: 'সকাল ৯টা',
    labelEn: '9:00 am',
    minutes: 540,
    builtIn: true,
  ),
  DueTimePreset(
    id: 'noon',
    labelBn: 'দুপুর ২টা',
    labelEn: '2:00 pm',
    minutes: 840,
    builtIn: true,
  ),
  DueTimePreset(
    id: 'evening',
    labelBn: 'সন্ধ্যা ৭টা',
    labelEn: '7:00 pm',
    minutes: 1140,
    builtIn: true,
  ),
  DueTimePreset(
    id: 'night',
    labelBn: 'রাত ৮টা',
    labelEn: '8:00 pm',
    minutes: 1200,
    builtIn: true,
  ),
  DueTimePreset(
    id: 'bedtime',
    labelBn: 'রাত ১০টা',
    labelEn: '10:00 pm',
    minutes: 1320,
    builtIn: true,
  ),
];

/// The six absence reasons.
const List<AbsenceReason> defaultAbsenceReasons = <AbsenceReason>[
  AbsenceReason(id: 'sick', labelBn: 'অসুস্থ', labelEn: 'Sick', builtIn: true),
  AbsenceReason(
    id: 'travel',
    labelBn: 'ভ্রমণ',
    labelEn: 'Travelling',
    builtIn: true,
  ),
  AbsenceReason(
    id: 'exam',
    labelBn: 'পরীক্ষা',
    labelEn: 'Exams',
    builtIn: true,
  ),
  AbsenceReason(
    id: 'work',
    labelBn: 'কাজ/অফিস',
    labelEn: 'Work',
    builtIn: true,
  ),
  AbsenceReason(
    id: 'family',
    labelBn: 'পারিবারিক কারণ',
    labelEn: 'Family matter',
    builtIn: true,
  ),
  AbsenceReason(
    id: 'other',
    labelBn: 'অন্যান্য',
    labelEn: 'Other',
    builtIn: true,
  ),
];

/// The fallback group id: an unknown or missing `groupId` resolves to it.
const String fallbackGroupId = 'other';

/// Every seed id except the generic `other` (which is too common a word to ban
/// in presentation code). Used by the P3-07 architecture test.
const Set<String> seedOptionIds = <String>{
  'kitchen',
  'cooking',
  'cleaning',
  'water',
  'fridge',
  'living',
  'morning',
  'noon',
  'evening',
  'night',
  'bedtime',
  'sick',
  'travel',
  'exam',
  'work',
  'family',
};
