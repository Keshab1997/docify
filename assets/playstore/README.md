# Play Store Assets — Docify

All assets needed for the Google Play Console listing.

## Required by Play Console

| File | Dimensions | Notes |
|---|---|---|
| `icon/app_icon.png` | 512 × 512 | High-res app icon, no transparency, no rounded corners |
| `feature/feature_graphic.png` | 1024 × 500 | Top banner on Play Store listing |
| `screenshots/01_home.png` | 1080 × 1920 (9:16) | Home screen |
| `screenshots/02_tools.png` | 1080 × 1920 (9:16) | All tools grid |
| `screenshots/03_documents.png` | 1080 × 1920 (9:16) | My Documents |
| `screenshots/04_profile.png` | 1080 × 1920 (9:16) | Privacy / Profile |

## Text copy

| File | Character limit |
|---|---|
| `descriptions/short_description.txt` | ≤ 80 chars |
| `descriptions/full_description.txt` | ≤ 4000 chars |

## Notes

- App icon style: clay/paper-sculpture 3D (matches the in-app icon)
- Feature graphic + screenshots: modern flat blue (#02569B → #2D9CDB) to feel clean & professional
- All assets are PNG, sRGB, full-bleed, no transparency
- Screenshots are mockups — replace with real device captures once `flutter build apk` is finalised
- Feature graphic and screenshots can also be used for the FastWeb / web listing

## Optional extras to create

- `img/promo_video_thumb.png` — 1280×720 (if a promo video is uploaded)
- Phone-frame versions of the screenshots for the website / press kit