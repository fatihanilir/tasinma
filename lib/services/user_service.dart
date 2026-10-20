import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProfileState {
  final int consentVersion;
  final bool blocked;

  const UserProfileState({required this.consentVersion, required this.blocked});
}

/// `users/{uid}` dokümanı: yalnızca e-posta ve hesap/onay tarihleri tutulur.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Profili oluşturur/günceller; onay sürümünü ve engel durumunu döndürür.
  Future<UserProfileState> syncProfile(
    User user, {
    int? acceptConsentVersion,
  }) async {
    final ref = _doc(user.uid);
    final blocked = await isBlocked(user.email);
    if (blocked) {
      return const UserProfileState(consentVersion: 0, blocked: true);
    }
    final snap = await ref.get();
    final existing = snap.data() ?? const <String, dynamic>{};
    final stored = (existing['consentVersion'] as num?)?.toInt() ?? 0;

    final data = <String, dynamic>{
      'email': user.email,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      // Profil sonradan eklendiği için eski hesaplarda gerçek kayıt tarihi.
      final created = user.metadata.creationTime;
      data['createdAt'] = created != null
          ? Timestamp.fromDate(created)
          : FieldValue.serverTimestamp();
    }
    if (!existing.containsKey('homeCount')) {
      final homes = await ref.collection('homes').count().get();
      data['homeCount'] = homes.count ?? 0;
    }
    final accepts =
        acceptConsentVersion != null && acceptConsentVersion > stored;
    if (accepts) {
      data['consentVersion'] = acceptConsentVersion;
      data['consentAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
    return UserProfileState(
      consentVersion: accepts ? acceptConsentVersion : stored,
      blocked: false,
    );
  }

  Future<bool> isBlocked(String? email) async {
    if (email == null || email.isEmpty) return false;
    final snap = await _firestore.collection('blockedEmails').doc(email).get();
    return snap.exists;
  }

  Future<void> deleteProfile(String uid) => _doc(uid).delete();
}
