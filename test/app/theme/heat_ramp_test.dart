import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/heat_ramp.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

/// P3-24 (B.7, B.9-21): the contrast table of the calendar's heat tints, hatch,
/// dimmed days and corner marks, for EVERY registered theme.
void main() {
  for (final spec in appThemes) {
    group('heat ramp - ${spec.labelEn}', () {
      final AppTokens t = spec.tokens;
      final ramp = HeatRamp.of(t);
      final glyphInks = <String, Color>{
        'scheduled': t.statusScheduledOn,
        'inProgress': t.statusInProgressOn,
        'completed': t.statusCompletedOn,
        'verified': t.statusVerifiedOn,
        'overdue': t.statusOverdueOn,
        'skipped': t.statusSkippedOn,
      };

      test('has four distinct tints', () {
        expect(ramp.tints, hasLength(HeatRamp.steps));
        expect(ramp.tints.toSet(), hasLength(HeatRamp.steps));
        expect(ramp.tintOf(0), isNull);
        expect(ramp.tintOf(9), ramp.tints.last);
      });

      test('the day number (primary ink) is >= 4.5 on every tint', () {
        for (final tint in ramp.tints) {
          expect(_contrast(ramp.ink, tint), greaterThanOrEqualTo(4.5));
        }
      });

      test('every status glyph is >= 3 on every tint', () {
        for (final tint in ramp.tints) {
          for (final entry in glyphInks.entries) {
            expect(
              _contrast(entry.value, tint),
              greaterThanOrEqualTo(3),
              reason: '${entry.key} on $tint',
            );
          }
        }
      });

      test('the today ring (accent) is >= 3 on every tint', () {
        for (final tint in ramp.tints) {
          expect(_contrast(t.accent, tint), greaterThanOrEqualTo(3));
        }
      });

      test('a day outside the month stays >= 3 on the background', () {
        expect(
          _contrast(ramp.outsideMonthText, t.background),
          greaterThanOrEqualTo(3),
        );
      });

      test('the hatch line is >= 3 on the background and on every tint', () {
        for (final fill in <Color>[t.background, ...ramp.tints]) {
          expect(
            _contrast(HeatRamp.hatchLine(t, fill), fill),
            greaterThanOrEqualTo(3),
          );
        }
      });

      test('the corner marks are >= 4.5 (icon on container)', () {
        expect(
          _contrast(t.statusOverdueOn, t.statusOverdueContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(t.accentStrong, t.accentSoft), greaterThanOrEqualTo(4.5));
      });

      test('the selected number is >= 4.5 on its pill', () {
        expect(_contrast(t.accentStrong, t.accentSoft), greaterThanOrEqualTo(4.5));
      });
    });
  }
}
