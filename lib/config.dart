// App configuration.
//
// API base URL is overridable at build time:
//   flutter run --dart-define=API_BASE_URL=https://api.your-server.com
// Default: the production tunnel on the Windows server (24/7).
class AppConfig {
  static const _defined = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_defined.isNotEmpty) return _defined;
    return 'https://fitcoach.veridianabode.in';
  }

  // AdMob settings --------------------------------------------------------
  // Generate your real IDs from https://apps.admob.com after creating an
  // AdMob account. Empty string = ads disabled (no banner shown).
  static const String adMobAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String adMobAppIdIos = 'ca-app-pub-3940256099942544~1458002511';
  // Banner unit IDs (the 3940... IDs are Google's test units).
  static const String bannerAdUnitAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String bannerAdUnitIos = 'ca-app-pub-3940256099942544/2934735716';

  static bool get adsEnabled => true;
}
