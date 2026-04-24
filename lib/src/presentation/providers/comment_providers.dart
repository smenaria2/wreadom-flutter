import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_comment_repository.dart';
import '../../data/services/audio_review_upload_service.dart';
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

final feedPostCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  postId,
) async {
  return ref.watch(commentRepositoryProvider).getFeedPostComments(postId);
});
