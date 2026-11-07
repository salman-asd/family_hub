# FCM push client manual test

Use an Android device with a Firebase-configured build and a verified account.
P4-15's server sender and P4-17's foreground notification bridge are separate
steps; for this checklist, send a test notification from the Firebase console
to the token shown in the device document.

1. Install and launch the app without opening notification settings. Confirm
   Android does not show a notification-permission prompt on first launch.
2. Sign in with a verified account. Confirm
   `users/{uid}/devices/{deviceId}` is created with the current FCM token,
   `platform: android`, language, app version, flavor, and timestamps.
   Confirm the same installation ID is reused after force-stop and relaunch.
3. Open the in-app notification permission explanation and grant permission.
   Confirm the Android 13+ system prompt appears only after the explicit
   request, and the capability status updates. Repeat with permission denied,
   then grant from app settings and resume the app.
4. Change the app language between Bangla and English. Confirm the existing
   device document updates its `lang` without changing `createdAt` or
   `deviceId`.
5. Send a console test notification while the app is in the background and
   again after swiping it away. Confirm Android displays it on `push_events`.
   Tap each notification and confirm an allow-listed route opens.
6. Send a foreground test notification. Confirm the last-received diagnostic
   updates. A user-visible foreground notification is not expected until
   P4-17 installs the bridge.
7. Test a valid route for each enabled module. Then send an unknown route and
   a route for a disabled module; both must open `/home`.
8. Sign out while online. Confirm the device document is deleted and the FCM
   token is deleted. A subsequent message sent to the old token must not be
   delivered to the signed-out installation.
9. Repeat sign-out while offline. It should fail rather than leave a
   signed-out account with a device token that may still receive pushes.
10. Leave a family while online. Confirm the device record is removed and the
    app can register it again if the same account later rejoins.

Record Android version, device model, app flavor, permission state, and any
delivery or routing failures. Do not copy real FCM tokens into issues or logs.

## Results

**Not run — 2026-11-07**, and the sender-only rows are `N/A — Spark`: there is
no push backend in this build (P4-15 and P4-26 are deferred, Appendix I), so a
message can only come from the Firebase console. The rows that remain real work
are the console sends in steps 5–7, the permission flow in step 3, and the
sign-out / leave-family device-record checks in steps 8–10; the app can be built
against `familyhub-app-ai` for them with

```bash
flutter build apk --flavor dev -t lib/main_dev.dart
```

Record device model, Android version, notification permission state, whether the
system prompt appeared only after the in-app request, and what each tap opened.
Do not paste FCM tokens here or in any issue.
