# Data Safety — Play Console Declaration for Docify

Package: com.keshabstudios.docify
App: Docify: Photo , PDF & CV Maker
Last updated: 30 September 2026

This document is the exact answers you should enter in Play Console → Policy → Data safety.

---

## 1. Overview

**Does your app collect or share any of the required user data types?**
- **YES**
  - Reason 1: Google AdMob SDK collects device IDs, app interactions, diagnostics, approximate location (from IP) for advertising.
  - Reason 2: Optional, user-initiated backup to user's own Google Drive uploads user's chosen files (files and docs) and sign-in profile (email, name, photo) via Firebase Auth.

**Is all of the user data collected by your app encrypted in transit?**
- **YES** — HTTPS/TLS to AdMob and Google Drive / Firebase.

**Do you provide a way for users to request that their data be deleted?**
- **YES**
  - In-app: Documents → Delete, Profile → Sign out / Delete Account, Clear cache
  - Drive: User deletes Docify folder from https://drive.google.com + revokes at https://myaccount.google.com/permissions
  - Email: keshabsarkar2018@gmail.com with subject "Docify Data Deletion"

**Target audience:**
- 18+ — not directed to children under 13. Not a children's app.

---

## 2. Data types — Detailed

### A. Device or other IDs (e.g., Android Advertising ID)
- **Collected:** YES
- **Shared:** YES — to Google AdMob (Google LLC)
- **Purpose:** Advertising, Analytics, Fraud prevention, Personalization
- **Optional?** No for ad-supported free app, but user can reset ID in Android Settings → Privacy → Ads
- **Encrypted in transit:** YES
- **Notes:** Collected by AdMob SDK, not by Docify code directly.

### B. App interactions (e.g., taps, views)
- **Collected:** YES (via AdMob SDK)
- **Shared:** YES (to AdMob)
- **Purpose:** Advertising, Analytics
- **Encrypted:** YES

### C. App info and performance (crash logs, diagnostics)
- **Collected:** YES (via AdMob SDK / Firebase)
- **Shared:** YES
- **Purpose:** Analytics, Fraud prevention
- **Encrypted:** YES

### D. Approximate location (derived from IP, not GPS)
- **Collected:** YES (via AdMob SDK, IP-based)
- **Shared:** YES (to AdMob)
- **Purpose:** Advertising
- **Precise location?** NO — we do NOT request ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION
- **Encrypted:** YES

### E. Files and docs (user's photos, signatures, PDFs, CVs, certificates)
- **Collected:** YES — BUT ONLY when user explicitly chooses to back up to THEIR Google Drive
- **Shared:** NO — Goes to user's own Drive, processed by Google as Drive provider, not by developer's server. Developer has no server that can see them.
- **Purpose:** App functionality (backup/restore), user-directed
- **Optional:** YES — Off by default. User taps Sync or enables Automatic backup toggle (off by default, can be turned off anytime)
- **Encrypted:** YES (HTTPS)
- **Notes:** Default mode is 100% on-device. No collection unless user taps Sync.

### F. Photos and videos (system)
- **Collected:** NO — We use Photo Picker and Camera only when user picks/captures, and processing stays on-device. Not counted as "collection" per Play policy unless uploaded to developer server (which we don't).
- **Shared:** NO

### G. Email, Name, Profile photo (via Firebase Auth + Google Sign-In)
- **Collected:** YES — When user taps Sign in with Google
- **Shared:** NO
- **Purpose:** Account management, display on Profile screen
- **Optional:** YES — Guest mode fully works without it
- **Encrypted:** YES

### H. Contacts, SMS, Phone, Address, Precise location, Microphone, etc.
- **Collected:** NO
- **Shared:** NO

---

## 3. Permissions justification (for Play Console → App content → Permissions)

| Permission | Why needed | Video / justification text |
|---|---|---|
| android.permission.INTERNET | Ads + optional Drive sync | "Internet is used for Google AdMob banner ads and, if user enables it, backup to user's own Google Drive. No documents are sent to developer server." |
| android.permission.CAMERA | Scan document / capture signature when user chooses | "Camera is used only when user taps Scan or Capture signature. Image stays on device." |
| android.permission.WRITE_EXTERNAL_STORAGE (maxSdk 29) | Save to gallery on Android 10 and older via system picker | "Only for saving resized photo to gallery on Android 10 and older. Uses system picker on newer." |
| No READ_MEDIA_IMAGES | We use Photo Picker, no broad media permission | "We use Android Photo Picker, no broad storage permission." |

We do NOT request: ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, READ_CONTACTS, READ_SMS, RECORD_AUDIO, READ_MEDIA_IMAGES, etc.

---

## 4. Security practices

- **Encryption in transit:** YES (TLS)
- **Data deletion:** YES (see data_deletion.md)
- **No server storing user documents:** YES — only user's own Drive
- **Fingerprint lock:** Android BiometricPrompt checks locally, app never receives biometric data.

---

## 5. SDKs that collect/share data

- **Google Mobile Ads (AdMob)** — https://policies.google.com/privacy — collects device IDs, approximate location (IP), app interactions for ads.
- **Firebase Authentication** — https://firebase.google.com/support/privacy — email, display name, photo URL when user signs in.
- **Google Sign-In** — https://policies.google.com/privacy
- **Google Drive API (drive.file scope)** — https://policies.google.com/privacy — files user chooses to back up, to user's own Drive.

No other SDKs.

---

## 6. Data safety form — Copy-paste answers

When Play Console asks:

**Photos and videos:**
- Collected? NO (on-device processing only, not uploaded to developer)

**Files and docs:**
- Collected? YES
- Shared? NO
- Ephemeral? NO
- Required? NO (optional backup)
- Purpose: App functionality

**Device or other IDs:**
- Collected? YES
- Shared? YES
- Purpose: Advertising, Analytics, Fraud prevention

**App activity, App info and performance, Approximate location:**
- Collected? YES (via AdMob SDK)
- Shared? YES
- Purpose: Advertising, Analytics

**Personal info (email, name):**
- Collected? YES (optional sign-in)
- Shared? NO
- Purpose: Account management

**Everything else:** NO

---

## 7. Links to provide in Play Console

- Privacy Policy URL: https://keshab1997.github.io/docify/privacy.html
- Data deletion URL: https://keshab1997.github.io/docify/data-deletion.html (also in Privacy Policy)
- Support email: keshabsarkar2018@gmail.com
- Website: https://keshab1997.github.io/docify/preview/main/

---

## 8. Testing notes for reviewer

- App works fully offline without sign-in. All tools work guest mode.
- To test Drive sync: Profile → Sign in → Sync with Drive → Allow drive.file → Sync now. Files go to YOUR Drive's Docify folder.
- Ads: Banner at bottom of main nav. Test ads in debug, real ads in release via ADMOB variables.
- No login wall, no paywall.
