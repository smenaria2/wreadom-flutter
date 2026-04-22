import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseBookmarkRepository implements BookmarkRepository {
  FirebaseBookmarkRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> addBookmark(Bookmark bookmark) async {
    final data = bookmark.toJson()..remove('id');
    data.removeWhere((key, value) => value == null);
    final doc = await _firestore.collection('bookmarks').add(data);
    return doc.id;
  }

  @override
  Future<List<Bookmark>> getBookBookmarks(String userId, String bookId) async {
    final snapshot = await _firestore
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: bookId)
        .get();

    final items = snapshot.docs.map((doc) {
      final data = mapFirestoreData(doc.data(), doc.id);
      return Bookmark.fromJson(data);
    }).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Future<List<Bookmark>> getUserBookmarks(String userId) async {
    final snapshot = await _firestore
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .get();

    final items = snapshot.docs.map((doc) {
      final data = mapFirestoreData(doc.data(), doc.id);
      return Bookmark.fromJson(data);
    }).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    await _firestore.collection('bookmarks').doc(bookmarkId).delete();
  }
}
