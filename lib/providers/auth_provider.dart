import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../utils/app_links.dart';

enum DeleteAccountResult { deleted, needsPassword, cancelled, failed }

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static const _guestKey = 'guest_continued';

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _guestContinued = false;
  bool _ready = false;
  bool _profileReady = false;
  int _consentVersion = 0;
  bool _consentChecked = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get guestContinued => _guestContinued;
  /// Yalnızca ilk açılışta bekletir; sonraki girişlerde ekran ağacı korunur.
  bool get isReady => _ready;
  bool get canUseApp => isAuthenticated || _guestContinued;
  bool get isAdmin => _user?.email?.toLowerCase() == AppLinks.adminEmail;
  bool get usesPassword => _authService.signInProvider == 'password';

  /// Giriş ekranındaki "okudum, onaylıyorum" kutusu.
  bool get consentChecked => _consentChecked;
  bool get needsConsent =>
      isAuthenticated && _profileReady && _consentVersion < AppLinks.legalVersion;
  bool get isAppleSignInAvailable => _authService.isAppleSignInAvailable;

  /// Premium gelene kadar herkese açık; premium'da kapanacak.
  bool get isPremium => false;
  bool get showAds => !isPremium;

  /// Misafir: hesapta sticky takip. Girişli: maliyet kırılımı altı sabit.
  bool get showStickyCalculatorAd => showAds && !isAuthenticated;
  bool get showFixedCalculatorAd => showAds && isAuthenticated;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Misafir bayrağı kalıcı değil: her açılışta giriş ekranı gelsin.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    _guestContinued = false;

    _authService.authStateChanges.listen((user) {
      final changed = user?.uid != _user?.uid;
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
        _guestContinued = false;
        if (changed) {
          _profileReady = false;
          _syncProfile(user);
        }
      } else {
        _profileReady = false;
        _consentVersion = 0;
        if (_status != AuthStatus.loading) {
          _status = AuthStatus.unauthenticated;
        }
        _ready = true;
      }
      notifyListeners();
    });
  }

  Future<void> _syncProfile(User user, {bool accept = false}) async {
    try {
      _consentVersion = await _userService.syncProfile(
        user,
        acceptConsentVersion:
            (accept || _consentChecked) ? AppLinks.legalVersion : null,
      );
    } catch (e) {
      // Profil yazılamazsa (ağ vb.) kullanıcıyı kilitlemeyelim.
      debugPrint('Profile sync error: $e');
      _consentVersion = AppLinks.legalVersion;
    }
    if (_user?.uid != user.uid) return;
    _profileReady = true;
    _ready = true;
    notifyListeners();
  }

  void setConsentChecked(bool value) {
    _consentChecked = value;
    if (value && _errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  Future<void> acceptConsent() async {
    final user = _user;
    if (user == null) return;
    await _syncProfile(user, accept: true);
  }

  bool _requireConsent() {
    if (_consentChecked) return true;
    _errorMessage =
        'Devam etmek için Gizlilik Politikası ve Kullanım Koşulları\'nı onaylayın.';
    notifyListeners();
    return false;
  }

  void _logAuth(UserCredential? result, String method) {
    final isNew = result?.additionalUserInfo?.isNewUser ?? false;
    final future = isNew
        ? _analytics.logSignUp(signUpMethod: method)
        : _analytics.logLogin(loginMethod: method);
    future.catchError((_) {});
  }

  /// Önce yeniden doğrular, sonra evleri, profili ve hesabı siler.
  Future<DeleteAccountResult> deleteAccount({String? password}) async {
    if (_user == null) return DeleteAccountResult.failed;
    if (usesPassword && (password == null || password.isEmpty)) {
      return DeleteAccountResult.needsPassword;
    }
    try {
      await _authService.reauthenticate(password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'reauth-cancelled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return DeleteAccountResult.cancelled;
      }
      _errorMessage = _mapFirebaseError(e);
      notifyListeners();
      return DeleteAccountResult.failed;
    } catch (e) {
      if (e.toString().contains('popup-closed-by-user')) {
        return DeleteAccountResult.cancelled;
      }
      _errorMessage = 'Kimlik doğrulanamadı';
      notifyListeners();
      return DeleteAccountResult.failed;
    }

    try {
      final uid = _user!.uid;
      await DatabaseService().deleteAllUserData();
      await _userService.deleteProfile(uid);
      await _authService.deleteCurrentUser();
      _analytics.logEvent(name: 'account_deleted').catchError((_) {});
      _consentChecked = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return DeleteAccountResult.deleted;
    } catch (e) {
      debugPrint('Delete account error: $e');
      _errorMessage =
          'Hesap silinemedi. Lütfen tekrar deneyin veya ${AppLinks.supportEmail} adresine yazın.';
      notifyListeners();
      return DeleteAccountResult.failed;
    }
  }

  Future<void> continueAsGuest() async {
    // Sadece bu oturum; sayfa yenilenince tekrar giriş ekranı açılır.
    _guestContinued = true;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (!_requireConsent()) return false;
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _logAuth(result, 'google');
        await _clearGuestFlag();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (!_requireConsent()) return false;
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.signInWithEmail(email, password);
      _logAuth(result, 'email');
      await _clearGuestFlag();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Giriş yapılamadı';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    if (!_requireConsent()) return false;
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.registerWithEmail(email, password);
      _logAuth(result, 'email');
      await _clearGuestFlag();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Kayıt oluşturulamadı';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await _clearGuestFlag();
      _guestContinued = false;
      _consentChecked = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Çıkış yapılamadı';
      notifyListeners();
    }
  }

  Future<void> _clearGuestFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, false);
    _guestContinued = false;
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'too-many-requests':
        return 'Çok fazla deneme, biraz bekle';
      case 'user-mismatch':
        return 'Farklı bir hesapla doğrulama yapıldı';
      case 'requires-recent-login':
        return 'Güvenlik için çıkış yapıp tekrar giriş yaptıktan sonra deneyin';
      default:
        return e.message ?? 'Bir hata oluştu';
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('popup-closed-by-user')) {
      return 'Giriş penceresi kapatıldı';
    }
    return 'Google ile giriş yapılamadı';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
