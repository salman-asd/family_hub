import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/presentation/expense_providers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/item_autocomplete_field.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the filter sheet; the sheet writes `expenseFiltersProvider` itself.
Future<void> showExpenseFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ExpenseFilterSheet(),
    );

/// Range presets, category, item, member, funding and "show deleted".
class ExpenseFilterSheet extends ConsumerStatefulWidget {
  const ExpenseFilterSheet({super.key});

  @override
  ConsumerState<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends ConsumerState<ExpenseFilterSheet> {
  final TextEditingController _item = TextEditingController();
  Item? _selectedItem;

  @override
  void initState() {
    super.initState();
    final id = ref.read(expenseFiltersProvider).itemId;
    _selectedItem = id == null ? null : ref.read(catalogIndexProvider).itemsById[id];
    _item.text = _selectedItem?.nameBn ?? '';
  }

  @override
  void dispose() {
    _item.dispose();
    super.dispose();
  }

  ExpenseFilters get _filters => ref.read(expenseFiltersProvider);

  void _set(ExpenseFilters next) =>
      ref.read(expenseFiltersProvider.notifier).set(next);

  /// `ExpenseFilters` has no copyWith; rebuild it with one field changed.
  ExpenseFilters _with({
    Object? range = _keep,
    Object? categoryId = _keep,
    Object? itemId = _keep,
    Object? memberId = _keep,
    Object? funding = _keep,
    bool? includeDeleted,
  }) {
    final f = _filters;
    return ExpenseFilters(
      range: identical(range, _keep) ? f.range : range as DateKeyRange?,
      categoryId: identical(categoryId, _keep) ? f.categoryId : categoryId as String?,
      itemId: identical(itemId, _keep) ? f.itemId : itemId as String?,
      memberId: identical(memberId, _keep) ? f.memberId : memberId as String?,
      funding: identical(funding, _keep) ? f.funding : funding as FundingSource?,
      includeDeleted: includeDeleted ?? f.includeDeleted,
      text: f.text,
    );
  }

  Future<void> _pickRange(RangePreset preset) async {
    final today = ref.read(currentDateKeyProvider);
    final weekStart = ref.read(bazarSettingsProvider).weekStartDay;
    if (preset == RangePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(today.year - 5),
        lastDate: DateTime(today.year, today.month, today.day),
      );
      if (picked == null || !mounted) return;
      _set(
        _with(
          range: DateKeyRange(
            DateKey(picked.start.year, picked.start.month, picked.start.day),
            DateKey(picked.end.year, picked.end.month, picked.end.day),
          ),
        ),
      );
      return;
    }
    _set(
      _with(
        range: resolveRange(preset, today: today, weekStartDay: weekStart),
      ),
    );
  }

  String _dateText(DateKey key) => ref
      .read(appFormattersProvider)
      .fullDate(DateTime(key.year, key.month, key.day));

  String _presetLabel(RangePreset preset) {
    final l10n = context.l10n;
    return switch (preset) {
      RangePreset.today => l10n.expenseRangeToday,
      RangePreset.yesterday => l10n.expenseRangeYesterday,
      RangePreset.last7Days => l10n.expenseRangeLast7,
      RangePreset.thisWeek => l10n.expenseRangeThisWeek,
      RangePreset.thisMonth => l10n.expenseRangeThisMonth,
      RangePreset.lastMonth => l10n.expenseRangeLastMonth,
      RangePreset.thisYear => l10n.expenseRangeThisYear,
      RangePreset.custom => l10n.expenseRangeCustom,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = ref.watch(expenseFiltersProvider);
    final index = ref.watch(catalogIndexProvider);
    final members = ref.watch(bazarMemberOptionsProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final canSeeDeleted = ref.can(Permission.editOthersExpense);
    final label = Theme.of(context).textTheme.labelLarge;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.expenseFilterTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(l10n.expenseFilterRange, style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: Text(l10n.expenseRangeAll),
                  selected: filters.range == null,
                  onSelected: (_) => _set(_with(range: null)),
                ),
                for (final preset in RangePreset.values)
                  ChoiceChip(
                    label: Text(_presetLabel(preset)),
                    selected: false,
                    onSelected: (_) => _pickRange(preset),
                  ),
              ],
            ),
            if (filters.range != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.expenseFilterRangeActive(
                    _dateText(filters.range!.start),
                    _dateText(filters.range!.end),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Text(l10n.expenseFilterCategory, style: label),
            const SizedBox(height: 8),
            ChoiceWrap<String?>(
              selected: filters.categoryId,
              onChanged: (id) => _set(
                _with(categoryId: id == filters.categoryId ? null : id),
              ),
              options: [
                for (final c in index.activeCategories)
                  ChoiceOption<String?>(c.id, c.displayName(bangla: bangla)),
              ],
            ),
            const SizedBox(height: 16),
            ItemAutocompleteField(
              controller: _item,
              selected: _selectedItem,
              label: l10n.expenseFilterItem,
              categoryId: filters.categoryId,
              onTextChanged: (text) {
                if (text.trim().isEmpty && _selectedItem != null) {
                  setState(() => _selectedItem = null);
                  _set(_with(itemId: null));
                }
              },
              onSelected: (item) {
                setState(() {
                  _selectedItem = item;
                  _item.text = item.nameBn;
                });
                _set(_with(itemId: item.id));
              },
              onNewItem: (_) {},
              allowNew: false,
            ),
            const SizedBox(height: 16),
            PersonPicker(
              options: members,
              selectedId: filters.memberId,
              onChanged: (id) => _set(_with(memberId: id)),
              label: l10n.expenseFilterMember,
              allowNone: true,
            ),
            const SizedBox(height: 16),
            Text(l10n.expenseFilterFunding, style: label),
            const SizedBox(height: 8),
            ChoiceWrap<FundingSource?>(
              selected: filters.funding,
              onChanged: (value) => _set(_with(funding: value)),
              options: [
                ChoiceOption<FundingSource?>(null, l10n.expenseFilterAny),
                ChoiceOption<FundingSource?>(
                  FundingSource.fund,
                  l10n.expenseFundingFund,
                ),
                ChoiceOption<FundingSource?>(
                  FundingSource.member,
                  l10n.bazarFundingMember,
                ),
              ],
            ),
            if (canSeeDeleted)
              SwitchListTile(
                key: const ValueKey('filter-show-deleted'),
                contentPadding: EdgeInsets.zero,
                value: filters.includeDeleted,
                onChanged: (v) => _set(_with(includeDeleted: v)),
                title: Text(l10n.expenseFilterShowDeleted),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('filter-reset'),
                    onPressed: () {
                      ref.read(expenseFiltersProvider.notifier).reset();
                      setState(() {
                        _selectedItem = null;
                        _item.clear();
                      });
                    },
                    child: Text(l10n.expenseFilterReset),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionDone),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const Object _keep = Object();
