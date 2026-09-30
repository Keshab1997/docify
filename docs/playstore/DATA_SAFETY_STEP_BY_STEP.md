# Data Safety Form — Step-by-Step Fillup Guide
### Docify: Photo , PDF & CV Maker — Play Console → Policy → Data safety

> Ei guide follow kore Play Console e Data safety form fillup korben. CSV file `data_safety_form.csv` reference hisebe khola rakhun.

---

## Step 1: Overview

**Does your app collect or share any of the required user data types?**
- Select **YES**
- Reason: AdMob collects device IDs + optional Drive backup uploads user files to user's own Drive

**Is all of the user data collected by your app encrypted in transit?**
- Select **YES** (HTTPS/TLS)

**Do you provide a way for users to request that their data be deleted?**
- Select **YES**
- Provide deletion URL: `https://keshab1997.github.io/docify/data-deletion.html`
- In-app paths: Documents → Delete, Profile → Sign out / Delete Account, Clear cache, Drive folder delete at drive.google.com

---

## Step 2: Data types — Add each type

Play Console e "Add data type" click kore protita type add korben.

### Type 1: Device or other IDs
- Click **Device or other IDs** → Check **Device or other IDs**
- **Collected?** YES
- **Shared?** YES
- **Ephemeral?** NO (not temporary)
- **Required?** NO (user can reset Advertising ID)
- **Purposes:** Check **Advertising**, **Analytics**, **Fraud prevention, security, and compliance**, **Personalization**
- **Encrypted in transit?** YES
- **Notes:** Collected by Google AdMob SDK, not by Docify code. User can reset in Settings → Privacy → Ads.

### Type 2: App activity → App interactions
- Data type: **App activity** → **App interactions**
- Collected: YES, Shared: YES, Ephemeral: NO, Required: NO
- Purposes: Advertising, Analytics
- Encrypted: YES

### Type 3: App info and performance → Crash logs, Diagnostics, etc.
- Data type: **App info and performance** → **Crash logs**, **Diagnostics**, **Other app performance data**
- Collected: YES, Shared: YES, Ephemeral: NO, Required: NO
- Purposes: Analytics, Fraud prevention
- Encrypted: YES

### Type 4: Location → Approximate location
- Data type: **Location** → **Approximate location**
- Collected: YES, Shared: YES, Ephemeral: NO, Required: NO
- Purposes: Advertising
- Encrypted: YES
- Note: Derived from IP by AdMob, NOT GPS. We do NOT request location permission.

### Type 5: Files and docs
- Data type: **Files and docs** → **Files and docs**
- Collected: YES, Shared: NO, Ephemeral: NO, Required: NO (optional)
- Purposes: **App functionality** (backup/restore)
- Encrypted: YES
- **Important explanation to paste:**
  ```
  Collected ONLY when user explicitly taps Sync to THEIR own Google Drive. Default is 100% on-device. Files go to user's Drive folder "Docify" — Google as processor, not developer server. Developer has no server storing documents. Optional, OFF by default, user can turn off Automatic backup anytime. Encrypted via HTTPS. Deletion: user deletes from drive.google.com + revokes at myaccount.google.com/permissions + in-app delete.
  ```

### Type 6: Personal info → Email, Name
- Data type: **Personal info** → **Email address**, **Name**
- Collected: YES, Shared: NO, Ephemeral: NO, Required: NO (optional sign-in)
- Purposes: **Account management**
- Encrypted: YES
- Note: Via Firebase Auth when user taps Sign in with Google. Guest mode works without.

### Type 7: Photos and videos
- **Do NOT add** as collected — because on-device processing only is NOT counted as collection per Play policy. We use Photo Picker, no upload to developer server.
- If Play asks, select NO.

### Type 8: Everything else (Contacts, SMS, Precise location, Microphone, Calendar, etc.)
- **Do NOT add** — select NO for all.

---

## Step 3: Security

- **Data encrypted in transit:** YES
- **Data deletion:** YES — provide URL https://keshab1997.github.io/docify/data-deletion.html

---

## Step 4: SDKs

Play Console automatically detects AdMob, Firebase. If asked, confirm:

- **Google Mobile Ads (AdMob):** https://policies.google.com/privacy — collects device IDs, approximate location, app interactions for ads
- **Firebase Authentication:** https://firebase.google.com/support/privacy — email, display name, photo URL
- **Google Drive API (drive.file):** https://policies.google.com/privacy — files user chooses to backup

---

## Step 5: Preview and Submit

- Preview the data safety summary — should show:
  - Device IDs shared with third parties (AdMob)
  - Files and docs collected only for backup (not shared)
  - Email collected for account (not shared)
  - Approximate location, App interactions collected for ads
- Ensure encrypted in transit YES, deletion YES
- Save → Submit for review

---

## Copy-paste answers for Play Console notes field

If Play Console asks for additional notes:

```
Docify is private by design, on-device first. Default mode: photos, signatures, PDFs, CVs processed locally, no upload to developer server — we do not operate one. Optional backup: user taps Sign in with Google → files go to Docify folder in THEIR Google Drive (drive.file scope only, no access to rest of Drive) — Google as Drive provider, not developer. Off by default, user can enable Automatic backup toggle (off by default, max once per 15 min, silent, never prompts). Guest mode fully works without sign-in. Ads: banner via AdMob (device IDs, approximate location from IP, app interactions for advertising). Permissions: INTERNET for ads + optional Drive, CAMERA only when user scans, WRITE_EXTERNAL_STORAGE maxSdk 29 for gallery save on Android 10 and older. No broad storage, no location, no contacts. Data deletion: in-app Documents delete, Profile sign out/delete account, Drive folder delete at drive.google.com + revoke at myaccount.google.com/permissions, email keshabsarkar2018@gmail.com. Privacy: https://keshab1997.github.io/docify/privacy.html Data deletion: https://keshab1997.github.io/docify/data-deletion.html
```

---

## CSV Reference

Open `data_safety_form.csv` in Excel/Google Sheets for quick reference while filling form. Each row = one data type with Collected/Shared/Purpose.

© 2026 Keshab Studios
