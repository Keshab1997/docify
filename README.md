# JobDoc - Photo, PDF & CV
Package: com.keshabstudios.jobdoc
Ads: AdMob only. No in-app purchases.
Documents stay on device.

## What is this?
JobDoc helps you prepare photos, signatures, PDFs and a simple CV for job applications, exam forms and college admissions.

Resize a photo to the exact KB limit. Make a passport-size photo. Clean a signature. Turn images into a PDF. Merge files. Keep everything on your phone.

Built for Indian job forms: SSC, IBPS, Rail, UPSC, State PSC, Passport, Private jobs.

## Features v1.1
- Photo Resize — min–max KB, exam presets (SSC/IBPS/Rail/UPSC), crop, aspect lock, camera + gallery
- Passport photo — 35×45 mm / 2×2 inch, crop frame, white/blue/red background
- Create Signature — draw or clean a photo, pen size/color, transparent PNG, target KB
- Crop Image — free / 35:45 / 1:1 / 3:4, rotate
- JPG ↔ PNG — quality slider
- Image to PDF — reorder pages, A4/Letter, landscape
- Merge PDF — real page merge (raster fallback), reorder/remove
- Compress PDF — shrink scans
- PDF to Images — each page as JPG
- Job Form Assistant — exam presets, crop + draw signature, separate files + optional pack
- My Documents — open, share, rename, delete, filter
- CV Builder — Indian fields, photo, 2 templates, last draft saved
- Document Scan — multi-page, crop, contrast, PDF
- Search — only in-app tools, no mic
- Profile — privacy policy, about

## Tech
- Flutter stable
- applicationId com.keshabstudios.jobdoc
- minSdk 24, targetSdk 36, compileSdk 36
- State: Riverpod
- Image: image, flutter_image_compress
- PDF: pdf, printing
- Picker: image_picker (Photo Picker), file_picker
- Ads: google_mobile_ads (test IDs in debug)
- Storage: path_provider, app's own directory, no READ_MEDIA_IMAGES, no MANAGE_EXTERNAL_STORAGE
- Share: share_plus

## Ads (Test IDs - Debug only)
App ID: ca-app-pub-3940256099942544~3347511713
Banner: ca-app-pub-3940256099942544/6300978111
Interstitial: ca-app-pub-3940256099942544/1033173712
Release must replace with real AdMob unit. Contains ads = Yes in Play Console.

## Privacy
Photos, signatures, PDFs and CV text stay on phone and are not uploaded.
AdMob SDK may collect Device IDs, App interactions, Diagnostics, IP (approx location) for advertising, analytics, fraud prevention. Encrypted in transit.

## Store Listing (Copy-paste)
**App name:** JobDoc - Photo, PDF & CV
**Short desc (80 chars):** Resize photo, signature, PDF and CV for job and exam forms.
**Full desc:** See spec in project root / docs.

## Build
```bash
flutter pub get
flutter build appbundle --release
```

Target API 36 required from 31 Aug 2026 for new apps.

## Data Safety
- No collection: Photos, Files, Name, Email, Contacts, Location, CV text
- Yes (AdMob): Device IDs, App interactions, Diagnostics, Approx location — for Advertising, Analytics, Fraud prevention. Encrypted in transit.

## Permissions
- Photo Picker: Yes (no broad storage)
- Camera: Yes, only for scan/signature, with rationale
- INTERNET: Yes, for ads only
- No: READ_MEDIA_IMAGES, MANAGE_EXTERNAL_STORAGE, RECORD_AUDIO, Location, POST_NOTIFICATIONS, SMS, Contacts

## Individual account upload
If Play Console created after 13 Nov 2023: Closed testing 12 testers (use 15) x 14 days opted-in, then production access request.
If before: no 12 testers gate.

## Design
Reference: screenshot in uploads/file_00000000ed048211abbc3745272db543.png
Colors: #F6F8FC bg, #FFFFFF card, #1D4ED8 title blue, #0F172A body, #64748B muted, #2563EB primary, #EEF4FF photo card, #FFF1F4 signature, #E9FBF3 image2pdf, #F4F0FF merge, #FFF6F1->#FFF0F6 job banner, #EF4444 pdf badge, #16A34A success.
Font: Plus Jakarta Sans (Google Fonts).

No token or secrets/ committed.
