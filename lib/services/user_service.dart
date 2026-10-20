import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// `users/{uid}` dokümanı: yalnızca e-posta ve hesap/onay tarihleri tutulur.
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Profili oluşturur/günceller ve kayıtlı onay sürümünü döndürür.
  Future<int> syncProfile(User user, {int? acceptConsentVersion}) async {
    final ref = _doc(user.uid);
    final snap = await ref.get();
    final stored = (snap.data()?['consentVersion'] as num?)?.toInt() ?? 0;
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
    final accepts =
        acceptConsentVersion != null && acceptConsentVersion > stored;
    if (accepts) {
      data['consentVersion'] = acceptConsentVersion;
      data['consentAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
    return accepts ? acceptConsentVersion : stored;
  }

  Future<void> deleteProfile(String uid) => _doc(uid).delete();
}
