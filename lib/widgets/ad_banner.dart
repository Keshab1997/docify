/// AdMob banner slot. Swaps in a no-op on web, where the SDK has no
/// implementation. See `../services/ads.dart`.
library;

export 'ad_banner_mobile.dart' if (dart.library.js_interop) 'ad_banner_web.dart';
