# Play Console Checklist — Docify: Photo , PDF & CV Maker
Package: com.keshabstudios.docify
Version: 1.1.2+4 → next should be 1.2.0+5 for new Profile
Last updated: 30 September 2026

## 1. Store listing (must match on-device name)

- [ ] App name: `Docify: Photo , PDF & CV Maker` (exact, including comma and spaces) — must match `kAppName` in `lib/app_info.dart` and `android:label` in AndroidManifest.xml. ✅ Already synced.
- [ ] Short description (80 chars max):
  - EN: `Resize photo, signature, PDF and CV for job and exam forms.`
  - BN: `চাকরির ফর্মের জন্য ফটো রিসাইজ, সিগনেচার, PDF ও CV।`
- [ ] Full description: Use `docs/store_listing_en.md` and `docs/store_listing_bn.md` (improved versions in this PR)
- [ ] App icon: 512x512 PNG, no transparency, from `assets/images/app_logo.png` (check adaptive icon)
- [ ] Feature graphic: 1024x500 PNG/JPG — create with Docify wordmark + tools collage (photo resize, passport, PDF, CV)
- [ ] Screenshots: Phone (at least 2, up to 8) — Home, Tools, Photo Resize, Passport Photo, Merge PDF, CV Builder, Documents, Profile (new). Tablet optional but recommended.
- [ ] Contact details: Email `keshabsarkar2018@gmail.com`, Phone optional, Website `https://keshab1997.github.io/docify/preview/main/`
- [ ] Privacy Policy URL: `https://keshab1997.github.io/docify/privacy.html` — must be live before submission. Host from `docs/website/` via GitHub Pages.

## 2. App content

- [ ] **Privacy Policy** — URL set, matches in-app (Profile → Privacy). ✅ `docs/privacy_policy.md` + HTML
- [ ] **Data safety** — Fill using `docs/data_safety.md`. Answers: Device IDs shared with AdMob, Files and docs only when user backs up to own Drive, Email optional.
- [ ] **Data deletion** — Provide URL `https://keshab1997.github.io/docify/data-deletion.html` + in-app path (Profile → Data Deletion). ✅ `docs/data_deletion.md`
- [ ] **Ads** — Declare: App contains ads → Yes (AdMob banner). No in-app purchases.
- [ ] **Target audience** — 18+ (not designed for children). Not a children's app. Target age 18+.
- [ ] **Content rating** — IARC questionnaire: No violence, no sexual content, no gambling, no user-generated chat. Should be Everyone or Everyone 10+ with ads flag.
- [ ] **Government apps** — No, not official. Add disclaimer in description: "Docify is a preparation tool, not an official app of any exam board or government."
- [ ] **Encryption** — Does app use encryption? YES (HTTPS for AdMob, Drive). No need for export compliance docs (standard HTTPS).
- [ ] **Permissions** — Justify INTERNET, CAMERA, WRITE_EXTERNAL_STORAGE maxSdk 29. No location, contacts.

## 3. Policy & compliance

- [ ] **Deceptive behavior** — Ensure app name matches launcher label (fixed in 1.1.2). No misleading exam board logos.
- [ ] **User data** — Privacy policy discloses AdMob and Drive.file scope. Data deletion available.
- [ ] **Families policy** — Not targeting children, no child-directed ads. AdMob content rating max G.
- [ ] **AdMob** — Real AdMob IDs from repository variables `ADMOB_APP_ID` and `ADMOB_BANNER_ID` (Settings → Variables). Test IDs only in debug. Verify no test ad in release AAB.
- [ ] **Firebase** — `google-services.json` via secret `GOOGLE_SERVICES_JSON_BASE64` for release builds. Guest mode still works without it, but release should have it for sign-in.

## 4. Technical

- [ ] **AAB** — Build via `release.yml` workflow (tag `v*`). Uses `Keshab1997/flutter-builder@v1.8.8`, verifies signing, fail-on-placeholders true.
- [ ] **Versioning** — `pubspec.yaml` version `1.1.2+4` → bump to `1.2.0+5` for new Profile. Version code must increase.
- [ ] **Signing** — Keystore secrets: `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` set in repo secrets.
- [ ] **Min SDK / Target SDK** — Check `android/app/build.gradle` (should be min 21+, target 34/35). Update if Play requires.
- [ ] **64-bit** — Flutter builds arm64-v8a + armeabi-v7a + x86_64 by default.
- [ ] **No debug logs** — Ensure no sensitive logs in release.
- [ ] **Web preview** — `web-preview.yml` deploys to GitHub Pages `preview/main/`. Verify legal HTML pages are also deployed (copy `docs/website/*.html` to web build or host separately).

## 5. New Profile features to test before submission

- [ ] Profile header shows correct version from PackageInfo
- [ ] Account card: guest → sign-in → sync → sign-out flows
- [ ] Stats row: document count from DocStore
- [ ] Quick actions: My Documents, Sync with Drive, Lock
- [ ] Settings: Language sheet, Auto backup note, Fingerprint info, Clear cache dialog
- [ ] Support: Rate opens Play Store, Share uses share_plus, Contact opens mailto, Bug report, What's new
- [ ] Legal: Privacy, Terms, Data Deletion, Data Safety, About, Open source licenses, Ads — all open LegalDocScreen
- [ ] Footer: Made in India, links to privacy/terms/support
- [ ] No crashes in guest mode (without google-services.json)
- [ ] Ad banner still shows at bottom of MainNav

## 6. Hosting legal pages (critical for Play approval)

Option A — GitHub Pages from `main` branch `/docs` folder:
1. GitHub repo → Settings → Pages → Source: Deploy from branch → Branch: main → Folder: /docs
2. Then URLs become: `https://keshab1997.github.io/docify/privacy_policy.html` etc.
3. Better: create `docs/website/` with `privacy.html`, `terms.html`, `data-deletion.html` (nice HTML with inline CSS) and set Pages to serve from `docs/website/`.

Option B — Copy legal HTML into Flutter web build:
- Add `web/legal/` files and link from `docifyWebPreviewUrl` + `/privacy.html` etc.
- Update `web-preview.yml` to include them.

This PR includes HTML versions in `docs/playstore/website/` — copy them to Pages hosting.

Required URLs for Play Console:
- Privacy Policy: `https://keshab1997.github.io/docify/privacy.html`
- Terms: `https://keshab1997.github.io/docify/terms.html`
- Data deletion: `https://keshab1997.github.io/docify/data-deletion.html`

Make sure they are live and return 200 before submitting.

## 7. Release notes

- [ ] Update `distribution/whatsnew/whatsnew-en-US` and `whatsnew-bn-BD` for next version (1.2.0)
- [ ] EN: Highlight new Profile, Legal, Data Deletion, Support, Share, Rate
- [ ] BN: Same in Bengali

Example for 1.2.0:
```
--- 1.2.0 ---
• Completely redesigned Profile — Account, Your Docify stats, Preferences, Support & Legal.
• Play Store ready: Privacy Policy, Terms, Data Deletion, Data Safety pages in app and on web.
• Quick actions: Sync with Drive, Lock Documents, My Documents stats.
• Support: Rate, Share, Contact, Bug report, What's new.
• Faster photo and PDF tools, bug fixes.
```

## 8. Final checks before "Send for review"

- [ ] AAB uploaded, version code higher than previous
- [ ] All store listing fields filled (EN + BN)
- [ ] Privacy policy URL live and matches in-app
- [ ] Data safety questionnaire complete and matches privacy policy
- [ ] Data deletion URL live
- [ ] Ads declared, content rating done
- [ ] No placeholder text, no TODO, no test ads in AAB
- [ ] Screenshots include new Profile screen
- [ ] Contact email verified (inbox works)
- [ ] App icon and feature graphic comply (no copyrighted exam logos)

## 9. After approval

- [ ] Monitor Crashlytics / Play Console → Android vitals
- [ ] Respond to reviews (especially in Bengali)
- [ ] Update `docs/sync_setup.md` if Firebase project changes
- [ ] Keep `docs/privacy_policy.md` and HTML in sync

---

Contact: keshabsarkar2018@gmail.com
Repo: https://github.com/Keshab1997/docify
Web preview: https://keshab1997.github.io/docify/preview/main/
