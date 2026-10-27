# Bazar dashboard contract

The Home tab renders dashboard cards from `visibleModulesProvider`. A disabled
or impermitted module contributes no cards. `BazarModule.dashboardCards` is the
single source for the three Bazar cards, and `BazarModule.reports` exposes the
`bazar_month` and `bazar_categories` report-view ids.

## Cards

- **Month spend** reads the family-local current month from
  `familyDateKeysProvider`, uses `monthSpendProvider` for the shared spend
  aggregation, and resolves its top category through `categoriesProvider`.
  Deleted expenses are already excluded by `MonthSpend`. Empty, loading and
  read-error states are explicit. Tapping opens `/bazar/expenses`.
- **Fund balance** reads `fundBalanceProvider` for the ledger balance and
  `contributionStatusProvider` for this month's received and remaining totals.
  Active managers (the `recordContribution` permission) also see the number of
  pending contributions and change requests. That action opens
  `/bazar/fund?section=pending`; the fund screen scrolls to the approval section.
  Everyone else sees the family totals but not the approval action. Tapping the
  card opens `/bazar/fund`.
- **Budget alert** reads `budgetAlertsProvider`, whose first row is the worst
  current-month alert. It renders nothing when there is no alert; a read error
  is shown rather than presented as a clear budget. Tapping opens
  `/bazar/budget`.

The Bazar tab reuses the same module card builders above its feature entries and
adds an alert count to the Budget entry. The activity feed continues to render
events through the localized `activityText(type, params)` mapping; dashboard
cards do not create or rewrite activity records.

These are read-only UI integrations. They add no collection, Firestore field,
query, or index.
