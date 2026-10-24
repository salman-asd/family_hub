# 0002 - One family per user

**Status:** accepted (H4)

A user belongs to at most one family (pending, active or admin-disabled).  Enforced
in the use cases (`ensureFreeToJoinAnyFamily`) and in the rules
(`familyPointerChangeOk`).  Leaving, rejection and cancelling free the user.
Account deletion (H9) leaves the family first, then soft-deletes `users/{uid}`.
