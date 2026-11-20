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
- API anahtarları Cloud Console’da kısıtlandı (Android SHA, iOS bundle, web siteleri).
- App Check: web’de Recaptcha; mobilde şimdilik kapalı (başlatırken çökme/hata).
- Authentication’da **Apple** giriş yöntemini açmak iOS için gerekli (henüz kullanıcıya kaldı).
- Play’den sonra Google’ın **App signing SHA-1**’ini Firebase + Cloud Android anahtarına ekle.

## Play Console — sıradaki

1. Hesap kurulumu bitince (kimlik / telefon / cihaz doğrulama) uygulamayı oluştur.
2. Zorunlu formlar: gizlilik `https://cebindeneve.com/gizlilik`, reklam var, 18+,
   hesap silme `https://cebindeneve.com/hesap-silme`, veri güvenliği (e-posta, analytics,
   reklam kimliği, isteğe bağlı kayıtlar).
3. Mağaza: ikon 512, feature graphic 1024×500, ≥2 ekran görüntüsü, site URL.
4. Kapalı test: AAB yükle, ≥12 testçi, 14 gün. Yeni kişisel hesapta şart.
5. “Uygulama imzalama” SHA-1’ini buraya / Cursor’a ilet → Firebase’e eklenecek.

## App Store / Xcode

- Apple Developer alındı. Xcode cuma sonrası kurulacak (Mac şart).
- iOS: Apple ile giriş butonu (yalnızca iOS), entitlements, AdMob App ID Info.plist’te hazır.
- Bundle: `com.cebindeneve.app`

## Ürün kararları (kısa)

- Logo tıklanınca web’de ana sayfaya döner; native app’te no-op.
- `/hesapla` yavaş: splash + logo küçültme + ana sayfada `main.dart.js` prefetch.
- Ev fiyatı girilmeden mobil reklam slotu gösterilmiyor (boş ekranda reklam yok).
- Sticky banner ile Kaydet butonu arasında boşluk (kazara tıklama politikası).
- Trafik / reklam linkleri: ana sayfa veya rehber; UTM önerilir.

## Destek e-postaları

- `info@cebindeneve.com` (destek)
- Admin: `ffatihanilir@gmail.com`

---

*Son güncelleme: 2026-11-20 — AdMob kimlikleri canlıda, AAB derlendi, Play hesap kurulumu kullanıcıda.*
