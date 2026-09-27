/// Platform-aware AdMob entry point.
///
/// `google_mobile_ads` ships no web implementation, so on web the call would
/// throw `MissingPluginException` during startup. This conditional export keeps
/// the mobile/iOS implementation and swaps in a no-op for web.
library;

export 'ads_mobile.dart' if (dart.library.js_interop) 'ads_web.dart';
