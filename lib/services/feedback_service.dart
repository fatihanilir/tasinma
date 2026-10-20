import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum FeedbackCategory {
  suggestion('oneri', 'Öneri'),
  bug('hata', 'Hata bildirimi'),
  question('soru', 'Soru'),
  other('diger', 'Diğer');

  final String id;
  final String label;
  const FeedbackCategory(this.id, this.label);

  static String labelOf(String? id) => FeedbackCategory.values
      .firstWhere((c) => c.id == id, orElse: () => FeedbackCategory.other)
      .label;
}

class FeedbackItem {
  final String id;
  final String message;
  final String category;
  final String? email;
  final String status;
  final DateTime? createdAt;

  const FeedbackItem({
    required this.id,
    required this.message,
    required this.category,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  bool get isNew => status == 'new';

  factory FeedbackItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FeedbackItem(
      id: doc.id,
      message: d['message'] as String? ?? '',
      category: d['category'] as String? ?? 'diger',
      email: d['email'] as String?,
      status: d['status'] as String? ?? 'new',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class FeedbackService {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('feedback');

  Future<void> send({
    required FeedbackCategory category,
    required String message,
    String? email,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final replyTo = (email ?? '').trim();
    await _ref.add({
      'message': message.trim(),
      'category': category.id,
      'email': replyTo.isNotEmpty ? replyTo : user?.email,
      'uid': user?.uid,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<FeedbackItem>> latest({int limit = 50}) async {
    final snap =
        await _ref.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(FeedbackItem.fromDoc).toList();
  }

  Future<void> markDone(String id) => _ref.doc(id).update({'status': 'done'});

  Future<void> delete(String id) => _ref.doc(id).delete();
}
