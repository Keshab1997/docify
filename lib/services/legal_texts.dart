library;

/// Single source of truth for in-app legal documents.
/// These texts are also mirrored in `docs/` as markdown + HTML for Play Store.

const String kPrivacyPolicyLastUpdated = '30 September 2026';
const String kTermsLastUpdated = '30 September 2026';
const String kSupportEmail = 'keshabsarkar2018@gmail.com';
const String kDeveloperName = 'Keshab Sarkar';
const String kAppPackage = 'com.keshabstudios.docify';
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.keshabstudios.docify';
const String kPrivacyPolicyUrl =
    'https://keshab1997.github.io/docify/privacy.html';
const String kTermsUrl = 'https://keshab1997.github.io/docify/terms.html';
const String kDataDeletionUrl =
    'https://keshab1997.github.io/docify/data-deletion.html';

const String kPrivacyPolicyText = '''
# Privacy Policy — Docify: Photo , PDF & CV Maker
App: Docify: Photo , PDF & CV Maker
Package: com.keshabstudios.docify
Developer: Keshab Sarkar (Keshab Studios)
Contact: keshabsarkar2018@gmail.com
Last updated: 30 September 2026

Docify is a document preparation tool for adults (18+). It resizes photos, prepares signatures, creates and merges PDFs, and builds a simple CV on your phone.

## 1. Documents stay on your device (default)
Photos, signatures, PDFs and text you type into a CV are processed locally on your phone. We do not upload those files to any server of ours — we do not operate one. The app works fully without an account: you are never asked for a name, email or phone number inside the app.

Files you create or import to "My Documents" (job forms, certificates, ID proofs) are kept in the app's private storage on your phone. My Documents can be locked with your phone's fingerprint, face or screen lock; Android does that check, and Docify never receives or stores your fingerprint, face data or PIN.

## 2. Optional Google sign-in and Google Drive sync
You can choose "Sign in with Google" to back up your documents. This is optional; declining keeps everything exactly as before, on the phone only.

If you enable it:
- Sign-in uses Google Sign-In and Firebase Authentication (Google LLC) with your chosen Google account. Docify receives your display name, email address and profile photo to show on the Profile screen.
- Files you back up are uploaded to a folder named "Docify" in **your own Google Drive** — your account, your storage. They go to Google as your Drive provider, not to us; we have no server that can see them.
- Your folder names, and which file is in which folder, are saved with the backup in the same Docify folder (a small file named `.docify-folders.json`), so a new phone can put your files back in their folders.
- Scope requested: `drive.file`, which allows access only to files this app creates or opens. It does not expose the rest of your Drive.
- Downloading a backup copies Drive files back to the phone. Nothing on the phone is ever deleted by syncing, and signing out never deletes your Drive copies — you remove them from Drive yourself (or revoke access in your Google account at https://myaccount.google.com/permissions).
- Backups happen when you tap Sync, or — only if you turn on the "Automatic backup" switch — silently when the app opens. Automatic backup is off by default and you can turn it off at any time; it never asks for new permissions.

## 3. Ads
Docify shows advertisements through Google AdMob. The Google Mobile Ads SDK may collect and share device identifiers (including the Android advertising ID), app interactions, diagnostic data, and IP address, which may be used to estimate approximate location. This is used for advertising, analytics and fraud prevention. Data is encrypted in transit. You can reset or delete your advertising ID in Android settings.

Docify does not sell your documents. We do not have your documents on a server.

## 4. Permissions we use
- INTERNET: for ads and optional Drive sync
- CAMERA: only when you choose to scan a page or capture a signature
- WRITE_EXTERNAL_STORAGE (maxSdk 29): only for saving to gallery on Android 10 and older via system picker

We do NOT request: READ_MEDIA_IMAGES (we use Photo Picker), ACCESS_FINE_LOCATION, READ_CONTACTS, READ_SMS, RECORD_AUDIO.

## 5. Children
Docify is not directed to children under 13, and the target audience is 18+. It is not a children's app.

## 6. Data retention and deletion
- On-device files: deleted when you delete them in My Documents or uninstall the app.
- Drive backup: files remain in your Drive's Docify folder until you delete them from Drive or revoke access. Uninstalling the app does not delete Drive copies.
- Account: sign out removes local auth session. To delete your Firebase auth record, use Profile → Delete Account or email us.

## 7. Contact
Questions: keshabsarkar2018@gmail.com

## 8. Data Safety Summary (Play Console)
- No collection: Photos and videos, Name, Phone, Address, Contacts, SMS, Precise location, CV text, Documents you upload to My documents, Fingerprint/face data or PIN
- Yes (AdMob): Device or other IDs (Collected & Shared for Advertising, Analytics, Fraud prevention), App interactions, Diagnostics, Approximate location (from IP). Encrypted in transit. User can reset Advertising ID.
- Yes (optional, user-directed): Files and docs you choose to back up — uploaded to your own Google Drive (processed by Google as the Drive provider, not by the developer). Sign-in email/display name/profile photo (Firebase Authentication). Only when you tap Sign in / Sync, or automatically if you switch on "Automatic backup" in the sync sheet (off by default, can be turned off at any time); revocable from your Google account.
''';

const String kTermsOfServiceText = '''
# Terms of Service — Docify: Photo , PDF & CV Maker
Last updated: 30 September 2026
Developer: Keshab Sarkar — Keshab Studios
Contact: keshabsarkar2018@gmail.com
Package: com.keshabstudios.docify

## 1. What Docify is
Docify is a preparation tool that helps you resize photos, signatures, PDFs and build a simple CV for job applications, exam forms and college admissions. It does NOT submit forms for you, and it is NOT an official app of any exam board, university, or government.

## 2. Acceptance
By installing or using Docify you agree to these terms. If you do not agree, uninstall the app.

## 3. Your responsibilities
- You are responsible for the photos, signatures, PDFs and CV content you create. Make sure they meet the requirements of the portal you apply to.
- Do not use Docify to create forged government IDs, fake certificates, or misleading documents. The app is for resizing and assembling your own legitimate documents.
- You must have rights to any photo or document you import.

## 4. No warranty
Docify is provided "as is". While we test photo sizing against common exam presets (SSC, IBPS, Rail, UPSC), we cannot guarantee that every portal will accept your file. Always check the file on the portal's own preview/checker.

## 5. On-device processing
All resizing, cropping, PDF creation happens on your phone. We do not operate a server that stores your files. If you enable optional Drive backup, your files are stored in YOUR Google Drive, under your Google account's terms.

## 6. Ads and third parties
The app shows ads via Google AdMob. AdMob's terms and privacy policy apply to ad delivery. Google Sign-In, Firebase Authentication and Google Drive are provided by Google LLC and subject to Google's terms.

## 7. Intellectual property
Docify's code, design, icons and tool artwork are owned by Keshab Studios. Your documents and CV content remain yours. CV templates generate a PDF for you; no Docify watermark is added.

## 8. Age
You must be 18+ to use Docify, or have parental guidance where required by local law. The app is not directed to children under 13.

## 9. Termination
You may stop using Docify at any time by uninstalling. We may update or discontinue features as needed.

## 10. Limitation of liability
To the maximum extent permitted by law, Keshab Studios is not liable for indirect, incidental or consequential damages arising from use of the app, including rejection of a form due to file size mismatch.

## 11. Changes
We may update these terms when features change. Continued use after an update means you accept the new terms. Material changes will be noted in What's New on Play Store.

## 12. Contact
keshabsarkar2018@gmail.com
''';

const String kDataDeletionText = '''
# Data Deletion — Docify: Photo , PDF & CV Maker
Last updated: 30 September 2026

Docify is primarily an on-device app. Here's how to delete your data.

## 1. On-device documents (default mode)
- Open Docify → Documents → select file → Delete.
- Or uninstall the app — this removes the app's private folder (Docify) from your phone.
- Files you shared via WhatsApp, Email, etc. are copies outside Docify; delete them from those apps if needed.

## 2. Google Drive backup (optional)
If you enabled "Sync with Google Drive":
- Drive files live in YOUR Google Drive in a folder named "Docify".
- To delete them: open https://drive.google.com → find folder "Docify" → Delete. Then empty Trash in Drive if you want permanent deletion.
- Revoke Docify's Drive access: https://myaccount.google.com/permissions → find Docify → Remove Access. After revocation, Docify can no longer read/write that folder.
- Signing out of Docify does NOT auto-delete Drive files — you control Drive deletion.

## 3. Firebase Authentication (optional sign-in)
- To sign out: Profile → Sign out.
- To delete your Firebase auth record (email, display name, profile photo reference):
  - In app: Profile → Delete Account (if available) or
  - Email us at keshabsarkar2018@gmail.com from the same email you signed in with, subject "Delete my Docify account", and we will delete your Firebase user within 7 days.
- Deleting auth does NOT delete Drive files — follow step 2 for Drive.

## 4. Ads data
- AdMob may store Advertising ID. You can reset/delete it: Android Settings → Privacy → Ads → Reset/Delete advertising ID.

## 5. Request via email
If you cannot access the app, email keshabsarkar2018@gmail.com with:
- Subject: Docify Data Deletion
- Your signed-in email (if any) and what you want deleted (on-device guidance, Drive, or auth).

We respond within 7 days.

## 6. No server copy
We do not operate a Docify server that stores your photos, signatures, PDFs or CVs. There is nothing to delete on our side except the optional Firebase auth record.
''';

const String kDataSafetyText = '''
# Data Safety — Play Console answers for Docify

## Data collection and sharing
- Does your app collect or share any of the required user data types? **Yes**
  - Because: AdMob collects device IDs for ads, and optional Drive backup uploads user-chosen files to user's own Drive.

## Data types

### Device or other IDs (AdMob)
- Collected: Yes
- Shared: Yes (to AdMob)
- Purpose: Advertising, Analytics, Fraud prevention
- Encrypted in transit: Yes
- Required: No (app works without, but ads need it)
- User can request deletion: Yes (reset advertising ID in Android settings)

### App interactions, Diagnostics, Approximate location (from IP) — AdMob SDK
- Collected: Yes (via AdMob SDK)
- Shared: Yes
- Purpose: Advertising, Analytics, Fraud prevention
- Encrypted: Yes

### Files and docs (user's own documents, photos, signatures, PDFs, CVs)
- Collected: Yes, but ONLY when user chooses to back up to THEIR Google Drive
- Shared: No (goes to user's Drive, processed by Google as Drive provider, not by developer)
- Purpose: App functionality (backup/restore), user-directed
- Encrypted: Yes (HTTPS to Google Drive)
- Optional: Yes, off by default, user taps Sync

### Email, display name, profile photo (Firebase Auth)
- Collected: Yes, when user taps Sign in with Google
- Shared: No
- Purpose: Account management, show profile
- Encrypted: Yes
- Optional: Yes

### Photos and videos, Contacts, SMS, Location (precise), etc.
- Collected: No

## Security
- Data encrypted in transit: Yes
- Data deletion request mechanism: Yes (in-app delete, Drive deletion, email keshabsarkar2018@gmail.com)

## Children
- Target audience: 18+
- Not directed to children under 13

## Permissions justification (for Play Console)
- INTERNET: ads + optional Drive sync
- CAMERA: user-initiated scan/capture
- WRITE_EXTERNAL_STORAGE maxSdk 29: save to gallery on Android 10 and older via system picker
- No broad storage, no location, no contacts
''';

const String kAboutText = '''
# About Docify

Every document, form-ready.

Docify is a pocket toolkit for the paperwork behind job, exam and admission forms. Resize a photo to the exact KB, make a passport-size picture, clean up a signature, merge PDFs and build a CV — all on your phone.

Why it exists
Online portals are picky. A photo that is 52 KB when the limit is 50, a signature in the wrong format, a PDF that is too heavy to upload — and the form bounces back. Docify shows you the exact size, pixels and format before you save, so you fix it once and move on.

What you can do
• Photo and passport photo — exact KB range, exam presets, 35x45 mm and 2x2 inch
• Signature — draw or pick a photo, clean it, resize it
• PDF tools — image to PDF, merge, compress, PDF to images, document scan
• CV builder — 10 templates, no watermark
• My Documents — folders, sharing and an optional fingerprint lock

Private by design
Your photos, signatures, PDFs and CV text are processed on your device. Docify does not upload your documents to a server, and no login is needed. Optional Google Drive backup goes to YOUR Drive only if you turn it on.

Free, with ads
Docify shows ads through Google AdMob, which is its only income. There are no paid features.

Not official
Docify is a preparation tool. It does not submit forms, and it is not an app of any exam board or government. Always check your form's official notification for the exact requirements.

Made with care in India by Keshab Sarkar — Keshab Studios.

Package: com.keshabstudios.docify
Contact: keshabsarkar2018@gmail.com
Website: https://keshab1997.github.io/docify/about.html
Web version: https://keshab1997.github.io/docify/preview/main/
Privacy: https://keshab1997.github.io/docify/privacy.html
Terms: https://keshab1997.github.io/docify/terms.html
''';
