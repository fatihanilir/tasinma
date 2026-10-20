import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStats {
  final int totalUsers;
  final int newUsers7d;
  final int newUsers30d;
  final int totalHomes;
  final int newFeedback;

  const AdminStats({
    required this.totalUsers,
    required this.newUsers7d,
    required this.newUsers30d,
    required this.totalHomes,
    required this.newFeedback,
  });
}

class AdminUser {
  final String email;
  final String provider;
  final String platform;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const AdminUser({
    required this.email,
    required this.provider,
    required this.platform,
    required this.createdAt,
    required this.lastSeenAt,
  });
}

/// Yalnızca admin hesabının okuyabildiği sayımlar (bkz. firestore.rules).
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Future<AdminStats> stats() async {
    final users = _firestore.collection('users');
    final now = DateTime.now();
    final results = await Future.wait([
      _count(users),
      _count(users.where(
        'createdAt',
        isGreaterThanOrEqualTo: now.subtract(const Duration(days: 7)),
      )),
      _count(users.where(
        'createdAt',
        isGreaterThanOrEqualTo: now.subtract(const Duration(days: 30)),
      )),
      _count(_firestore.collectionGroup('homes')),
      _count(_firestore
          .collection('feedback')
          .where('status', isEqualTo: 'new')),
    ]);
    return AdminStats(
      totalUsers: results[0],
      newUsers7d: results[1],
      newUsers30d: results[2],
      totalHomes: results[3],
      newFeedback: results[4],
    );
  }

  Future<List<AdminUser>> latestUsers({int limit = 30}) async {
    final snap = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return AdminUser(
        email: d['email'] as String? ?? '—',
        provider: d['provider'] as String? ?? '',
        platform: d['platform'] as String? ?? '',
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
        lastSeenAt: (d['lastSeenAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }
}
