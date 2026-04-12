import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
abstract class CommentReply with _$CommentReply {
  const factory CommentReply({
    String? id,
    required String userId,
    required String username,
    String? displayName,
    String? penName,
    required String text,
    required int timestamp,
    String? userPhotoURL,
    List<String>? likes,
    Map<String, String>? mentions,
  }) = _CommentReply;

  factory CommentReply.fromJson(Map<String, dynamic> json) => _$CommentReplyFromJson(json);
}

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    String? id,
    required dynamic bookId,
    required String bookTitle,
    required String userId,
    required String username,
    required String text,
    int? rating,
    String? chapterTitle,
    int? chapterIndex,
    String? chapterId,
    String? quote,
    required int timestamp,
    String? feedPostId,
    String? userPhotoURL,
    String? displayName,
    String? penName,
    List<CommentReply>? replies,
    List<String>? likes,
    Map<String, String>? mentions,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
