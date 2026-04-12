import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/book.dart';
import '../../domain/repositories/writer_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseWriterRepository implements WriterRepository {
  FirebaseWriterRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> createBook(Book book) async {
    final data = book.toJson()..remove('id');
    final now = DateTime.now().millisecondsSinceEpoch;
    data['createdAt'] ??= now;
    data['updatedAt'] = now;
    data['isOriginal'] = true;
    data['source'] = 'firestore';
    final doc = await _firestore.collection('books').add(data);
    return doc.id;
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'status': 'deleted',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<Book>> getUserBooks(String userId, {String status = 'all'}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('books')
        .where('authorId', isEqualTo: userId);
    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.get();
    final items = snapshot.docs.map((doc) {
      final data = mapFirestoreData(doc.data(), doc.id);
      return Book.fromJson(data);
    }).where((book) => book.status != 'deleted').toList();
    items.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    return items;
  }

  @override
  Future<void> updateBook(String bookId, Book book) async {
    final data = book.toJson()..remove('id');
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.collection('books').doc(bookId).set(
          data,
          SetOptions(merge: true),
        );
  }
}
