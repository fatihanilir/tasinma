/// Web'de AdMob yok; uygulama ekranları reklamsız.
class AdsService {
  AdsService._();

  static Future<bool> get ready async => false;
  static Future<void> init() async {}
  static Future<bool> get privacyOptionsRequired async => false;
  static Future<void> showPrivacyOptions() async {}
}
