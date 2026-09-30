# Data Deletion Instructions — Docify: Photo , PDF & CV Maker
Package: com.keshabstudios.docify
Last updated: 30 September 2026
Contact: keshabsarkar2018@gmail.com
URL: https://keshab1997.github.io/docify/data-deletion.html

This page explains how to delete your data from Docify. Docify is primarily an on-device app with no Docify server storing your documents.

## Summary
- **On-device documents**: Delete in app or uninstall.
- **Google Drive backup (optional)**: Delete from YOUR Drive + revoke access.
- **Firebase Auth (optional sign-in)**: Sign out or delete account via app or email.
- **Ads**: Reset Advertising ID in Android settings.

---

## 1. Delete on-device documents (default mode)

Docify saves files to app-private storage (`/data/data/com.keshabstudios.docify/` and `Docify/` folder).

**Method A — In app:**
1. Open Docify → Bottom bar → Documents
2. Long press or tap file → Delete (trash icon)
3. Confirm

**Method B — Uninstall:**
1. Android Settings → Apps → Docify → Uninstall
2. This removes the app's private folder including all saved documents.
3. Files you shared via WhatsApp, Email, Gallery are copies outside Docify; delete them from those apps if needed.

**Temporary files:**
Profile → Preferences → Clear cache → Clear. This removes thumbnails and compressed copies only.

---

## 2. Delete Google Drive backup (optional feature)

If you enabled "Sync with Google Drive", your files are in YOUR Google Drive, not on our server.

**Step 1 — Delete files from Drive:**
1. Go to https://drive.google.com
2. Find folder named **"Docify"** in My Drive
3. Select files/folders → Move to Trash
4. Go to Trash → Empty trash if you want permanent deletion

**Step 2 — Revoke Drive access (optional but recommended):**
1. Go to https://myaccount.google.com/permissions
2. Find "Docify" or "Docify: Photo , PDF & CV Maker"
3. Click "Remove Access" / "Revoke"
4. After revocation, Docify can no longer read/write your Drive.

**Note:** Signing out of Docify does NOT auto-delete Drive files — you control Drive deletion. Local delete does NOT delete from Drive either — next sync will offer to restore it unless you delete from Drive too.

**Folder structure file:**
A small file `.docify-folders.json` stores your folder names. It is inside the Docify Drive folder and is deleted when you delete the folder.

---

## 3. Delete Firebase Authentication account (optional sign-in)

If you used "Sign in with Google":

**Method A — In app (if available):**
Profile → Account → Delete Account → Confirm

**Method B — Sign out (keeps Firebase record but removes local session):**
Profile → Sign out

**Method C — Email request (for full deletion):**
Email keshabsarkar2018@gmail.com from the same email you signed in with:
- Subject: "Delete my Docify account"
- Body: Your signed-in email address

We will delete your Firebase user record (display name, email, photo URL reference, UID) within 7 days. We will confirm via email.

**What deletion removes:**
- Firebase Auth user (email, display name, photo URL, UID)
- Any server-side token cache (none for documents)

**What deletion does NOT remove:**
- Drive files (follow section 2)
- On-device files (follow section 1)
- AdMob data (follow section 4)

---

## 4. Ads data (AdMob)

Google AdMob may store Advertising ID.

**To reset/delete:**
Android Settings → Privacy → Ads → Reset advertising ID or Delete advertising ID

You can also opt out of personalized ads in same screen.

More: https://support.google.com/googleplay/answer/3405269

---

## 5. What we do NOT store

We do NOT operate a Docify server that stores:
- Your photos, signatures, PDFs, CVs
- Your fingerprints, face data, PIN
- Your contacts, SMS, precise location

So there is nothing to delete on our server except optional Firebase Auth record.

---

## 6. Request via email (if you cannot access app)

Email: keshabsarkar2018@gmail.com
Subject: Docify Data Deletion Request
Include:
- Your signed-in email (if any)
- What you want deleted: on-device guidance, Drive files, or Firebase auth
- Device model (optional, helps)

We respond within 7 days.

---

## 7. Verification

After deletion:
- On-device: Documents tab should be empty
- Drive: https://drive.google.com → Docify folder should be gone
- Auth: Try signing in again — if deleted, it will create a new account

---

## 8. Contact

keshabsarkar2018@gmail.com
Keshab Studios, Kolkata, India

Official URL: https://keshab1997.github.io/docify/data-deletion.html
