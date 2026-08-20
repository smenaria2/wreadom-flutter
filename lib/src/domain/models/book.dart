import 'package:freezed_annotation/freezed_annotation.dart';
import '../../utils/image_proxy_utils.dart';
import 'author.dart';
import 'chapter.dart';
import 'leaf_attachment.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    String? description,
    @JsonKey(fromJson: proxyImageUrl) String? coverUrl,
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
    int? publishedAt,
    String? identifier,
    int? recommendationCount,
    double? weightedScore,
    double? averageRating,
    int? viewCount,
    int? ratingsCount,
    List<String>? topics,
    int? chapterCount,
    int? readingTimeMinutes,
    int? wordCount,
    String? collaborationStatus,
    String? collaboratorId,
    String? collaboratorName,
    String? collaboratorPhotoURL,
    String? collaborationRequestedBy,
    int? collaborationRequestedAt,
    int? collaborationRespondedAt,
    List<String>? authorIds,
    List<LeafAttachment>? leaves,
    int? leafCount,
    bool? hasLeaves,
    int? leafUpdatedAt,
    bool? optOutComplementary,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) =>
      _$BookFromJson(_sanitizeBookJson(json));
}

Map<String, dynamic> _sanitizeBookJson(Map<String, dynamic> json) {
  final leavesRaw = json['leaves'];
  if (leavesRaw == null) return json;

  final sanitized = <Map<String, dynamic>>[];
  if (leavesRaw is List) {
    for (final rawLeaf in leavesRaw) {
      if (rawLeaf is! Map) continue;
      final leaf = <String, dynamic>{
        for (final entry in rawLeaf.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
      try {
        LeafAttachment.fromJson(leaf);
        sanitized.add(leaf);
      } on Object {
        // Invalid legacy leaf entries must not prevent the book from loading.
      }
    }
  }
  final copy = Map<String, dynamic>.from(json);
  copy['leaves'] = sanitized;
  return copy;
}
