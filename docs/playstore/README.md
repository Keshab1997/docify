# Play Store Assets — Docify: Photo , PDF & CV Maker
Package: com.keshabstudios.docify
Version: 1.2.0+5 (Profile redesign)
Last updated: 30 Sep 2026

This folder contains everything needed for Google Play Console submission.

## Files created in this update

### 1. Improved Profile Screen (code)
- `lib/screens/profile_screen.dart` — completely redesigned:
  - App header with version from PackageInfo
  - Account card (guest vs signed-in) with Drive backup status
  - Stats row: My Documents count, Privacy 100%, Ads Banner
  - Quick actions: My Documents, Sync with Drive, Lock Documents
  - Preferences: Language (EN + BN coming soon), Auto backup, Fingerprint lock, Clear cache
  - Support: Rate on Play Store, Share app, Contact support, Report bug, What's new
  - Legal: Privacy Policy, Terms, Data Deletion, Data Safety, About, Open Source Licenses, Ads, Web version
  - Footer: Made in India, links
- `lib/services/legal_texts.dart` — single source of truth for legal texts (privacy, terms, data deletion, data safety, about)
- `lib/screens/legal/legal_doc_screen.dart` — full-screen and bottom-sheet legal viewer with external URL support

### 2. Legal Documents (markdown for repo + Play Console)
- `docs/privacy_policy.md` — improved, with data safety summary, permissions, deletion
- `docs/terms_of_service.md` — new, full ToS with liability, IP, age, governing law
- `docs/data_deletion.md` — new, step-by-step deletion for on-device, Drive, Firebase Auth, AdMob
- `docs/data_safety.md` — new, exact answers for Play Console Data safety form
- `docs/child_safety.md` — new, target audience 18+, not child-directed
- `docs/support.md` — new, help, FAQ, bug report template
- `docs/play_console_checklist.md` — full checklist for store listing, app content, policy, technical

### 3. Store Listings (EN + BN)
- `docs/store_listing_en.md` — improved full description with features, private by design, permissions explained, keywords, screenshot captions, feature graphic text
- `docs/store_listing_bn.md` — Bengali translation with same structure
- `distribution/whatsnew/whatsnew-en-US` — updated for 1.2.0 with new Profile highlights
- `distribution/whatsnew/whatsnew-bn-BD` — Bengali whats new

### 4. Website (HTML for GitHub Pages hosting — required for Play Policy URL)
- `docs/website/privacy.html` — beautiful, mobile-responsive privacy policy
- `docs/website/terms.html` — terms HTML
- `docs/website/data-deletion.html` — data deletion HTML
- `docs/website/index.html` — landing page with links to legal, Play Store, web preview
- Copies in `docs/playstore/website/` as backup

These HTML files must be hosted at:
- https://keshab1997.github.io/docify/privacy.html
- https://keshab1997.github.io/docify/terms.html
- https://keshab1997.github.io/docify/data-deletion.html

**How to host:**
- Option A: GitHub repo → Settings → Pages → Source: Deploy from branch → main → /docs → then URLs are /docs/website/*.html or copy to /docs root
- Option B: Copy `docs/website/*` to `gh-pages` branch or to Flutter web build `web/` folder so `web-preview.yml` deploys them to `preview/main/privacy.html` etc.
- Simplest for now: Enable Pages from main branch /docs folder, then move `privacy.html` etc to `docs/` root (or set custom path). Update Play Console URL accordingly.

## Play Console — What to paste where

### Main store listing
- App name: `Docify: Photo , PDF & CV Maker` (exact)
- Short desc EN: `Resize photo, signature, PDF and CV for job and exam forms.`
- Short desc BN: `চাকরির ফর্মের জন্য ফটো রিসাইজ, সিগনেচার, PDF ও CV।`
- Full desc: copy from `docs/store_listing_en.md` and `docs/store_listing_bn.md`
- Feature graphic: 1024x500 — create with Canva: Docify logo + "Resize • Passport Photo • Signature • PDF Tools • CV Builder" + "Private. On-device. Made in India."
- Screenshots: Use new Profile screen (8 screenshots max)

### App content
- Privacy Policy URL: `https://keshab1997.github.io/docify/privacy.html` (must be live)
- Data safety: Use `docs/data_safety.md` — Device IDs collected & shared (AdMob), Files and docs collected only when user backs up to own Drive (not shared), Email optional
- Data deletion URL: `https://keshab1997.github.io/docify/data-deletion.html`
- Ads: Yes, contains ads (AdMob banner), No in-app purchases
- Target audience: 18+, Not directed to children under 13
- Content rating: IARC — Everyone, with ads flag, no violence/sexual/gambling
- Government apps: No, not official — disclaimer already in description
- Encryption: Yes (HTTPS), no export compliance docs needed

### Permissions
- INTERNET: "For ads and optional Drive backup to user's own Drive"
- CAMERA: "Only when user taps Scan or Capture signature, image stays on device"
- WRITE_EXTERNAL_STORAGE maxSdk 29: "Save to gallery on Android 10 and older via system picker"

## Testing before submission

1. Guest mode: uninstall → install release AAB → all tools work without sign-in
2. Profile: version shows 1.2.0, stats row shows doc count, quick actions work
3. Legal: Privacy, Terms, Data Deletion, Data Safety, About, Licenses all open
4. Support: Rate opens Play Store, Share uses system share, Contact opens mailto
5. Sync: Sign in → Sync → Drive folder "Docify" created → restore on second device
6. Ads: Banner at bottom, no test ads in release (check ADMOB_APP_ID variable)
7. No crashes, no placeholder text

## Next steps for you (owner)

1. Review `lib/screens/profile_screen.dart` — adjust colors/text if needed
2. Host legal HTML pages and verify URLs return 200
3. Create feature graphic (1024x500) and screenshots with new Profile
4. Bump version already done: 1.2.0+5
5. Push to branch, open PR, wait for CI (format + analyze + test) — per AGENTS.md, no local flutter test
6. Tag `v1.2.0` → triggers `release.yml` → builds signed AAB with AdMob IDs from repo variables
7. Upload AAB to Play Console → Internal testing → Production
8. Fill store listing EN + BN, data safety, privacy URL, data deletion URL, content rating, ads declaration
9. Submit for review

## Contact & Links

- Email: keshabsarkar2018@gmail.com
- GitHub: https://github.com/Keshab1997/docify
- Web preview: https://keshab1997.github.io/docify/preview/main/
- Privacy: https://keshab1997.github.io/docify/privacy.html
- Terms: https://keshab1997.github.io/docify/terms.html
- Data deletion: https://keshab1997.github.io/docify/data-deletion.html

Made with care in India 🇮🇳
