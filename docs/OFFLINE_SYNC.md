# Offline writes and conflict handling

Everyday writes use one bounded Firestore batch and may queue while offline.
The app's sync banner reports pending writes; an acknowledgement timeout is
queued work, not a failed save. A retry reuses the ids generated for the
original intent so it cannot create a second expense or occurrence.

Integrity and administrative operations require a server probe and fail with a
network failure while offline. This includes decisions that depend on fresh
financial or membership state. They must not be presented as successful when
the server could not confirm them.

On a conflict, the app does not silently merge or overwrite financial and chore
state. Refresh the affected record, review the current values, and repeat the
user action if it is still appropriate. Deterministic occurrence and ledger
ids make retries safe; append-only ledger corrections are new compensating
rows rather than edits to the original transaction.
