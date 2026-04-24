import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    // Enable offline persistence
    _db.settings = const Settings(persistenceEnabled: true);
  }

  // Generic Get stream
  Stream<List<T>> streamCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _db.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => builder(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Generic Get Document
  Future<T> getDocument<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
  }) async {
    final doc = await _db.doc(path).get();
    return builder(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Generic Set Data
  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) {
    return _db.doc(path).set(data, SetOptions(merge: merge));
  }

  // Generic Add to Collection
  Future<DocumentReference> addDocument({
    required String path,
    required Map<String, dynamic> data,
  }) {
    return _db.collection(path).add(data);
  }

  // Generic Update Data
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) {
    return _db.doc(path).update(data);
  }

  // Generic Delete Data
  Future<void> deleteDocument({required String path}) {
    return _db.doc(path).delete();
  }
}
