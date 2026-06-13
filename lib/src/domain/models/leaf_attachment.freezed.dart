// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaf_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LeafAttachment {

 String get id; LeafType get type; int get createdAt; String get createdBy; String? get createdByRole; String? get textHtml; String? get textPlain; int? get wordCount; String? get imageUrl; String? get imageAlt; String? get url; LeafLinkType? get linkType; String? get title; String? get question; String? get audioUrl; String? get audioObjectKey; int? get audioDurationMs; String? get audioMimeType; int? get audioSizeBytes;
/// Create a copy of LeafAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeafAttachmentCopyWith<LeafAttachment> get copyWith => _$LeafAttachmentCopyWithImpl<LeafAttachment>(this as LeafAttachment, _$identity);

  /// Serializes this LeafAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeafAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByRole, createdByRole) || other.createdByRole == createdByRole)&&(identical(other.textHtml, textHtml) || other.textHtml == textHtml)&&(identical(other.textPlain, textPlain) || other.textPlain == textPlain)&&(identical(other.wordCount, wordCount) || other.wordCount == wordCount)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.imageAlt, imageAlt) || other.imageAlt == imageAlt)&&(identical(other.url, url) || other.url == url)&&(identical(other.linkType, linkType) || other.linkType == linkType)&&(identical(other.title, title) || other.title == title)&&(identical(other.question, question) || other.question == question)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.audioObjectKey, audioObjectKey) || other.audioObjectKey == audioObjectKey)&&(identical(other.audioDurationMs, audioDurationMs) || other.audioDurationMs == audioDurationMs)&&(identical(other.audioMimeType, audioMimeType) || other.audioMimeType == audioMimeType)&&(identical(other.audioSizeBytes, audioSizeBytes) || other.audioSizeBytes == audioSizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,createdAt,createdBy,createdByRole,textHtml,textPlain,wordCount,imageUrl,imageAlt,url,linkType,title,question,audioUrl,audioObjectKey,audioDurationMs,audioMimeType,audioSizeBytes]);

@override
String toString() {
  return 'LeafAttachment(id: $id, type: $type, createdAt: $createdAt, createdBy: $createdBy, createdByRole: $createdByRole, textHtml: $textHtml, textPlain: $textPlain, wordCount: $wordCount, imageUrl: $imageUrl, imageAlt: $imageAlt, url: $url, linkType: $linkType, title: $title, question: $question, audioUrl: $audioUrl, audioObjectKey: $audioObjectKey, audioDurationMs: $audioDurationMs, audioMimeType: $audioMimeType, audioSizeBytes: $audioSizeBytes)';
}


}

/// @nodoc
abstract mixin class $LeafAttachmentCopyWith<$Res>  {
  factory $LeafAttachmentCopyWith(LeafAttachment value, $Res Function(LeafAttachment) _then) = _$LeafAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, LeafType type, int createdAt, String createdBy, String? createdByRole, String? textHtml, String? textPlain, int? wordCount, String? imageUrl, String? imageAlt, String? url, LeafLinkType? linkType, String? title, String? question, String? audioUrl, String? audioObjectKey, int? audioDurationMs, String? audioMimeType, int? audioSizeBytes
});




}
/// @nodoc
class _$LeafAttachmentCopyWithImpl<$Res>
    implements $LeafAttachmentCopyWith<$Res> {
  _$LeafAttachmentCopyWithImpl(this._self, this._then);

  final LeafAttachment _self;
  final $Res Function(LeafAttachment) _then;

/// Create a copy of LeafAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? createdAt = null,Object? createdBy = null,Object? createdByRole = freezed,Object? textHtml = freezed,Object? textPlain = freezed,Object? wordCount = freezed,Object? imageUrl = freezed,Object? imageAlt = freezed,Object? url = freezed,Object? linkType = freezed,Object? title = freezed,Object? question = freezed,Object? audioUrl = freezed,Object? audioObjectKey = freezed,Object? audioDurationMs = freezed,Object? audioMimeType = freezed,Object? audioSizeBytes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LeafType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByRole: freezed == createdByRole ? _self.createdByRole : createdByRole // ignore: cast_nullable_to_non_nullable
as String?,textHtml: freezed == textHtml ? _self.textHtml : textHtml // ignore: cast_nullable_to_non_nullable
as String?,textPlain: freezed == textPlain ? _self.textPlain : textPlain // ignore: cast_nullable_to_non_nullable
as String?,wordCount: freezed == wordCount ? _self.wordCount : wordCount // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageAlt: freezed == imageAlt ? _self.imageAlt : imageAlt // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,linkType: freezed == linkType ? _self.linkType : linkType // ignore: cast_nullable_to_non_nullable
as LeafLinkType?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,audioObjectKey: freezed == audioObjectKey ? _self.audioObjectKey : audioObjectKey // ignore: cast_nullable_to_non_nullable
as String?,audioDurationMs: freezed == audioDurationMs ? _self.audioDurationMs : audioDurationMs // ignore: cast_nullable_to_non_nullable
as int?,audioMimeType: freezed == audioMimeType ? _self.audioMimeType : audioMimeType // ignore: cast_nullable_to_non_nullable
as String?,audioSizeBytes: freezed == audioSizeBytes ? _self.audioSizeBytes : audioSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeafAttachment].
extension LeafAttachmentPatterns on LeafAttachment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeafAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeafAttachment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeafAttachment value)  $default,){
final _that = this;
switch (_that) {
case _LeafAttachment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeafAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _LeafAttachment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LeafType type,  int createdAt,  String createdBy,  String? createdByRole,  String? textHtml,  String? textPlain,  int? wordCount,  String? imageUrl,  String? imageAlt,  String? url,  LeafLinkType? linkType,  String? title,  String? question,  String? audioUrl,  String? audioObjectKey,  int? audioDurationMs,  String? audioMimeType,  int? audioSizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeafAttachment() when $default != null:
return $default(_that.id,_that.type,_that.createdAt,_that.createdBy,_that.createdByRole,_that.textHtml,_that.textPlain,_that.wordCount,_that.imageUrl,_that.imageAlt,_that.url,_that.linkType,_that.title,_that.question,_that.audioUrl,_that.audioObjectKey,_that.audioDurationMs,_that.audioMimeType,_that.audioSizeBytes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LeafType type,  int createdAt,  String createdBy,  String? createdByRole,  String? textHtml,  String? textPlain,  int? wordCount,  String? imageUrl,  String? imageAlt,  String? url,  LeafLinkType? linkType,  String? title,  String? question,  String? audioUrl,  String? audioObjectKey,  int? audioDurationMs,  String? audioMimeType,  int? audioSizeBytes)  $default,) {final _that = this;
switch (_that) {
case _LeafAttachment():
return $default(_that.id,_that.type,_that.createdAt,_that.createdBy,_that.createdByRole,_that.textHtml,_that.textPlain,_that.wordCount,_that.imageUrl,_that.imageAlt,_that.url,_that.linkType,_that.title,_that.question,_that.audioUrl,_that.audioObjectKey,_that.audioDurationMs,_that.audioMimeType,_that.audioSizeBytes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LeafType type,  int createdAt,  String createdBy,  String? createdByRole,  String? textHtml,  String? textPlain,  int? wordCount,  String? imageUrl,  String? imageAlt,  String? url,  LeafLinkType? linkType,  String? title,  String? question,  String? audioUrl,  String? audioObjectKey,  int? audioDurationMs,  String? audioMimeType,  int? audioSizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _LeafAttachment() when $default != null:
return $default(_that.id,_that.type,_that.createdAt,_that.createdBy,_that.createdByRole,_that.textHtml,_that.textPlain,_that.wordCount,_that.imageUrl,_that.imageAlt,_that.url,_that.linkType,_that.title,_that.question,_that.audioUrl,_that.audioObjectKey,_that.audioDurationMs,_that.audioMimeType,_that.audioSizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeafAttachment implements LeafAttachment {
  const _LeafAttachment({required this.id, required this.type, required this.createdAt, required this.createdBy, this.createdByRole, this.textHtml, this.textPlain, this.wordCount, this.imageUrl, this.imageAlt, this.url, this.linkType, this.title, this.question, this.audioUrl, this.audioObjectKey, this.audioDurationMs, this.audioMimeType, this.audioSizeBytes});
  factory _LeafAttachment.fromJson(Map<String, dynamic> json) => _$LeafAttachmentFromJson(json);

@override final  String id;
@override final  LeafType type;
@override final  int createdAt;
@override final  String createdBy;
@override final  String? createdByRole;
@override final  String? textHtml;
@override final  String? textPlain;
@override final  int? wordCount;
@override final  String? imageUrl;
@override final  String? imageAlt;
@override final  String? url;
@override final  LeafLinkType? linkType;
@override final  String? title;
@override final  String? question;
@override final  String? audioUrl;
@override final  String? audioObjectKey;
@override final  int? audioDurationMs;
@override final  String? audioMimeType;
@override final  int? audioSizeBytes;

/// Create a copy of LeafAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeafAttachmentCopyWith<_LeafAttachment> get copyWith => __$LeafAttachmentCopyWithImpl<_LeafAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeafAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeafAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByRole, createdByRole) || other.createdByRole == createdByRole)&&(identical(other.textHtml, textHtml) || other.textHtml == textHtml)&&(identical(other.textPlain, textPlain) || other.textPlain == textPlain)&&(identical(other.wordCount, wordCount) || other.wordCount == wordCount)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.imageAlt, imageAlt) || other.imageAlt == imageAlt)&&(identical(other.url, url) || other.url == url)&&(identical(other.linkType, linkType) || other.linkType == linkType)&&(identical(other.title, title) || other.title == title)&&(identical(other.question, question) || other.question == question)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.audioObjectKey, audioObjectKey) || other.audioObjectKey == audioObjectKey)&&(identical(other.audioDurationMs, audioDurationMs) || other.audioDurationMs == audioDurationMs)&&(identical(other.audioMimeType, audioMimeType) || other.audioMimeType == audioMimeType)&&(identical(other.audioSizeBytes, audioSizeBytes) || other.audioSizeBytes == audioSizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,createdAt,createdBy,createdByRole,textHtml,textPlain,wordCount,imageUrl,imageAlt,url,linkType,title,question,audioUrl,audioObjectKey,audioDurationMs,audioMimeType,audioSizeBytes]);

@override
String toString() {
  return 'LeafAttachment(id: $id, type: $type, createdAt: $createdAt, createdBy: $createdBy, createdByRole: $createdByRole, textHtml: $textHtml, textPlain: $textPlain, wordCount: $wordCount, imageUrl: $imageUrl, imageAlt: $imageAlt, url: $url, linkType: $linkType, title: $title, question: $question, audioUrl: $audioUrl, audioObjectKey: $audioObjectKey, audioDurationMs: $audioDurationMs, audioMimeType: $audioMimeType, audioSizeBytes: $audioSizeBytes)';
}


}

/// @nodoc
abstract mixin class _$LeafAttachmentCopyWith<$Res> implements $LeafAttachmentCopyWith<$Res> {
  factory _$LeafAttachmentCopyWith(_LeafAttachment value, $Res Function(_LeafAttachment) _then) = __$LeafAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, LeafType type, int createdAt, String createdBy, String? createdByRole, String? textHtml, String? textPlain, int? wordCount, String? imageUrl, String? imageAlt, String? url, LeafLinkType? linkType, String? title, String? question, String? audioUrl, String? audioObjectKey, int? audioDurationMs, String? audioMimeType, int? audioSizeBytes
});




}
/// @nodoc
class __$LeafAttachmentCopyWithImpl<$Res>
    implements _$LeafAttachmentCopyWith<$Res> {
  __$LeafAttachmentCopyWithImpl(this._self, this._then);

  final _LeafAttachment _self;
  final $Res Function(_LeafAttachment) _then;

/// Create a copy of LeafAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? createdAt = null,Object? createdBy = null,Object? createdByRole = freezed,Object? textHtml = freezed,Object? textPlain = freezed,Object? wordCount = freezed,Object? imageUrl = freezed,Object? imageAlt = freezed,Object? url = freezed,Object? linkType = freezed,Object? title = freezed,Object? question = freezed,Object? audioUrl = freezed,Object? audioObjectKey = freezed,Object? audioDurationMs = freezed,Object? audioMimeType = freezed,Object? audioSizeBytes = freezed,}) {
  return _then(_LeafAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LeafType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByRole: freezed == createdByRole ? _self.createdByRole : createdByRole // ignore: cast_nullable_to_non_nullable
as String?,textHtml: freezed == textHtml ? _self.textHtml : textHtml // ignore: cast_nullable_to_non_nullable
as String?,textPlain: freezed == textPlain ? _self.textPlain : textPlain // ignore: cast_nullable_to_non_nullable
as String?,wordCount: freezed == wordCount ? _self.wordCount : wordCount // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageAlt: freezed == imageAlt ? _self.imageAlt : imageAlt // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,linkType: freezed == linkType ? _self.linkType : linkType // ignore: cast_nullable_to_non_nullable
as LeafLinkType?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,audioObjectKey: freezed == audioObjectKey ? _self.audioObjectKey : audioObjectKey // ignore: cast_nullable_to_non_nullable
as String?,audioDurationMs: freezed == audioDurationMs ? _self.audioDurationMs : audioDurationMs // ignore: cast_nullable_to_non_nullable
as int?,audioMimeType: freezed == audioMimeType ? _self.audioMimeType : audioMimeType // ignore: cast_nullable_to_non_nullable
as String?,audioSizeBytes: freezed == audioSizeBytes ? _self.audioSizeBytes : audioSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
