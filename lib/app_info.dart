/// Single source of truth for how the app is named.
///
/// [kAppName] is the exact string entered in the Google Play Console
/// (Store listing → App name). It is also the Android launcher label and the
/// title shown in the recent-apps switcher, because Play rejects an app whose
/// store name and on-device name disagree.
///
/// If the Play Console name ever changes, change it here and nowhere else.
library;

/// The full app name. Must stay in sync with the Play Console listing.
const String kAppName = 'Docify: Photo , PDF & CV Maker';

/// The wordmark only — for places where the full name has no room, such as a
/// single line of UI, generated file names and PDF footers.
const String kAppShortName = 'Docify';

/// The part of [kAppName] after the colon, used as the second line under the
/// wordmark. Rendered on its own it still reads as the full store name.
const String kAppDescriptor = 'Photo , PDF & CV Maker';
