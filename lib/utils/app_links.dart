import 'package:url_launcher/url_launcher.dart';

class AppLinks {
  static const String supportEmail = 'info@cebindeneve.com';
  static const String adminEmail = 'ffatihanilir@gmail.com';

  static const String site = 'https://cebindeneve.com';
  static const String privacy = '$site/gizlilik';
  static const String terms = '$site/kosullar';
  static const String support = '$site/destek';
  static const String accountDeletion = '$site/hesap-silme';
  static const String analyticsConsole =
      'https://console.firebase.google.com/project/cebinden-eve/analytics';

  /// Metinler değişince artırılır; kullanıcılardan yeniden onay istenir.
  static const int legalVersion = 1;

  static Future<void> open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<void> mail({String subject = 'Cebinden Eve destek'}) async {
    await launchUrl(
      Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: 'subject=${Uri.encodeComponent(subject)}',
      ),
    );
  }
}
