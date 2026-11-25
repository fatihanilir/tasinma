# Cebinden Eve — kaldığın yerden devam

Bu dosya, Cursor sohbetindeki kararları ve bekleyen işleri özetler.
Yeni bilgisayarda: `git checkout cursor/ev-alim-hesaplayici` → Cursor’a
“DEVAM.md’yi oku, kaldığımız yerden devam et” de.

**Şifre / anahtar dosyası yok.** İmza anahtarı GitHub’da değildir.

---

## Proje özeti

- **Site:** https://cebindeneve.com — Flutter web hesaplayıcı `/hesapla/`,
  statik rehber/araçlar `site/` + `tools/build_site.py`.
- **Firebase proje:** `cebinden-eve` (hesap: `ffatihanilir@gmail.com`)
- **Paket / bundle ID:** `com.cebindeneve.app` (Android + iOS aynı)
- **Git dalı:** `cursor/ev-alim-hesaplayici` → `github.com/fatihanilir/tasinma`
- **Öncelik:** AdSense onayı + Play Store / App Store yayın + AdMob geliri.
  Asıl ürün uygulama (`/hesapla` / native app); site AdSense ve organik trafik için.

## Yerelde çalıştırma

```bash
git clone https://github.com/fatihanilir/tasinma.git && cd tasinma
git checkout cursor/ev-alim-hesaplayici
flutter pub get
tools/build_all.sh          # public/ üretir (gitignore’da)
firebase login              # ffatihanilir@gmail.com
firebase serve --only hosting --host 0.0.0.0 --port 5000
# http://127.0.0.1:5000/
```

Yayına almak: `tools/build_all.sh && firebase deploy --only hosting`

Android AAB: `flutter build appbundle --release`  
Çıktı: `build/app/outputs/bundle/release/app-release.aab`

## Taşınması gereken (GitHub dışı)

`~/cebindeneve-keys/` klasörünü USB / AirDrop ile yeni Mac’e aynı yola kopyala:

- `upload-keystore.jks` — Play güncelleme imzası (kaybedersen güncelleme yükleyemezsin)
- `key.properties` — şifreler burada

Upload SHA-1 (Firebase’e kayıtlı):  
`3D:14:DB:C9:89:63:DE:37:5E:EA:6D:B4:8B:73:D1:58:77:54:0C:27`

---

## AdSense (web)

- Yayıncı: `ca-pub-8974319907510791`
- Ret nedeni (yaklaşık): düşük değerli içerik + politika. `/hesapla` Flutter canvas
  AdSense’e uygun değil → reklamsız + `noindex`. Reklam sadece içerik sayfalarında.
- `ads: no` sayfalar: destek, gizlilik, hakkimizda, hesap-silme, iletisim, kosullar, 404.
- Sitemap gönderildi (~30 sayfa). İnceleme isteği için: 2–4 hafta trafik + indeks bekle;
  acele etme. Trafiği ana sayfa / rehberlere yönlendir (`/hesapla` değil).
- `ads.txt`: `google.com, pub-8974319907510791, DIRECT, f08c47fec0942fa0`

## AdMob (uygulama) — gerçek kimlikler kodda

| | Kimlik |
|---|---|
| Android App ID | `ca-app-pub-6659689615274144~2500061789` |
| Android Banner | `ca-app-pub-6659689615274144/6382245284` |
| iOS App ID | `ca-app-pub-6659689615274144~2443000277` |
| iOS Banner | `ca-app-pub-6659689615274144/4177260484` |

- AdMob yayıncı numarası AdSense’ten **farklı** (`6659…` vs `8974…`) — ayrı hesap;
  AdMob’da ödeme bilgisi ayrıca girilmeli.
- `app-ads.txt` yayında: https://cebindeneve.com/app-ads.txt  
  Play / App Store “web sitesi” alanına `https://cebindeneve.com` yazılacak.
- Debug derlemede Google test reklamları; release’te gerçek birimler.
- AB izin formu (UMP) kodda var; AdMob’da Privacy & messaging → GDPR mesajı yayınlanmalı.

## Firebase / Google Cloud

- Web / Android / iOS uygulamaları Firebase’de kayıtlı.
- App Check: web’de Recaptcha; mobilde şimdilik kapalı (başlatırken çökme/hata).
- Authentication’da **Apple** giriş yöntemini açmak iOS için gerekli (henüz kullanıcıya kaldı).
- Google ile giriş sağlayıcısı açık olmalı. Web client ID
  (`lib/firebase_options.dart` → `googleServerClientId`):
  `381980641519-hskendkgt9ivm58pp0rkdus1cti9d0se.apps.googleusercontent.com`
  Firebase Authentication → Google ekranındaki Web client ID bununla aynı kalacak.
- Cloud **Android key (auto created by Firebase)** kısıtı **None**.
  Boş **Android apps** listesiyle kaydetme; anahtar bütün uygulamaları reddeder.
  iOS anahtarı iOS uygulamalarına, Browser anahtarı HTTP referrer’a kısıtlı.
- OAuth consent: **In production**, **External**. **Back to testing** / **Make internal** yok.

Play’in uygulama imzalama SHA-1’i Firebase’e eklendi (21 Kas 2026).
Android OAuth istemcisi aynı gün oluştu, parmak izi bununla aynı:

`F0:C9:60:74:75:AD:6F:FE:22:53:C8:3F:8C:5A:E4:9E:1E:91:9A:75`

Firebase’de duran diğer parmak izleri: upload SHA-1 `3D:14:DB:…`,
bir SHA-1 daha `AC:95:56:…`, upload SHA-256 `A7:95:B6:…`.
**Play’den kurulan APK’nın gerçek imzası** (telefondan `apksigner` ile okundu, 24 Kas 2026).
Google ile giriş bu ikisi Firebase’e eklenince çalıştı:

- SHA-1 `06:52:DC:A3:27:46:DB:D5:77:41:B2:11:02:88:6B:7F:17:DA:6D:F0`
- SHA-256 `3D:7D:68:A3:BA:19:28:3F:F2:B1:37:53:8A:0F:A8:2F:BD:AF:3D:53:F5:BE:B9:19:AD:6B:01:35:62:08:C9:0F`

`F0:C9:60…` ve `CF:9F:E0…` Play sayfasından kopyalandı ama yüklü APK’ya uymadı.
Firebase’de zararsız; silme. Emin olmak için Play sayfasına değil, kurulu APK’ya bak:
`adb shell pm path com.cebindeneve.app` → `adb pull` → `apksigner verify --print-certs`.

## Play Console — 23 Kas 2026

Hesap kişisel, kimlik doğrulandı. Uygulama: Cebinden Eve,
`com.cebindeneve.app`, Türkçe, ücretsiz. Satıcı beyanı: satıcı hesabı değil.

Bitenler: veri güvenliği, reklam kimliği (evet, amaç reklam), devlet uygulaması hayır,
finans özelliği yok, içerik derecelendirmesi, hedef kitle 18+, reklam beyanı,
gizlilik `https://cebindeneve.com/gizlilik`, hesap silme `https://cebindeneve.com/hesap-silme`.
Mağaza ayarı: kategori Finans, e-posta `info@cebindeneve.com`, site `https://cebindeneve.com`,
telefon boş. Mağaza girişi kaydedildi. Yapay zeka beyanı: öğeleri etiketleme.

Kapalı test (Alpha) sürümü `1.0.0 (1)` yayında. Kanal **Etkin**.
Ülkeler: Türkiye ve Pakistan, ikisi de **Hedeflenen**. Yeni sürüm oluşturma.
Test listesi **MyLocation**, 25 e-posta (25 Kas 2026). Listeye yazmak katılım
sayılmaz. Sayaç, bağlantıyı açıp katılan kişi 12 olunca başlar.
Herkese açık mağaza adresi açılmaz. Katılım bağlantısı:
`https://play.google.com/apps/testing/com.cebindeneve.app`

Fiverr: Touseef Ijaz, 14 gün / testçi siparişi satın alındı. Satıcıya Play
Console erişimi verilmez. Yalnızca bu bağlantı ve listedeki Gmail’ler.
Testçiler bağlantıyı aynı Gmail ile açıp katılacak, kuracak, uygulamayı bir kez
açacak ve 14 gün çıkmayacak.

Play paket ekranındaki DEX optimizasyonu %26 ve 16 KB notu ret değildir.
SafetyNet bildirimi de ret değildir (`firebase_app_check`, mobilde kapalı).

Üretim kilitli. **Üretime başvur** gri kalır. Şart: en az 12 kişi aynı anda
kayıtlı kalsın, sonra 14 gün. E-posta listesine yazmak yetmez; bağlantıdan katılmak sayılır.

Yüklenen AAB bu Windows makinede üretildi:
`build/app/outputs/bundle/release/app-release.aab` (20 Kas 2026).
İmza doğrulandı. Flutter’ın native sembol soyma adımı cmdline-tools yüzünden
exit 1 verdi; paket yine de oluştu. cmdline-tools sonradan kuruldu, temiz
yeniden derleme yapılmadı. JAVA_HOME PyCharm JBR olmasın
(`jlink` yok). Bu makinede Temurin 17:
`C:\Users\Fatih-ANILIR\jdks\jdk-17.0.21.1+2`.

Mağaza görselleri `store/play/` içinde:

- `icon-512.png` — 512×512
- `feature-1024x500.png` — 1024×500
- `01-giris.png`, `02-hesap.png`, `03-faiz.png`, `04-taksit.png`, `05-kirilim.png`
  — 1080×1920

Anahtar klasörü bu makineye kopyalandı:
`C:\Users\Fatih-ANILIR\cebindeneve-keys\` (`upload-keystore.jks`, `key.properties`).
`key.properties` içindeki `storeFile` Windows yoluna çevrildi. Şifreler dosyada;
buraya yazma. Mac’teki asıl kopya `~/cebindeneve-keys/` duruyor olmalı.
`firebase login` bu Windows makinede yapıldı (`ffatihanilir@gmail.com`).

## Google ile giriş — çözüldü (24 Kas 2026)

Play’den kurulan sürümde Google ile giriş çalışıyor. Sebep: yüklü APK’nın
imzası Firebase’e eklenen parmak izleriyle uyuşmuyordu. Yukarıdaki
`06:52:DC…` SHA-1 ve `3D:7D:68…` SHA-256 eklenince düzeldi.

Uygulamadaki hata metni bütün istisnaları yutuyor (`lib/providers/auth_provider.dart`
→ `_friendlyError`); gerçek kod için `adb logcat`.

Sıradaki: Fiverr testçilerinin katılımını bekle. Kontrol panelinde kayıtlı
testçi 12 olunca 14 gün sayacı başlar. Ondan önce üretime başvurma.
**Yeni sürüm oluştur**ma.

Play bildirimi (23 Kas): `play-services-safetynet:18.0.0` kullanımdan kalkıyor.
Kaynak `firebase_app_check`; mobilde etkinleştirilmiyor. Ret değil, testi durdurmaz.

## App Store / Xcode

- Apple Developer alındı. Xcode **26.6** bu Mac’te kurulu (`/Applications/Xcode.app`).
- Bundle: `com.cebindeneve.app` (Android ile aynı).
- iOS kod: Apple ile giriş butonu (yalnızca iOS), `Runner.entitlements` (Sign In with Apple),
  AdMob App ID `Info.plist`’te hazır. `DEVELOPMENT_TEAM` henüz boş — Xcode’da Team seçilecek.
- **Biten (25 Kas 2026):** Firebase Authentication → Apple açık (Service ID boş = native iOS için
  normal; web Apple girişi yoksa gerekmez). developer.apple.com → App ID `com.cebindeneve.app`,
  Sign In with Apple, Primary App ID. App Store Connect’te uygulama: **Cebinden Eve**.
- **Eksik:** `ios/Runner/GoogleService-Info.plist` repoda yok — Firebase Console → Project
  settings → iOS app → Download; `ios/Runner/` altına koy.
- **Biten:** Xcode hesabı `fatihanilir@icloud.com`. Team **FATIH ANILIR** (ID `A7GD3M5C8D`, Individual, Admin). **MESUT KUZU** seçilmeyecek. Bundle `com.cebindeneve.app`. Sign In with Apple capability duruyor. Hedef: Any iOS Device.
- **Biten (25 Kas 12:27):** iPhone bir kez takıldı, development profili oluştu. Signing Certificate: Apple Development FATIH ANILIR (`2B8KLP38FW`). Kırmızı cihaz hatası gitti. Telefonun bağlı kalması gerekmez.
- **Archive iptali (25 Kas 12:28):** Saniyede düşüyordu. Sebep: bu Mac’te Flutter 3.41.7 / Dart 3.11.5, proje Dart ^3.12.2 istiyor. `ios/Flutter/Generated.xcconfig` ve `FlutterGeneratedPluginSwiftPackage` yoktu; Xcode bunu Build Canceled yazdı.
- **Düzeltildi:** Flutter **3.50.1** (Dart 3.14.0). `flutter pub get` ile iOS dosyaları üretildi.
- **Yüklendi (25 Kas 14:00):** Xcode Organizer’da Runner 1.0.0 (1), `com.cebindeneve.app`, Team FATIH ANILIR. Durum: **Uploaded with warnings**. Uyarılar ret değil (iOS 26.5 SDK notu, Nisan 2027’ye kadar; Firebase/Google dSYM eksikleri).
- **İşlendi (25 Kas 14:10):** TestFlight’ta 1.0.0 (1) upload **Complete**, sürüm durumu **Ready to Submit**. Sarı nokta hata değil. 90 gün içinde incelemeye eklenmezse build düşer.
- **Mağaza sayfası (25 Kas, kaydedildi):** Türkçe tanıtım, açıklama, anahtar kelimeler, destek ve pazarlama URL’si, telif `2026 Fatih Anılır`. Kategori Finance, alt başlık “Evin gerçek maliyeti”. Fiyat $0. Çin ana karası hariç 174 ülke. Gizlilik URL `https://cebindeneve.com/gizlilik`. iPhone ekran görüntüleri 1206×2622. Build 1 sürüm sekmesinde.
- **Gizlilik yayınlandı (25 Kas):** 8 veri türünün amacı dolduruldu ve Publish edildi. E-posta, diğer finansal bilgi, müşteri desteği, kullanıcı kimliği, ürün etkileşimi: kimliğe bağlı, izleme yok. Kaba konum ve cihaz kimliği: analitik + üçüncü taraf reklam, izleme var. Reklam verisi: üçüncü taraf reklam, izleme var.
- **Yaş sınırı kaydedildi:** 4+. Reklam var; kısıtlamasız web, kullanıcı içeriği, sosyal, mesajlaşma, kumar, tıbbi içerik yok. “Not Applicable” (çocuklara özel değil, yükseltilmedi).
- **Content Rights kaydedildi:** “No, this app does not contain, show, or access third-party content.”
- **İnceleme bilgisi kaydedildi:** telefon `+905377356183`, ad fatih, soyad anılır, e-posta `info@cebindeneve.com`. Sign-in required kapalı (kullanıcı adı/şifre yok). Not: hesaplama giriş gerektirmez, Google/Apple yalnızca kaydetmek için, ücretsiz ve reklamlı. Yayın: **Manually release this version** (onaydan sonra kendiliğinden yayına girmez).
- **iPad görselleri (25 Kas):** 13 inç slotuna 5 adet 2064×2752 yüklendi (giriş, hesap, faiz, taksit, kırılım). iPhone dosyaları bu slota konmadı.
- **İncelemeye gönderildi (25 Kas 17:17):** Draft Submission → Submit for Review. Sonuç: **1 Item Submitted**, iOS App 1.0 / 1.0.0 (1). Apple en fazla 48 saat diyor; bitince e-posta gelir. Onaydan sonra elle yayınlanacak. Çin ana karası uyum formları doldurulmadı (uygulama orada satılmıyor). Xcode’da yeniden yükleme yok.
- **TestFlight iç grup (25 Kas 17:35):** Grup adı Fatih. `fatihanilir@icloud.com` (Fatih ANILIR) eklendi, durum Invited. Build 1 grupta. Beta incelemesi yok; telefonda TestFlight uygulaması aynı Apple ID ile açılınca kurulur.
- **Klavye düzeltmesi → 1.0.0 (2) (25 Kas):** Mobilde Scaffold artık klavyeye göre küçülüyor (web'de eskisi gibi küçülmüyor). İlan linki/Başlık gibi alt alanlar klavyenin üstüne kayıyor. Klavye açıkken altta "Klavyeyi kapat" çubuğu çıkıyor, Yeni ev/Kaydet ve sabit reklam gizleniyor, kaydırınca klavye iniyor. Test: `test/keyboard_test.dart`. pubspec `1.0.0+2`.
  - iOS: Xcode → Archive → yükle (build 2). TestFlight "Fatih" grubuna otomatik düşer. İncelemedeki build 1 için: ya onaylanınca 1.0.0 (2)'yi güncelleme olarak gönder, ya da incelemeden çekip build 2'yi seçip yeniden gönder.
  - Android: AAB Windows'ta derlenmeli (anahtar `C:\Users\Fatih-ANILIR\cebindeneve-keys\`; bu Mac'te yok). Kapalı test (Alpha) kanalına yeni sürüm olarak yükle. 14 günlük sayaç sıfırlanmaz, test kullanıcıları güncellemeyi Play'den otomatik alır.

## Ürün kararları (kısa)

- Logo tıklanınca web’de ana sayfaya döner; native app’te no-op.
- `/hesapla` yavaş: splash + logo küçültme + ana sayfada `main.dart.js` prefetch.
- 24 Kas 2026: `firebase.json`’daki `no-cache` → `public, max-age=0, must-revalidate,
  s-maxage=31536000`. `no-cache` Firebase CDN’de her isteği MISS yapıyordu; şimdi HIT.
  Firebase her deploy’da CDN önbelleğini kendisi temizler. Yayında.
- Kalan yavaşlık Firebase/Fastly (Milano POP) yolunda: `main.dart.js` HTTP/2 ile
  rastgele 40–60 sn. gstatic / storage.googleapis.com aynı ağda hep <1 sn.
  Çözüm seçeneği: `main.dart.js`’i Cloud Storage’dan sunmak (Blaze gerekir) ya da
  deferred import ile bölmek. Kullanıcı şimdilik bırakmayı seçti.
- Ev fiyatı girilmeden mobil reklam slotu gösterilmiyor (boş ekranda reklam yok).
- Sticky banner ile Kaydet butonu arasında boşluk (kazara tıklama politikası).
- Trafik / reklam linkleri: ana sayfa veya rehber; UTM önerilir.

## Destek e-postaları

- `info@cebindeneve.com` (destek)
- Admin: `ffatihanilir@gmail.com`

---

*Son güncelleme: 2026-11-25 — App Store 1.0 incelemeye gönderildi (manuel yayın). Play kapalı test devam. Klavye düzeltmesi 1.0.0+2 hazır, yüklenmedi.*
