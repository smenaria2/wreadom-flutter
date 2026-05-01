import 'package:freezed_annotation/freezed_annotation.dart';
import 'author.dart';
import 'chapter.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    String? description,
    String? coverUrl,
    required List<Author> authors,
    required List<String> subjects,
    required List<String> languages,
    required Map<String, String> formats,
    @JsonKey(name: 'download_count') required int downloadCount,
    @JsonKey(name: 'media_type') required String mediaType,
    required List<String> bookshelves,
    dynamic year, // can be int or String
    String? source,
    bool? isOriginal,
    String? contentType,
    String? authorId,
    List<Chapter>? chapters,
    String? status,
    int? createdAt,
    int? updatedAt,
    String? identifier,
    int? recommendationCount,
    double? weightedScore,
    double? averageRating,
    int? viewCount,
    int? ratingsCount,
    List<String>? topics,
    int? chapterCount,
    String? collaborationStatus,
    String? collaboratorId,
    String? collaboratorName,
    String? collaboratorPhotoURL,
    String? collaborationRequestedBy,
    int? collaborationRequestedAt,
    int? collaborationRespondedAt,
    List<String>? authorIds,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
