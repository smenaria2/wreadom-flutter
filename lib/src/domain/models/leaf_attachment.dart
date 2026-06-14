import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaf_attachment.freezed.dart';
part 'leaf_attachment.g.dart';

enum LeafType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('link')
  link,
  @JsonValue('audio')
  audio,
  @JsonValue('question')
  question,
  @JsonValue('certificate')
  certificate,
}

enum LeafLinkType {
  @JsonValue('youtube')
  youtube,
  @JsonValue('spotify')
  spotify,
  @JsonValue('instagram')
  instagram,
  @JsonValue('amazon')
  amazon,
  @JsonValue('wikipedia')
  wikipedia,
}

@freezed
abstract class LeafAttachment with _$LeafAttachment {
  const factory LeafAttachment({
    required String id,
    required LeafType type,
    required int createdAt,
    required String createdBy,
    String? createdByRole,
    String? textHtml,
    String? textPlain,
    int? wordCount,
    String? imageUrl,
    String? imageAlt,
    String? url,
    LeafLinkType? linkType,
    String? title,
    String? question,
    String? audioUrl,
    String? audioObjectKey,
    int? audioDurationMs,
    String? audioMimeType,
    int? audioSizeBytes,
    String? certificateTopicName,
    int? certificateIssuedAt,
    String? certificateParticipantName,
    String? certificateParticipantPhotoUrl,
  }) = _LeafAttachment;

  factory LeafAttachment.fromJson(Map<String, dynamic> json) =>
      _$LeafAttachmentFromJson(json);
}
