import '../services/firestore_service.dart';

class ContactRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final String userId;

  ContactRepository({required this.userId});

  String get _basePath => 'contacts/$userId/list';

  Stream<List<Map<String, dynamic>>> getContacts() {
    return _firestoreService.streamCollection(
      path: _basePath,
      builder: (data, id) => {...data, 'id': id},
      queryBuilder: (query) => query.orderBy('is_primary', descending: true),
    );
  }

  Future<void> addContact(Map<String, dynamic> contact) {
    return _firestoreService.addDocument(path: _basePath, data: contact);
  }

  Future<void> deleteContact(String contactId) {
    return _firestoreService.deleteDocument(path: '$_basePath/$contactId');
  }

  Future<void> updateContact(String contactId, Map<String, dynamic> data) {
    return _firestoreService.updateData(path: '$_basePath/$contactId', data: data);
  }
}
