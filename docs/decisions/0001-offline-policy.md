# 0001 - Offline policy (decision D3)

**Status:** accepted (H3)

Onboarding and administrative actions (create family, join, approve, reject, role
change, transfer admin, leave, cancel, revoke, settings, account deletion) REQUIRE
the server: `guardWrite(probe: ...)` fails fast with `Network` and writes nothing.
Everyday data (profile save, and from Phase 2 expenses and chores) is QUEUED: a
commit not acknowledged after the ack wait counts as queued, never as failure, and
the sync banner shows "waiting to sync".  A "does not exist" snapshot that comes
from the cache is UNKNOWN, not absent (`DocState`).  Retries reuse document ids.
