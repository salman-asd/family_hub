# Account deletion and admin transfer

## Before deleting an account

Account deletion requires re-authentication. The user must leave their family
before the profile is soft-deleted and the Firebase Auth account is deleted.
The operation is resumable if Auth deletion fails after the profile was
soft-deleted. It does not hard-delete family records or audit history.

An admin cannot delete an account while other active family members remain
unless another admin has first been established. This protects the family from
losing its last administrator.

## Transfer the admin role

1. While the current admin is still active, open the family member/roles
   management screen.
2. Promote the intended successor to admin and complete the transfer through
   the app's transfer-admin action.
3. Confirm the successor is shown as an active admin before the original admin
   leaves or deletes their account.
4. The successor can then manage invitations, membership, settings, and future
   admin transfers.

Do not delete the original account if the transfer fails or the successor is
not confirmed. Ask another active admin to retry; if none exists, contact the
project maintainer rather than editing Firestore directly.

## Historical attribution

Deleting an account clears profile PII and soft-deletes the user, but existing
expense and chore history keeps the recorded display name so financial records
remain explainable. This follows the account-history decision in
`docs/decisions/0002-one-family-per-user.md`; it does not expose private
member statistics to other members.
