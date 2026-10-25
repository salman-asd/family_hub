import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations_bn.dart';
import 'package:family_hub/core/localization/generated/app_localizations_en.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Roadmap section 3.6, verbatim: every stable code has a message in both
/// languages and no raw code reaches the screen.
const List<String> _validationCodes = <String>[
  'required',
  'too_long',
  'invalid_amount',
  'amount_not_positive',
  'future_date',
  'qty_unit_required',
  'member_required',
  'category_required',
  'item_name_required',
  'too_many_lines',
  'invalid_month',
  'invalid_range',
  'negative',
  'too_many_decimals',
  'too_large',
];

const List<String> _conflictCodes = <String>[
  'month_locked',
  'advance_settled',
  'overpayment',
  'already_closed',
  'not_closed',
  'reopen_note_required',
  'catalog_not_empty',
  'duplicate_item',
  'import_already_undone',
  'import_has_locked_month',
  'concurrent_edit',
  'budget_exists',
];

const List<String> _notFoundEntities = <String>[
  'expense',
  'item',
  'category',
  'advance',
  'budget',
  'import_batch',
];

void main() {
  final en = AppLocalizationsEn();
  final bn = AppLocalizationsBn();

  test('every validation code has a non-empty bn and en message', () {
    for (final code in _validationCodes) {
      for (final l in [en, bn]) {
        final text = l.bazarFailureMessage(Validation('field', code));
        expect(text, isNotEmpty, reason: code);
        expect(text, isNot(contains(code)), reason: 'raw code leaked: $code');
      }
    }
  });

  test('every conflict code has a non-empty bn and en message', () {
    for (final code in _conflictCodes) {
      for (final l in [en, bn]) {
        final text = l.bazarFailureMessage(Conflict(code: code));
        expect(text, isNotEmpty, reason: code);
        expect(text, isNot(contains(code)), reason: 'raw code leaked: $code');
      }
    }
  });

  test('every NotFound entity has a non-empty bn and en message', () {
    for (final entity in _notFoundEntities) {
      for (final l in [en, bn]) {
        final text = l.bazarFailureMessage(NotFound(entity: entity));
        expect(text, isNotEmpty, reason: entity);
        expect(
          text,
          isNot(contains(entity)),
          reason: 'raw code leaked: $entity',
        );
      }
    }
  });

  test('unknown codes fall back without leaking the code', () {
    for (final l in [en, bn]) {
      final text = l.bazarFailureMessage(
        const Validation('field', 'future_code'),
      );
      expect(text, isNotEmpty);
      expect(text, isNot(contains('future_code')));
    }
  });

  test('the remaining failures still have a message', () {
    for (final l in [en, bn]) {
      for (final failure in <AppFailure>[
        const NotFound(),
        const Conflict(),
        const PermissionDenied(),
        const Network(),
        const Unknown(),
      ]) {
        expect(l.bazarFailureMessage(failure), isNotEmpty, reason: '$failure');
      }
    }
  });

  test('permission messages name the Household Manager', () {
    expect(
      en.bazarFailureMessage(const PermissionDenied()),
      contains('Household Manager'),
    );
    expect(
      bn.bazarFailureMessage(const PermissionDenied()),
      contains('সংসার ব্যবস্থাপক'),
    );
  });
}
