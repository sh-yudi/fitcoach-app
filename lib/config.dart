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
  // Set adsEnabled to true and replace these with real IDs from
  // https://apps.admob.com before publishing to app stores.
  static const String adMobAppIdAndroid = '';
  static const String adMobAppIdIos = '';
  static const String bannerAdUnitAndroid = '';
  static const String bannerAdUnitIos = '';

  static bool get adsEnabled => false;
}
