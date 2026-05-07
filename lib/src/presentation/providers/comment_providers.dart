import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/repositories/firebase_comment_repository.dart';
import '../../data/services/audio_review_upload_service.dart';
import '../../data/utils/firestore_utils.dart';
import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return FirebaseCommentRepository();
});

final audioReviewUploadServiceProvider = Provider<AudioReviewUploadService>((
  ref,
) {
  return AudioReviewUploadService();
});

final bookCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  bookId,
) async {
  return ref.watch(commentRepositoryProvider).getBookComments(bookId);
});

final liveBookCommentsProvider = StreamProvider.family<List<Comment>, String>((
  ref,
  bookId,
) {
  final idAsInt = int.tryParse(bookId);
  final ids = [bookId, ?idAsInt];
  return FirebaseFirestore.instance
      .collection('comments')
      .where('bookId', whereIn: ids)
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs.map((doc) {
          final data = mapFirestoreData(doc.data(), doc.id);
          return Comment.fromJson(data);
        }).toList();
        items.sort(_compareBookComments);
        return items;
      });
});

final feedPostCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  postId,
) async {
  return ref.watch(commentRepositoryProvider).getFeedPostComments(postId);
});

final liveFeedPostCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
      final idAsInt = int.tryParse(postId);
      final ids = [postId, ?idAsInt];
      return FirebaseFirestore.instance
          .collection('comments')
          .where('feedPostId', whereIn: ids)
          .snapshots()
          .map((snapshot) {
            final items = snapshot.docs.map((doc) {
              final data = mapFirestoreData(doc.data(), doc.id);
              return Comment.fromJson(data);
            }).toList();
            items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return items;
          });
    });

int _compareBookComments(Comment a, Comment b) {
  final aHighlightedAt = a.highlightedAt ?? 0;
  final bHighlightedAt = b.highlightedAt ?? 0;
  final aHighlighted = a.isHighlighted == true;
  final bHighlighted = b.isHighlighted == true;
  if (aHighlighted != bHighlighted) {
    return aHighlighted ? -1 : 1;
  }
  if (aHighlightedAt != bHighlightedAt) {
    return bHighlightedAt.compareTo(aHighlightedAt);
  }
  return b.timestamp.compareTo(a.timestamp);
}
