import 'package:family_hub/core/firebase/server_time.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeTxRunner', () {
    test('resolves a ServerTime marker with the injected clock', () async {
      final clock = FakeClock(DateTime.utc(2026, 10, 18, 10));
      final runner = FakeTxRunner(<String, Map<String, dynamic>>{
        'families/f1/members/u1': <String, dynamic>{'role': 'member'},
      }, clock);

      await runner.runBatch((batch) {
        batch.set('families/f1/activity/e1', <String, dynamic>{
          'type': 'family.created',
          'recordedAt': ServerTime.instance,
        });
        batch.update('families/f1/members/u1', <String, dynamic>{
          'updatedAt': ServerTime.instance,
        });
      });

      expect(
        runner.store['families/f1/activity/e1']?['recordedAt'],
        clock.nowUtc(),
      );
      expect(
        runner.store['families/f1/members/u1']?['updatedAt'],
        clock.nowUtc(),
      );
    });
    test(
      'runBatch applies set, update, delete atomically on completion',
      () async {
        final runner = FakeTxRunner({
          'families/f1/expenses/e1': {'amount': 100, 'note': 'initial'},
          'families/f1/expenses/e2': {'amount': 200},
        });

        await runner.runBatch((batch) {
          batch.set('families/f1/expenses/e3', {'amount': 300});
          batch.update('families/f1/expenses/e1', {'note': 'updated'});
          batch.delete('families/f1/expenses/e2');
        });

        expect(runner.store['families/f1/expenses/e3'], {'amount': 300});
        expect(runner.store['families/f1/expenses/e1'], {
          'amount': 100,
          'note': 'updated',
        });
        expect(runner.store.containsKey('families/f1/expenses/e2'), isFalse);
      },
    );

    test('runBatch with merge combines fields', () async {
      final runner = FakeTxRunner({
        'families/f1/settings/general': {
          'currency': 'BDT',
          'timezone': 'Asia/Dhaka',
        },
      });

      await runner.runBatch((batch) {
        batch.set('families/f1/settings/general', {
          'currency': 'USD',
        }, merge: true);
      });

      expect(runner.store['families/f1/settings/general'], {
        'currency': 'USD',
        'timezone': 'Asia/Dhaka',
      });
    });

    test('runTransaction supports read and staged writes', () async {
      final runner = FakeTxRunner({
        'families/f1/fund/balance': {'totalPaisa': 5000},
      });

      final result = await runner.runTransaction<int>((tx) async {
        final current = await tx.get('families/f1/fund/balance');
        final currentTotal = (current?['totalPaisa'] as int?) ?? 0;
        final newTotal = currentTotal + 1500;

        tx.update('families/f1/fund/balance', {'totalPaisa': newTotal});
        tx.set('families/f1/fundTransactions/tx_1', {
          'amount': 1500,
          'type': 'contribution',
        });
        return newTotal;
      });

      expect(result, 6500);
      expect(runner.store['families/f1/fund/balance']?['totalPaisa'], 6500);
      expect(
        runner.store['families/f1/fundTransactions/tx_1']?['type'],
        'contribution',
      );
    });

    test('runTransaction read-your-own-writes inside transaction', () async {
      final runner = FakeTxRunner();

      await runner.runTransaction((tx) async {
        expect(await tx.get('doc/a'), isNull);
        tx.set('doc/a', {'value': 42});
        final readBack = await tx.get('doc/a');
        expect(readBack?['value'], 42);
      });

      expect(runner.store['doc/a']?['value'], 42);
    });
  });
}
