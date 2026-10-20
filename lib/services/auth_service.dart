import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  String? get signInProvider {
    final providers = currentUser?.providerData ?? const [];
    return providers.isEmpty ? null : providers.first.providerId;
  }

  /// Hesap silme öncesi Firebase yakın tarihli giriş ister.
  Future<void> reauthenticate({String? password}) async {
    final user = currentUser;
    if (user == null) return;
    if (signInProvider == 'password') {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password!),
      );
      return;
    }
    if (signInProvider == 'google.com') {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(GoogleAuthProvider());
        return;
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'reauth-cancelled');
      }
      final googleAuth = await googleUser.authentication;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
    }
  }

  Future<void> deleteCurrentUser() async {
    await currentUser?.delete();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Apple web için ayrı Firebase + Apple Developer kurulumu gerekir.
  bool get isAppleSignInAvailable => !kIsWeb;
}
