# Docify Sync — one-time Firebase & Google Drive setup

Everything below is optional. Without it the app is a full **guest app**:
all tools work, files stay on the phone, and the Profile screen shows
"Sign-in not enabled on this build". Follow these steps once to switch on
Google sign-in + backup to the user's own Google Drive.

> You own the console; the code is already in the repo (`lib/services/app_auth.dart`,
> `lib/services/drive/`, `lib/widgets/sync_sheet.dart`).

---

## 1. Get your SHA-1 (and SHA-256)

Google Sign-in only works for the exact signing key you ship.

Debug key (what `flutter run` uses):

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

Release key (the keystore referenced by `android/key.properties`, alias is
in that file):

```bash
keytool -list -v -keystore /path/to/upload-keystore.jks -alias <alias>
```

Copy **SHA-1** (and SHA-256 if the console offers a second field) from the
output. Both keys are worth registering if you test release builds locally.

> **Publishing through Google Play?** Play re-signs your app with its own
> *app signing key*. Also add that key's SHA-1 + SHA-256 (Play Console → your
> app → **Test and release → App integrity → App signing**) to the Firebase
> Android app (Project settings → Your apps → Add fingerprint). Without it,
> Google sign-in works in local/CI builds but fails for users who install
> from the Play Store.

## 2. Firebase project + Android app + google-services.json

1. <https://console.firebase.google.com> → Add project (e.g. `docify-sync`),
   Analytics off is fine.
2. **Add app → Android**: package name `com.keshabstudios.docify`, paste the
   SHA-1 from step 1 → Register app.
3. Download **`google-services.json`** and place it at:
   ```
   android/app/google-services.json
   ```
   This path is **gitignored on purpose** — never commit it. Android builds
   run guest-mode without it and apply the Google services plugin only when
   it exists (see `android/app/build.gradle`).

### Optional but recommended: give CI the same file

The reusable build workflow (`Keshab1997/flutter-builder`) writes the file
before building when the repository secret **`GOOGLE_SERVICES_JSON_BASE64`**
is set:

```bash
base64 -w0 android/app/google-services.json   # Linux
base64 -i android/app/google-services.json    # macOS
```

Paste the output as a new repo secret named `GOOGLE_SERVICES_JSON_BASE64`
(GitHub → Settings → Secrets and variables → Actions → New repository secret).
`release.yml` and `manual-build.yml` pass it to the builder explicitly;
`publish-release.yml` uses `secrets: inherit`.
Without it, CI builds still pass (guest mode) — only distribution builds
that need Firebase would skip it.

## 3. Enable Google as a sign-in provider

Firebase console → your project → **Build → Authentication → Get started →
Sign-in method → Google → Enable** → set a public-facing name (e.g. `Docify`)
→ Save.

If asked for a support email/project ID, pick the project's own.

## 4. Enable the Google Drive API

Google Cloud console (<https://console.cloud.google.com>, same project as
Firebase — it is auto-created as `Your Project - Firebase`) →

**APIs & Services → Library → "Google Drive API" → Enable.**

Without this every sync call returns `403: Drive API has not been used…`.

## 5. OAuth consent screen + scope + test users

Google Cloud console → **APIs & Services → OAuth consent screen**:

| Field | Value |
|---|---|
| User type | **External** |
| App name | Docify |
| Scopes | **Add scope → `.../auth/drive.file`** (the only Drive scope the app asks for) |
| Test users | Add **your own Google address** (and any testers) |

While the app is in *Testing* status only test users can sign in — that is
fine. Google will call the app "unverified" until you submit verification;
test users can proceed through that screen normally. (Verification is not
required for personal use; `drive.file` is a limited, low-risk scope.)

## 6. Web client ID (recommended)

The ID token must be minted for a **Web application** OAuth client:

- Firebase console → Project settings → **General → Your apps → Web app** —
  if no web client exists, adding a Web app auto-creates one.
- Or: Google Cloud → **APIs & Services → Credentials** → find the
  `…apps.googleusercontent.com` client of type **Web application**.

Firebase/Google services normally wire this automatically for Android (the
generated `default_web_client_id`), so usually **no extra flag is needed**.
If sign-in fails with an audience/`id_token` error, pass it explicitly:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Also confirm an **Android** OAuth client exists with your package name +
SHA-1 (Firebase usually creates it during step 2; otherwise create it
manually under Credentials → Create OAuth client ID → Android).

## 7. Test on a device

1. Put `google-services.json` in place → uninstall the old app → `flutter run`.
2. **Profile** → the sign-in button must now be enabled → tap
   **Sign in with Google** → choose account → allow.
3. **Documents → cloud icon** (or Profile → *Sync with Drive*) → allow Drive
   access → the confirm sheet shows **N files to back up / restore (MB)**.
4. **Sync now** → check <https://drive.google.com> → a **`Docify`** folder
   with your files.
5. Restore check: clear app data (or second phone) → sign in → sync → files
   come back.
6. **Sign out** → local files stay, Drive copies stay (sign-out never
   deletes from Drive).

## Behaviour notes (by design)

- **Local delete does not delete from Drive.** A locally deleted file is
  "only on Drive", so the *next sync's confirm sheet offers to restore it* —
  cancel there, or delete it from Drive's `Docify` folder too if you really
  want it gone.
- Same content under a different name is never uploaded twice (md5 match).
- A Drive file with the same name but different content is **never
  overwritten**: the local copy uploads as `name (2).ext`.
- Put only regular files (PDF/JPG/PNG…) in the `Docify` folder — native
  Google Docs created inside it have no bytes/md5 and will show as failed.
- Web build: sign-in is not wired yet (Phase 3) — it runs as guest.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Button says "Sign-in not enabled on this build" | `google-services.json` missing/invalid | step 2, then rebuild (also check logcat for `AppAuth:` lines) |
| `403 Drive API has not been used…` | API off | step 4 |
| `invalid_client` / `401 unauthorized` | wrong/missing OAuth client, SHA-1 not registered | steps 1–2, 6 |
| "unverified app" warning | consent screen in Testing | expected — continue, or check step 5 test-user list |
| Sign-in ok, Drive prompt never appears | scope missing from consent | step 5 (`drive.file`) |
| Sync sheet errors mid-run with `401` | web/authorized-user token expired (~1 h) | close sheet, open again (silent re-auth), retry |
| App killed during sync | — | safe: sync is idempotent, run it again |

## Privacy

`docs/privacy_policy.md` already documents optional sign-in and Drive sync
(section "Optional Google sign-in and Google Drive sync" + Data Safety).
Any Play Store Data Safety form should mirror that section: files/docs are
collected **only when the user explicitly backs them up**, to their own
Google Drive (processed by Google, not by the developer).
