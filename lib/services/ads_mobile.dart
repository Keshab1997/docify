import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob unit id, injected at build time:
///
/// ```
/// flutter build appbundle --release \
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-<publisher>/<unit>
/// ```
///
/// The CI workflows pass it from the repository variable `ADMOB_BANNER_ID`.
/// Keeping it out of the source means a Google test unit id can never ship in
/// a release build, and with no value the banner slot simply stays empty.
const String adsBannerUnitId = String.fromEnvironment('ADMOB_BANNER_ID');

/// Best-effort AdMob bootstrap, started after the first frame. The app id
/// itself lives in the Android manifest as the `${admobAppId}` placeholder,
/// which Gradle fills from the `ADMOB_APP_ID` environment variable.
class Ads {
  const Ads._();

  static Future<void>? _initialization;
  static bool _ready = false;

  /// False when the build carried no unit id, so nothing should be requested.
  static bool get hasBannerUnit => adsBannerUnitId.isNotEmpty;

  static bool get isReady => _ready;

  /// The background startup and the banner share one initialization request.
  /// Unconfigured builds never start the SDK; failures leave a usable app.
  static Future<void> initialize() => _initialization ??= _initialize();

  static Future<void> _initialize() async {
    if (!hasBannerUnit) return;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('Ads: initialization unavailable, skipping banner ($e)');
    }
  }
}
