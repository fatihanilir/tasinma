import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının evler koleksiyonu referansı
  CollectionReference<Map<String, dynamic>> get _homesRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Kullanıcı giriş yapmamış');
    return _firestore.collection('users').doc(userId).collection('homes');
  }

  // Tüm evleri getir (stream)
  Stream<List<HomeModel>> getHomesStream() {
    try {
      return _homesRef
          .orderBy('order', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => HomeModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Tüm evleri getir (tek seferlik)
  Future<List<HomeModel>> getHomes() async {
    try {
      final snapshot = await _homesRef.orderBy('order', descending: false).get();
      return snapshot.docs
          .map((doc) => HomeModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Get homes error: $e');
      return [];
    }
  }

  // Ev kaydet veya güncelle
  Future<void> saveHome(HomeModel home) async {
    try {
      await _homesRef.doc(home.id).set(home.toJson());
    } catch (e) {
      print('Save home error: $e');
      rethrow;
    }
  }

  // Ev sil
  Future<void> deleteHome(String homeId) async {
    try {
      await _homesRef.doc(homeId).delete();
    } catch (e) {
      print('Delete home error: $e');
      rethrow;
    }
  }

  // Sıralamayı güncelle
  Future<void> updateOrder(List<HomeModel> homes) async {
    try {
      final batch = _firestore.batch();
      for (int i = 0; i < homes.length; i++) {
        final home = homes[i].copyWith(order: i);
        batch.set(_homesRef.doc(home.id), home.toJson());
      }
      await batch.commit();
    } catch (e) {
      print('Update order error: $e');
      rethrow;
    }
  }

  // Kullanıcı verilerini tamamen sil
  Future<void> deleteAllUserData() async {
    try {
      final snapshot = await _homesRef.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Delete all user data error: $e');
      rethrow;
    }
  }
}
