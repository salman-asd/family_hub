import 'package:family_hub/core/localization/generated/app_localizations_bn.dart';
import 'package:family_hub/core/localization/generated/app_localizations_en.dart';
import 'package:family_hub/core/localization/unit_labels.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();
  final bn = AppLocalizationsBn();

  test('every unit has a non-empty bn and en label', () {
    for (final unit in Unit.values) {
      expect(en.unitLabel(unit), isNotEmpty, reason: unit.name);
      expect(bn.unitLabel(unit), isNotEmpty, reason: unit.name);
    }
  });

  test('the labels are the roadmap spellings', () {
    expect(en.unitLabel(Unit.kg), 'kg');
    expect(en.unitLabel(Unit.g), 'g');
    expect(en.unitLabel(Unit.litre), 'litre');
    expect(en.unitLabel(Unit.piece), 'pcs');
    expect(en.unitLabel(Unit.dozen), 'dozen');
    expect(en.unitLabel(Unit.packet), 'packet');
    expect(en.unitLabel(Unit.cylinder), 'cylinder');
    expect(bn.unitLabel(Unit.kg), 'কেজি');
    expect(bn.unitLabel(Unit.cylinder), 'সিলিন্ডার');
  });
}
