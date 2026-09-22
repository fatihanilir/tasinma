import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  static const _guestKey = 'guest_continued';

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _guestContinued = false;
  bool _ready = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get guestContinued => _guestContinued;
  bool get isReady => _ready;
  bool get canUseApp => isAuthenticated || _guestContinued;
  bool get isAppleSignInAvailable => _authService.isAppleSignInAvailable;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _guestContinued = prefs.getBool(_guestKey) ?? false;

    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
        _guestContinued = false;
      } else if (_status != AuthStatus.loading) {
        _status = AuthStatus.unauthenticated;
      }
      _ready = true;
      notifyListeners();
    });
  }

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
    _guestContinued = true;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.signInWithGoogle();
      if (result != null) {
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
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.signInWithEmail(email, password);
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
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _authService.registerWithEmail(email, password);
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
