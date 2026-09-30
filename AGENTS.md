# AGENTS.md — Docify

Guidance for AI coding agents working in this repository.
Read this file completely before making any change.

---

## ⛔ Rule #1 — No local testing or analysis. Ever.

> **Agents must NEVER run tests or static analysis on this repository.**
>
> The following are forbidden for agents, in any form:
>
> - `flutter test`, `flutter analyze`, `flutter build`, `dart analyze`,
>   `dart test`, `gradlew test`, or any other test/lint/build command
> - installing SDKs or packages in order to run them
> - any improvised "quick check" that compiles, runs, or lints the app
>
> **All verification happens exclusively through GitHub Actions CI.**
> CI is the single source of truth for this project.

### How to verify a change instead

1. Push the change (or open a pull request).
2. The **Flutter CI** workflow (`.github/workflows/ci.yml`) runs
   automatically on every push and PR: format check → `flutter analyze`
   → `flutter test` with coverage.
3. Read the CI results **on GitHub** (Checks tab / commit status).
4. If CI is red, fix the code from the CI error messages and push again.

Do not try to reproduce CI locally and do not treat local impressions as
verification. The agent sandbox differs from CI (Flutter SDK, Android SDK,
Firebase config secrets), so local results would be misleading.

*(This rule applies to every agent — including the one reading this file.)*

---

## Project overview

**Docify** (`com.keshabstudios.docify`) is a Flutter app that resizes photos,
signatures, PDFs and CVs for job and exam application forms. Core promises:

- **Documents stay on the device.** Nothing is uploaded unless the user
  explicitly starts a Drive backup.
- **Guest-first.** Every tool works with no account. Sign-in is an optional
  extra (Google Sign-In + Firebase, backing up to the user's own Drive).
- **AdMob is the only monetization.**

## Repository layout

```
lib/
├── main.dart               # entry point → MainNavScreen (no login gate!)
├── app_info.dart           # app name / version constants
├── models/                 # SavedDoc, exam presets, CV template info
├── screens/                # home, tools, documents, profile + bottom nav
│   └── tools/              # one screen per tool + CV builder
├── services/               # app_auth (Firebase/Google), Drive API + sync,
│   └── cv/                 # CV PDF engine + templates
├── theme/                  # colors, typography, motion
├── tools/                  # tool_registry (metadata for all tools)
└── widgets/                # shared UI (ad banner, sync sheet, ...)

android/                    # Gradle project (key.properties is git-ignored)
assets/                     # tool artwork, logos
distribution/whatsnew/      # Play release notes (en-US, bn-BD)
docs/                       # privacy policy, store listings, sync setup
.github/workflows/          # ci, manual-build, release, publish-release,
                            # web-preview
```

## Invariants — do not break these

1. **No sign-in at launch.** `main()` must never trigger Google/Firebase
   authentication UI or network calls. Sign-in starts only from an explicit
   user tap (Profile tab button or Drive sync sheet). Do not re-add
   `attemptLightweightAuthentication()` or any "silent restore" at startup.
2. **Guest mode is first-class.** If `google-services.json` is absent,
   `AppAuth.firebaseReady` is `false` and every feature still works locally.
   Never make a tool depend on auth.
3. **On-device by default.** Files are written to the app sandbox
   (`DocStore`); Drive is opt-in with the `drive.file` scope only — either a
   manual sync run or the opt-in "Automatic backup" toggle, which is strictly
   silent (signed in + Drive already granted, never prompts).
4. **Never commit secrets.** This includes `google-services.json`,
   `android/key.properties`, `*.jks`/`*.keystore`, `*.pem`, tokens, and
   Firebase/Drive credentials. CI receives them via repository secrets —
   keep it that way.

## Making changes

- **Small, focused diffs.** One concern per commit; prefer editing existing
  files over adding new ones.
- **Commit style:** conventional commits, matching history —
  `fix(auth): …`, `feat(cv): …`, `chore(ci): …`, `docs: …`.
  Scope names already in use: `auth`, `android`, `ci`, `release`, `cv`.
- **Push to a branch + pull request** for features; CI must pass before merge.
  Trivial docs fixes may go directly to `main`.
- **Watch open PRs** before editing heavily-touched files
  (e.g. `lib/services/app_auth.dart`) and keep diffs merge-friendly.

## Code style

- `flutter_lints` (see `analysis_options.yaml`) — CI enforces it, so write
  lint-clean code even though you must not run the analyzer yourself.
- Format with the standard `dart format` style (CI checks formatting).
- Comment the **why**, not the what — existing code does this consistently
  (e.g. `app_auth.dart`, `sync_sheet.dart`). Match that voice.
- UI text is plain English; store/release metadata additionally ships in
  Bengali (`bn-BD`) under `distribution/` and `docs/`.

## CI map (the only test runner)

| Workflow | When | What |
|---|---|---|
| `ci.yml` | every push & PR | format check, analyze, tests, coverage (shared `flutter-builder` workflow) |
| `manual-build.yml` | manual dispatch | APK/AAB build |
| `release.yml` / `publish-release.yml` | releases | signed build → Play |
| `web-preview.yml` | push | deploys the web build to GitHub Pages |

If you need information while working (file contents, CI logs, PR state),
use read-only GitHub API calls. Everything that *executes* code is CI's job.
