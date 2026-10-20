import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminStats {
  final int totalUsers;
  final int newUsers7d;
  final int newUsers30d;
  final int totalHomes;
  final int newFeedback;
  final int blockedUsers;

  const AdminStats({
    required this.totalUsers,
    required this.newUsers7d,
    required this.newUsers30d,
    required this.totalHomes,
    required this.newFeedback,
    required this.blockedUsers,
  });
}

class AdminUser {
  final String uid;
  final String email;
  final String provider;
  final String platform;
  final int homeCount;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const AdminUser({
    required this.uid,
    required this.email,
    required this.provider,
    required this.platform,
    required this.homeCount,
    required this.createdAt,
    required this.lastSeenAt,
  });

  factory AdminUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return AdminUser(
      uid: doc.id,
      email: d['email'] as String? ?? '—',
      provider: d['provider'] as String? ?? '',
      platform: d['platform'] as String? ?? '',
      homeCount: (d['homeCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      lastSeenAt: (d['lastSeenAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Yalnızca admin hesabının yapabildiği işlemler (bkz. firestore.rules).
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _blocked =>
      _firestore.collection('blockedEmails');

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Future<AdminStats> stats() async {
    final now = DateTime.now();
    final results = await Future.wait([
      _count(_users),
      _count(_users.where(
        'createdAt',
        isGreaterThanOrEqualTo: now.subtract(const Duration(days: 7)),
      )),
      _count(_users.where(
        'createdAt',
        isGreaterThanOrEqualTo: now.subtract(const Duration(days: 30)),
      )),
      _count(_firestore.collectionGroup('homes')),
      _count(_firestore
          .collection('feedback')
          .where('status', isEqualTo: 'new')),
      _count(_blocked),
    ]);
    return AdminStats(
      totalUsers: results[0],
      newUsers7d: results[1],
      newUsers30d: results[2],
      totalHomes: results[3],
      newFeedback: results[4],
      blockedUsers: results[5],
    );
  }

  Future<List<AdminUser>> latestUsers({int limit = 50}) async {
    final snap =
        await _users.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(AdminUser.fromDoc).toList();
  }

  /// E-posta ile birebir arama (büyük/küçük harf duyarsız değil).
  Future<List<AdminUser>> findByEmail(String email) async {
    final snap = await _users.where('email', isEqualTo: email.trim()).get();
    return snap.docs.map(AdminUser.fromDoc).toList();
  }

  Future<Set<String>> blockedEmails() async {
    final snap = await _blocked.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> block(String email, {String? reason}) {
    return _blocked.doc(email).set({
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedBy': FirebaseAuth.instance.currentUser?.email,
      'reason': reason ?? '',
    });
  }

  Future<void> unblock(String email) => _blocked.doc(email).delete();

  /// Kullanıcının tüm kayıtlı evlerini siler ve sayacını sıfırlar.
  Future<int> deleteHomes(String uid) async {
    final homes = await _users.doc(uid).collection('homes').get();
    final docs = homes.docs;
    for (var i = 0; i < docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final doc in docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _users.doc(uid).update({'homeCount': 0});
    return docs.length;
  }

  /// Profil kaydını siler. Giriş hesabı Firebase konsolundan silinmelidir.
  Future<void> deleteProfile(String uid) async {
    await deleteHomes(uid);
    await _users.doc(uid).delete();
  }
}
