# Privacy Policy — Docify: Photo , PDF & CV Maker
App: Docify: Photo , PDF & CV Maker
Package: com.keshabstudios.docify
Developer: Keshab Sarkar — Keshab Studios
Contact: keshabsarkar2018@gmail.com
Privacy Policy URL: https://keshab1997.github.io/docify/privacy.html
Last updated: 30 September 2026

Docify is a document preparation app for adults (18+). It resizes photos, prepares signatures, creates and merges PDFs, and can build a simple CV on your phone. Private by design.

## 1. Documents stay on your device (default mode)
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

## 3. Ads (Google AdMob)
Docify shows advertisements through Google AdMob (Google LLC). The Google Mobile Ads SDK may collect and share:
- Device identifiers (including Android advertising ID)
- App interactions, diagnostic data
- IP address, which may be used to estimate approximate location

This is used for advertising, analytics and fraud prevention. Data is encrypted in transit. You can reset or delete your advertising ID in Android Settings → Privacy → Ads.

Docify does not sell your documents. We do not have your documents on a server.

## 4. Permissions
- INTERNET: for ads and optional Drive sync
- CAMERA: only when you choose to scan a page or capture a signature
- WRITE_EXTERNAL_STORAGE (maxSdkVersion 29): only for saving to gallery on Android 10 and older

We do NOT request: READ_MEDIA_IMAGES (we use Photo Picker), ACCESS_FINE_LOCATION, READ_CONTACTS, READ_SMS, RECORD_AUDIO.

## 5. Children
Docify is not directed to children under 13, and the target audience is 18+. It is not a children's app.

## 6. Data retention and deletion
- On-device files: deleted when you delete them in My Documents or uninstall the app.
- Drive backup: files remain in your Drive's Docify folder until you delete them from Drive or revoke access. Uninstalling the app does not delete Drive copies.
- Account: sign out removes local auth session. To delete your Firebase auth record, use Profile → Delete Account or email us at keshabsarkar2018@gmail.com.

See `data_deletion.md` for step-by-step instructions.

## 7. Security
- On-device files are stored in app-private storage, not world-readable.
- Drive sync uses HTTPS (TLS) to Google.
- No Docify server means no central breach risk for your documents.

## 8. Changes
We may update this policy when features change. Material changes will be noted in Play Store What's New and here with a new "Last updated" date.

## 9. Contact
Questions about this policy: keshabsarkar2018@gmail.com
Developer: Keshab Sarkar, Keshab Studios, India

## 10. Data Safety Summary (for Play Console)
- No collection: Photos and videos, Name, Phone, Address, Contacts, SMS, Precise location, CV text, Documents you upload to My documents, Fingerprint/face data or PIN (the lock is checked by Android)
- Yes (AdMob): Device or other IDs (Collected & Shared for Advertising, Analytics, Fraud prevention), App interactions, Diagnostics, Approximate location (from IP). Encrypted in transit. User can reset Advertising ID.
- Yes (optional, user-directed): Files and docs you choose to back up — uploaded to your own Google Drive (processed by Google as the Drive provider, not by the developer). Sign-in email/display name/profile photo (Firebase Authentication). Only when you tap Sign in / Sync, or automatically if you switch on "Automatic backup" in the sync sheet (off by default, can be turned off at any time); revocable from your Google account at https://myaccount.google.com/permissions.

Official web version: https://keshab1997.github.io/docify/privacy.html
