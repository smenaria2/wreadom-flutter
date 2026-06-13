// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaf_attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LeafAttachment _$LeafAttachmentFromJson(Map<String, dynamic> json) =>
    _LeafAttachment(
      id: json['id'] as String,
      type: $enumDecode(_$LeafTypeEnumMap, json['type']),
      createdAt: (json['createdAt'] as num).toInt(),
      createdBy: json['createdBy'] as String,
      createdByRole: json['createdByRole'] as String?,
      textHtml: json['textHtml'] as String?,
      textPlain: json['textPlain'] as String?,
      wordCount: (json['wordCount'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      imageAlt: json['imageAlt'] as String?,
      url: json['url'] as String?,
      linkType: $enumDecodeNullable(_$LeafLinkTypeEnumMap, json['linkType']),
      title: json['title'] as String?,
      question: json['question'] as String?,
      audioUrl: json['audioUrl'] as String?,
      audioObjectKey: json['audioObjectKey'] as String?,
      audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
      audioMimeType: json['audioMimeType'] as String?,
      audioSizeBytes: (json['audioSizeBytes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LeafAttachmentToJson(_LeafAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$LeafTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt,
      'createdBy': instance.createdBy,
      'createdByRole': instance.createdByRole,
      'textHtml': instance.textHtml,
      'textPlain': instance.textPlain,
      'wordCount': instance.wordCount,
      'imageUrl': instance.imageUrl,
      'imageAlt': instance.imageAlt,
      'url': instance.url,
      'linkType': _$LeafLinkTypeEnumMap[instance.linkType],
      'title': instance.title,
      'question': instance.question,
      'audioUrl': instance.audioUrl,
      'audioObjectKey': instance.audioObjectKey,
      'audioDurationMs': instance.audioDurationMs,
      'audioMimeType': instance.audioMimeType,
      'audioSizeBytes': instance.audioSizeBytes,
    };

const _$LeafTypeEnumMap = {
  LeafType.text: 'text',
  LeafType.image: 'image',
  LeafType.link: 'link',
  LeafType.audio: 'audio',
  LeafType.question: 'question',
};

const _$LeafLinkTypeEnumMap = {
  LeafLinkType.youtube: 'youtube',
  LeafLinkType.spotify: 'spotify',
  LeafLinkType.instagram: 'instagram',
  LeafLinkType.amazon: 'amazon',
  LeafLinkType.wikipedia: 'wikipedia',
};
