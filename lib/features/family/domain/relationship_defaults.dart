import 'package:family_hub/features/family/domain/relationship_entry.dart';
import 'package:family_hub/features/family/domain/relationship_id.dart';

/// The ten built-ins of roadmap 2.3, in display order.
const List<RelationshipEntry> relationshipDefaults = <RelationshipEntry>[
  RelationshipEntry(
    id: RelationshipId.father,
    labelBn: 'বাবা',
    labelEn: 'Father',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.mother,
    labelBn: 'মা',
    labelEn: 'Mother',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.son,
    labelBn: 'ছেলে',
    labelEn: 'Son',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.daughter,
    labelBn: 'মেয়ে',
    labelEn: 'Daughter',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.husband,
    labelBn: 'স্বামী',
    labelEn: 'Husband',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.wife,
    labelBn: 'স্ত্রী',
    labelEn: 'Wife',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.housewife,
    labelBn: 'গৃহিণী',
    labelEn: 'Housewife',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.daughterInLaw,
    labelBn: 'পুত্রবধূ',
    labelEn: 'Daughter-in-law',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.sonInLaw,
    labelBn: 'জামাই',
    labelEn: 'Son-in-law',
    spouseRelevant: true,
    builtIn: true,
  ),
  RelationshipEntry(
    id: RelationshipId.other,
    labelBn: 'অন্যান্য',
    labelEn: 'Other',
    builtIn: true,
  ),
];
