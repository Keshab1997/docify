import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob app id - test id in debug, real one required in release.
const String adsAppId = 'ca-app-pub-3940256099942544~3347511713';

/// Banner unit - test id in debug, real one required in release.
const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// AdMob bootstrap, called once before `runApp`.
class Ads {
  const Ads._();

  static Future<void> initialize() => MobileAds.instance.initialize();
}
