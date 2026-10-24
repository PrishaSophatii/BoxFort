import 'package:flutter/foundation.dart';

/// AdMob IDs.
///
/// Debug builds always use Google's public test ads, so you can never get
/// your AdMob account flagged for clicking your own ads while developing.
/// Release builds use the real IDs below once you fill them in from
/// https://apps.admob.com (Apps > your app > Ad units).
///
/// The *app* IDs also go in android/app/src/main/AndroidManifest.xml and
/// ios/Runner/Info.plist.
class AdIds {
  // TODO(launch): replace with your real ad unit IDs from AdMob.
  static const _androidBanner = '';
  static const _androidInterstitial = '';
  static const _androidRewarded = '';
  static const _iosBanner = '';
  static const _iosInterstitial = '';
  static const _iosRewarded = '';

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String _pick(String real, String test) =>
      kReleaseMode && real.isNotEmpty ? real : test;

  static String get banner => _ios
      ? _pick(_iosBanner, 'ca-app-pub-3940256099942544/2435281174')
      : _pick(_androidBanner, 'ca-app-pub-3940256099942544/9214589741');

  static String get interstitial => _ios
      ? _pick(_iosInterstitial, 'ca-app-pub-3940256099942544/4411468910')
      : _pick(_androidInterstitial, 'ca-app-pub-3940256099942544/1033173712');

  static String get rewarded => _ios
      ? _pick(_iosRewarded, 'ca-app-pub-3940256099942544/1712485313')
      : _pick(_androidRewarded, 'ca-app-pub-3940256099942544/5224354917');
}
