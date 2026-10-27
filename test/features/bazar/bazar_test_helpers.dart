import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/add_bazar_trip.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/add_expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/check_duplicate.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/restore_expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/soft_delete_expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/update_expense.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/close_month.dart';
import 'package:family_hub/features/bazar/fund/domain/usecases/reopen_month.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/add_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/add_custom_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/add_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/deactivate_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/deactivate_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/ensure_catalog_seeded.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/update_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/update_item.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';

import '../../support/in_memory_bazar_backend.dart';
import '../family/family_test_helpers.dart' show SeqIds;

/// The Bazar settings `CloseMonth` reads: one fixed value, never saved.
class _ReadOnlySettings implements BazarSettingsRepository {
  _ReadOnlySettings([this.value = BazarSettings.defaults]);

  final BazarSettings value;

  @override
  Stream<BazarSettings> watch(String familyId) => Stream.value(value);

  @override
  Future<Result<BazarSettings>> get(String familyId) async =>
      Success<BazarSettings>(value);

  @override
  Future<Result<void>> save(
    String familyId,
    BazarSettings settings,
    AuditEvent event,
  ) async => const Success<void>(null);
}

/// Shared fixture for Bazar tests: one backend that is both the family and the
/// catalog port, a fixed clock, deterministic ids and the standard family.
class BazarFixture {
  BazarFixture()
    : backend = InMemoryBazarBackend(),
      clock = FakeClock(DateTime.utc(2026, 10, 18, 9)),
      ids = SeqIds() {
    _seedFamily();
  }

  static const String familyId = 'f1';

  final InMemoryBazarBackend backend;
  final FakeClock clock;
  final SeqIds ids;

  void _seedFamily() {
    backend.families[familyId] = const Family(
      id: familyId,
      name: 'Bazar family',
    );
    backend.members[familyId] = <String, Member>{
      'alice': _member('alice', Role.admin, MembershipStatus.active),
      'bob': _member('bob', Role.moderator, MembershipStatus.active),
      'cara': _member('cara', Role.member, MembershipStatus.active),
      'dave': _member('dave', Role.member, MembershipStatus.pending),
    };
    backend.adminIds[familyId] = <String>['alice'];
    backend.permissionSettings[familyId] = PermissionSettings.defaults;
    for (final uid in <String>['alice', 'bob', 'cara', 'dave']) {
      backend.userFamily[uid] = familyId;
    }
  }

  static Member _member(String uid, Role role, MembershipStatus status) =>
      Member(
        uid: uid,
        role: role,
        status: status,
        fullName: 'Person $uid',
        relationship: 'other',
      );

  AddCategory get addCategory => _addCategory();

  AddItem get addItem => _addItem();

  AddCustomItem get addCustomItem => _addCustomItem();

  UpdateCategory get updateCategory => _updateCategory();

  UpdateItem get updateItem => _updateItem();

  DeactivateCategory get deactivateCategory => _deactivateCategory();

  DeactivateItem get deactivateItem => _deactivateItem();

  EnsureCatalogSeeded get ensureCatalogSeeded => EnsureCatalogSeeded(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  AddCategory _addCategory() => AddCategory(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  AddItem _addItem() => AddItem(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  AddCustomItem _addCustomItem() => AddCustomItem(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  UpdateCategory _updateCategory() => UpdateCategory(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  UpdateItem _updateItem() => UpdateItem(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  DeactivateCategory _deactivateCategory() => DeactivateCategory(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  DeactivateItem _deactivateItem() => DeactivateItem(
    catalog: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  FamilyDateKeys get dateKeys => FamilyDateKeys(clock: clock);

  AddExpense get addExpense => AddExpense(
    expenses: backend,
    catalog: backend,
    funds: backend,
    advances: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
    dateKeys: dateKeys,
  );

  AddBazarTrip get addBazarTrip => AddBazarTrip(
    expenses: backend,
    catalog: backend,
    funds: backend,
    advances: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
    dateKeys: dateKeys,
  );

  UpdateExpense get updateExpense => UpdateExpense(
    expenses: backend,
    funds: backend,
    advances: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
    dateKeys: dateKeys,
  );

  SoftDeleteExpense get softDeleteExpense => SoftDeleteExpense(
    expenses: backend,
    funds: backend,
    advances: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
    dateKeys: dateKeys,
  );

  RestoreExpense get restoreExpense => RestoreExpense(
    expenses: backend,
    funds: backend,
    advances: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
    dateKeys: dateKeys,
  );

  CheckDuplicate get checkDuplicate =>
      CheckDuplicate(expenses: backend, families: backend, clock: clock);

  CloseMonth get closeMonth => CloseMonth(
    funds: backend,
    openingRows: backend,
    settings: settings ?? _ReadOnlySettings(),
    families: backend,
    clock: clock,
    newId: ids.call,
    dateKeys: dateKeys,
  );

  ReopenMonth get reopenMonth => ReopenMonth(
    funds: backend,
    families: backend,
    clock: clock,
    newId: ids.call,
  );

  /// The Bazar settings `CloseMonth` reads; a test sets `fundStartMonth` here.
  BazarSettingsRepository? settings;

  /// Sets the fund window start `CloseMonth` should use.
  void setFundStart(MonthKey month) =>
      settings = _ReadOnlySettings(
        BazarSettings.defaults.copyWith(fundStartMonth: month),
      );

  /// A valid draft with sensible defaults for the fixed test clock.
  ExpenseDraft draft({
    DateTime? date,
    String? itemId,
    String itemName = 'চাল',
    String categoryId = 'cat_food',
    Quantity? qty,
    Unit? unit,
    Money? unitPrice,
    Money? typedTotal = const Money.paisa(10000),
    FundingSource funding = FundingSource.fund,
    String? paidByMemberId,
    bool reimbursable = false,
    String? purchaserId,
    String? shop,
    String? note,
    bool rememberItem = false,
  }) {
    final dateKey = date == null
        ? dateKeys.today()
        : DateKey.fromInstant(date, timezone: dateKeys.timezone);
    return ExpenseDraft(
      dateKey: dateKey,
      itemId: itemId,
      itemName: itemName,
      categoryId: categoryId,
      qty: qty,
      unit: unit,
      unitPrice: unitPrice,
      typedTotal: typedTotal,
      funding: funding,
      paidByMemberId:
          paidByMemberId ?? (funding == FundingSource.member ? 'alice' : null),
      reimbursable: reimbursable,
      purchaserId: purchaserId,
      shop: shop,
      note: note,
      rememberItem: rememberItem,
    );
  }

  /// Puts an expense in the fake without going through a use case.
  Expense putExpense({
    String id = 'exp-1',
    DateKey? dateKey,
    String? itemId,
    String itemName = 'চাল',
    String categoryId = 'cat_food',
    Quantity? qty,
    Unit? unit,
    Money? unitPrice,
    Money total = const Money.paisa(10000),
    FundingSource funding = FundingSource.fund,
    String? paidByMemberId,
    bool reimbursable = false,
    String? purchaserId,
    String? tripId,
    String? shop,
    String? note,
    ExpenseSource source = ExpenseSource.manual,
    String? importBatchId,
    DateTime? deletedAt,
    String? deletedBy,
    String createdBy = 'alice',
    DateTime? createdAt,
  }) {
    final date = dateKey ?? dateKeys.today();
    final at = createdAt ?? clock.nowUtc();
    final payer =
        paidByMemberId ?? (funding == FundingSource.member ? 'alice' : null);
    final expense = Expense(
      id: id,
      dateKey: date,
      monthKey: date.monthKey,
      occurredAt: at,
      itemId: itemId,
      itemName: itemName,
      categoryId: categoryId,
      qty: qty,
      unit: unit,
      unitPrice: unitPrice,
      total: total,
      funding: funding,
      paidByMemberId: payer,
      reimbursable: reimbursable,
      purchaserId: purchaserId,
      tripId: tripId,
      shop: shop,
      note: note,
      source: source,
      importBatchId: importBatchId,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      createdBy: createdBy,
      createdAt: at,
    );
    (backend.expenses[familyId] ??= <String, Expense>{})[id] = expense;
    backend.expenseNotify();
    return expense;
  }

  /// Puts a member advance in the fake without going through a use case.
  MemberAdvance putAdvance({
    required String expenseId,
    String memberId = 'alice',
    Money amount = const Money.paisa(10000),
    Money? settled,
    AdvanceStatus? status,
    DateKey? dateKey,
  }) {
    final date = dateKey ?? dateKeys.today();
    final paid = settled ?? Money.zero;
    final advance = MemberAdvance(
      expenseId: expenseId,
      memberId: memberId,
      amount: amount,
      settled: paid,
      status: status ?? MemberAdvance.statusFor(amount, paid),
      dateKey: date,
      monthKey: date.monthKey,
    );
    (backend.advances[familyId] ??= <String, MemberAdvance>{})[expenseId] =
        advance;
    backend.expenseNotify();
    return advance;
  }

  /// Puts a ledger row in the fake without going through a use case.
  FundTransaction putFundTransaction(FundTransaction row) {
    (backend.fundTransactions[familyId] ??=
            <String, FundTransaction>{})[row.id] =
        row;
    backend.expenseNotify();
    return row;
  }

  /// Puts a month closing in the fake.
  MonthClosing putClosing({
    required MonthKey monthKey,
    MonthStatus status = MonthStatus.closed,
  }) {
    final closing = MonthClosing(
      monthKey: monthKey,
      status: status,
      closedAt: status == MonthStatus.closed ? clock.nowUtc() : null,
      closedBy: status == MonthStatus.closed ? 'alice' : null,
    );
    (backend.closings[familyId] ??= <MonthKey, MonthClosing>{})[monthKey] =
        closing;
    backend.expenseNotify();
    return closing;
  }

  /// Puts a category in the fake without going through a use case.
  Category putCategory({
    String id = 'cat_food',
    String nameBn = 'খাবার',
    String? nameEn,
    int colorIndex = 0,
    String? emoji,
    String? imageData,
    int sortOrder = 0,
    bool active = true,
    bool builtIn = false,
    String? seedKey,
  }) {
    final category = Category(
      id: id,
      nameBn: nameBn,
      nameEn: nameEn,
      colorIndex: colorIndex,
      emoji: emoji,
      imageData: imageData,
      sortOrder: sortOrder,
      active: active,
      builtIn: builtIn,
      seedKey: seedKey,
    );
    (backend.categories[familyId] ??= <String, Category>{})[id] = category;
    backend.catalogNotify();
    return category;
  }

  /// Puts an item in the fake without going through a use case.
  Item putItem({
    String id = 'item_rice',
    String nameBn = 'চাল',
    String? nameEn,
    String categoryId = 'cat_food',
    Unit defaultUnit = Unit.kg,
    List<String> aliases = const <String>[],
    String? emoji,
    String? imageData,
    int useCount = 0,
    Money? lastPrice,
    Money? lastUnitPrice,
    DateTime? lastUsedAt,
    bool active = true,
    bool builtIn = false,
    String? seedKey,
  }) {
    final item = Item(
      id: id,
      nameBn: nameBn,
      nameEn: nameEn,
      categoryId: categoryId,
      defaultUnit: defaultUnit,
      aliases: aliases,
      emoji: emoji,
      imageData: imageData,
      useCount: useCount,
      lastPrice: lastPrice,
      lastUnitPrice: lastUnitPrice,
      lastUsedAt: lastUsedAt,
      active: active,
      builtIn: builtIn,
      seedKey: seedKey,
    );
    (backend.items[familyId] ??= <String, Item>{})[id] = item;
    backend.catalogNotify();
    return item;
  }
}
