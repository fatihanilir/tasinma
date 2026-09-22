# Ev Alım Hesaplayıcı - Flutter App

iOS, Android ve Web için tek kod tabanıyla çalışan ev alım hesaplayıcı uygulaması.

## Özellikler

- ✅ Ev fiyatı, nakit, tadilat masrafı hesaplama
- ✅ Vergi ve komisyon seçenekleri
- ✅ 60 ve 120 ay kredi taksit hesaplama
- ✅ Google / Apple ile giriş (Firebase Auth)
- ✅ Hesaplamaları buluta kaydetme (Firestore)
- ✅ iOS, Android ve Web desteği

## Kurulum

### 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com)'a gidin
2. "Proje ekle" ile yeni proje oluşturun (örn: `ev-hesap-app`)
3. **Authentication** bölümünden:
   - "Başlayın" tıklayın
   - **Google** sağlayıcısını etkinleştirin
   - **Apple** sağlayıcısını etkinleştirin (iOS için)
4. **Firestore Database** bölümünden:
   - "Veritabanı oluştur" tıklayın
   - "Test modunda başlat" seçin (sonra kuralları güncelleriz)

### 2. Flutter Firebase CLI Kurulumu

```bash
# FlutterFire CLI'ı kur
dart pub global activate flutterfire_cli

# Firebase'e giriş yap
firebase login

# Proje dizininde Firebase yapılandırması oluştur
cd /Users/fatih.anilir/Desktop/Tasinma
flutterfire configure
```

Bu komut `lib/firebase_options.dart` dosyasını otomatik güncelleyecek.

### 3. Platform Spesifik Ayarlar

#### iOS
```bash
cd ios
pod install
cd ..
```

`ios/Runner/Info.plist` dosyasına ekleyin:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Google Sign-In için -->
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

#### Android
`android/app/build.gradle.kts` dosyasında `minSdk` değerini kontrol edin (en az 21 olmalı).

Firebase Console'dan `google-services.json` dosyasını indirin ve `android/app/` klasörüne koyun.

#### Web
Firebase Console'dan Web app ekleyin ve yapılandırma değerlerini `lib/firebase_options.dart`'a kopyalayın.

### 4. Firestore Güvenlik Kuralları

Firebase Console > Firestore > Rules bölümünde:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar sadece kendi verilerini okuyup yazabilir
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Uygulamayı Çalıştırma

```bash
# Web'de çalıştır
flutter run -d chrome

# iOS simülatörde çalıştır (Xcode gerekli)
flutter run -d ios

# Android emülatörde çalıştır (Android Studio gerekli)
flutter run -d android
```

## Proje Yapısı

```
lib/
├── main.dart              # Uygulama giriş noktası
├── firebase_options.dart  # Firebase yapılandırması
├── models/
│   └── home_model.dart    # Ev veri modeli
├── providers/
│   ├── auth_provider.dart # Auth state yönetimi
│   └── homes_provider.dart# Evler state yönetimi
├── screens/
│   ├── auth_screen.dart   # Giriş ekranı
│   ├── home_screen.dart   # Ana ekran
│   ├── calculator_screen.dart # Hesap makinesi
│   ├── saved_homes_screen.dart # Kayıtlı evler listesi
│   └── home_detail_sheet.dart # Ev detay bottom sheet
├── services/
│   ├── auth_service.dart  # Firebase Auth servisi
│   └── database_service.dart # Firestore servisi
├── theme/
│   └── app_theme.dart     # Tema ve renkler
├── utils/
│   └── formatters.dart    # Sayı formatlama
└── widgets/
    ├── cost_breakdown.dart
    ├── hero_card.dart
    ├── home_list_card.dart
    ├── money_input.dart
    ├── payment_card.dart
    ├── segment_control.dart
    └── text_input.dart
```

## Sonraki Adımlar

- [ ] Firebase projesini oluştur
- [ ] `flutterfire configure` çalıştır
- [ ] iOS için Xcode kur ve pod install yap
- [ ] Android için Android Studio kur
- [ ] Uygulamayı test et
- [ ] App Store ve Play Store'a yükle
