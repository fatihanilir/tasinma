import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob reklam birimleri. Debug derlemede her zaman Google'ın test
/// kimlikleri kullanılır (kendi reklamına tıklamak hesabı riske atar).
class AdMobIds {
  static const _androidBanner = 'ca-app-pub-6659689615274144/6382245284';
  static const _iosBanner = 'ca-app-pub-6659689615274144/4177260484';

  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testIosBanner = 'ca-app-pub-3940256099942544/2435281174';

  static String get banner {
    if (kDebugMode) {
      return Platform.isIOS ? _testIosBanner : _testAndroidBanner;
    }
    return Platform.isIOS ? _iosBanner : _androidBanner;
  }
}

class AdsService {
  AdsService._();

  static final _ready = Completer<bool>();

  /// Reklam yüklemeden önce beklenir; false ise reklam gösterilmez.
  static Future<bool> get ready => _ready.future;

  /// AB/İngiltere kullanıcılarından Google'ın zorunlu tuttuğu izin formu
  /// alınır, ardından SDK başlatılır.
  static Future<void> init() async {
    if (_ready.isCompleted) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      _ready.complete(false);
      return;
    }
    try {
      await _gatherConsent().timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (canRequest) await MobileAds.instance.initialize();
      _ready.complete(canRequest);
    } catch (e) {
      debugPrint('AdMob init error: $e');
      if (!_ready.isCompleted) _ready.complete(false);
    }
  }

  static Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!done.isCompleted) done.complete();
        });
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  /// Ayarlar ekranından izinleri yeniden düzenleme (AB kullanıcıları için).
  static Future<bool> get privacyOptionsRequired async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  static Future<void> showPrivacyOptions() =>
      ConsentForm.showPrivacyOptionsForm((_) {});
}
