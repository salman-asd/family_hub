# Family Hub backup and restore

## Exporting a backup

Only an active family admin can export data (`Permission.exportData`). From
Bazar Reports, choose the date range and share each CSV or PDF through the
Android share sheet. CSV files are UTF-8 and contain integer paisa amounts;
keep the original files unchanged alongside a note of the exported date range.
Store backups in a private, access-controlled location. Do not send family
records to a public link or an untrusted recipient.

Export while online and after the app's queued writes have synced. Firestore's
offline cache is not a complete backup of the family, and an export is not a
substitute for a server-side recovery plan.

The app does not upload backups to Firebase or keep a second copy on the
device. A share-sheet target may retain a copy according to that target's
settings. Exported reports are for portability and review; they are not a
Firestore backup.

## What a restore involves

There is no in-app restore or bulk import for these exports. Restoring requires
an authorized administrator to review and reconcile each row, then use the
normal app workflows to recreate records. Re-entering records creates new
document ids and audit events; it does not restore original ids, ledger
relationships, deleted-document state, or historical audit/activity logs.
Do not edit Firestore directly or replay CSV rows as writes.

Before attempting recovery, preserve the original exports, identify the
affected family and date range, and contact the project maintainer. A future
restore tool must validate rows, preserve money as integer paisa, prevent
duplicate ledger entries, and be covered by rules and emulator tests.
