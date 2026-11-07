# firebase/

| File | Purpose |
| --- | --- |
| `firestore.rules` | Security rules (the backend half of every permission) |
| `firestore.indexes.json` | Composite indexes only (>= 2 fields). Checked by `node tools/check_indexes.mjs` |
| `rules_test/` | Emulator tests for the rules |

## Project

One Firebase project, `familyhub-app-ai`, serves both build flavors; `.firebaserc`
points the `default`, `dev` and `prod` aliases at it. The `dev` / `prod` split
that remains is only an Android flavor — a different app name and
`applicationId` suffix, so both installs can sit side by side on one phone.

**What that costs:** there is no second database to break. A test write from the
dev app is a real write, and `firebase deploy --only firestore:rules` changes the
rules the family is using immediately. Do rules experiments with the emulator
(`npx firebase emulators:exec`, above), and use the emulator or a family named
`QA …` for anything destructive.

```
npx firebase use dev          # or prod — both resolve to familyhub-app-ai
npx firebase deploy --only firestore:rules,firestore:indexes
```

## Real Firebase configuration (manual, once)

The repo ships placeholder keys in `lib/core/firebase/firebase_options_*.dart`. A non-emulator
run with placeholders fails at startup with `FirebaseNotConfiguredException`.

The real `android/app/src/{dev,prod}/google-services.json` for `familyhub-app-ai` are already on
the owner's machine and are marked `skip-worktree`, so git keeps showing the committed
placeholders. A fresh clone therefore needs both files put back and step 4 re-run.

Before the CLI steps, in the Firebase console for `familyhub-app-ai`:

- Authentication → Sign-in method → enable **Email/Password** (the only provider this app uses).
- Firestore Database → create in **Native mode**. The region is permanent — pick the
  one nearest Bangladesh that the console offers.
- Project settings → Your apps → register **two Android apps**, `com.familyhub.family_hub.dev`
  and `com.familyhub.family_hub`, with the debug SHA-1 for each.

1. `dart pub global activate flutterfire_cli`
2. `flutterfire configure` — run it interactively: choose project `familyhub-app-ai`, then both
   Android apps. It writes a single `lib/firebase_options.dart` with a class named
   `DefaultFirebaseOptions`; move its content into `lib/core/firebase/firebase_options_dev.dart`
   and `_prod.dart`, rename the class to `DevFirebaseOptions` / `ProdFirebaseOptions`, and keep
   the `static const String projectId` each file declares — the resolver and
   `test/core/firebase/firebase_options_test.dart` read it.
   `[VERIFY]` the non-interactive flag form (`--project`, `--android-app-id`, `--out`); the
   flutterfire version installed here has not been checked, so this doc does not script the call.
3. Put each app's `google-services.json` in `android/app/src/dev/` and
   `android/app/src/prod/`, then keep them out of commits:
   `git update-index --skip-worktree android/app/src/{dev,prod}/google-services.json`
4. Android API keys are not secrets, but restrict them to the app's package name and
   SHA-1 in the Google Cloud console.

## Verify the rules

The emulator needs JDK 21+. If `java -version` reports nothing, Android Studio
already ships a suitable JDK:

```
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
npx firebase emulators:exec --only firestore --project demo-family-hub \
  "npm --prefix firebase/rules_test test"
```

Expected as of 2026-11-07: 138 pass, 15 fail. All 15 are chore-occurrence and
comment writes that hit the emulator's 1000-expression budget — a Phase 5 rules
redesign, documented as item 24 in `docs/phase4_polish_audit.md`. Do not read a
green run of the other 18 files as proof that those 15 paths are enforced.

## Marking an emulator user's e-mail verified

Every rule except the owner's own `users/{uid}` requires
`request.auth.token.email_verified == true`, and the Auth emulator sends no real
verification mail, so a signed-up account is stuck at `/verify-email` until you
flip the flag. This is the invocation that works (verified 2026-11-07): `POST`,
not `PATCH`, and the `Authorization: Bearer owner` header is what the emulator
accepts in place of a real key.

```
# 1. Sign up (or sign in) and read the localId out of the response.
curl -s -X POST \
  "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-sdk-key" \
  -H "Content-Type: application/json" \
  -d '{"email":"whoever@example.com","password":"Passw0rd2","returnSecureToken":true}'

# 2. Set emailVerified on that localId.
curl -s -X POST \
  "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:update?key=fake-sdk-key" \
  -H "Authorization: Bearer owner" -H "Content-Type: application/json" \
  -d '{"localId":"<localId from step 1>","emailVerified":true}'

# 3. Confirm, then reload the user in the app ("I have verified my e-mail").
curl -s -X POST \
  "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:lookup?key=fake-sdk-key" \
  -H "Authorization: Bearer owner" -H "Content-Type: application/json" \
  -d '{"localId":["<localId>"]}'
```

The app listens on `userChanges()`, not `authStateChanges()`, so the reload after
step 2 is what moves it off `/verify-email`.
