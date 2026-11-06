# Firestore quota audit

## Measurement status

**Not measured.** The current repository does not have a Firestore read
counter that can attribute SDK reads to a screen. No quota compliance claim is
made here. The Firebase Spark quota must be checked in the Firebase console
for the production project before beta; pricing and limits can change.

## Required audit before beta

For each screen in the release checklist, record cold-open reads, warm-cache
reads, listener reads over a representative session, and the number of
documents returned. Use a test family with realistic data and the Firebase
console's current usage metrics. Record device, app version, date, and test
duration with each measurement. Include Home, Bazar, Reports, Chores calendar,
Rota, Inbox, and Family management.

Investigate any repeated listener, unbounded query, or screen whose reads grow
with navigation history. Keep queries date-bounded and limited, and compare
the results with the query/page caps in `lib/core/firebase/query_limits.dart`.
Re-run measurements after changing a listener or query. Do not infer document
read counts from the number of repository method calls.

## Spark console check

An owner must verify the production project's current Firestore free-tier
quotas and usage in the Firebase console. Save the check date and the observed
limits in this document before beta; never paste credentials or project
secrets here.
