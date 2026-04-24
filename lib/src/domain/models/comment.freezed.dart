// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentReply {

 String? get id; String get userId; String get username; String? get displayName; String? get penName; String get text; int get timestamp; String? get userPhotoURL; List<String>? get likes; Map<String, String>? get mentions;
/// Create a copy of CommentReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentReplyCopyWith<CommentReply> get copyWith => _$CommentReplyCopyWithImpl<CommentReply>(this as CommentReply, _$identity);

  /// Serializes this CommentReply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentReply&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&(identical(other.text, text) || other.text == text)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userPhotoURL, userPhotoURL) || other.userPhotoURL == userPhotoURL)&&const DeepCollectionEquality().equals(other.likes, likes)&&const DeepCollectionEquality().equals(other.mentions, mentions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,username,displayName,penName,text,timestamp,userPhotoURL,const DeepCollectionEquality().hash(likes),const DeepCollectionEquality().hash(mentions));

@override
String toString() {
  return 'CommentReply(id: $id, userId: $userId, username: $username, displayName: $displayName, penName: $penName, text: $text, timestamp: $timestamp, userPhotoURL: $userPhotoURL, likes: $likes, mentions: $mentions)';
}


}

/// @nodoc
abstract mixin class $CommentReplyCopyWith<$Res>  {
  factory $CommentReplyCopyWith(CommentReply value, $Res Function(CommentReply) _then) = _$CommentReplyCopyWithImpl;
@useResult
$Res call({
 String? id, String userId, String username, String? displayName, String? penName, String text, int timestamp, String? userPhotoURL, List<String>? likes, Map<String, String>? mentions
});




}
/// @nodoc
class _$CommentReplyCopyWithImpl<$Res>
    implements $CommentReplyCopyWith<$Res> {
  _$CommentReplyCopyWithImpl(this._self, this._then);

  final CommentReply _self;
  final $Res Function(CommentReply) _then;

/// Create a copy of CommentReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? username = null,Object? displayName = freezed,Object? penName = freezed,Object? text = null,Object? timestamp = null,Object? userPhotoURL = freezed,Object? likes = freezed,Object? mentions = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,userPhotoURL: freezed == userPhotoURL ? _self.userPhotoURL : userPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,likes: freezed == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>?,mentions: freezed == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentReply].
extension CommentReplyPatterns on CommentReply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentReply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentReply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentReply value)  $default,){
final _that = this;
switch (_that) {
case _CommentReply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentReply value)?  $default,){
final _that = this;
switch (_that) {
case _CommentReply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String userId,  String username,  String? displayName,  String? penName,  String text,  int timestamp,  String? userPhotoURL,  List<String>? likes,  Map<String, String>? mentions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentReply() when $default != null:
return $default(_that.id,_that.userId,_that.username,_that.displayName,_that.penName,_that.text,_that.timestamp,_that.userPhotoURL,_that.likes,_that.mentions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String userId,  String username,  String? displayName,  String? penName,  String text,  int timestamp,  String? userPhotoURL,  List<String>? likes,  Map<String, String>? mentions)  $default,) {final _that = this;
switch (_that) {
case _CommentReply():
return $default(_that.id,_that.userId,_that.username,_that.displayName,_that.penName,_that.text,_that.timestamp,_that.userPhotoURL,_that.likes,_that.mentions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String userId,  String username,  String? displayName,  String? penName,  String text,  int timestamp,  String? userPhotoURL,  List<String>? likes,  Map<String, String>? mentions)?  $default,) {final _that = this;
switch (_that) {
case _CommentReply() when $default != null:
return $default(_that.id,_that.userId,_that.username,_that.displayName,_that.penName,_that.text,_that.timestamp,_that.userPhotoURL,_that.likes,_that.mentions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentReply implements CommentReply {
  const _CommentReply({this.id, required this.userId, required this.username, this.displayName, this.penName, required this.text, required this.timestamp, this.userPhotoURL, final  List<String>? likes, final  Map<String, String>? mentions}): _likes = likes,_mentions = mentions;
  factory _CommentReply.fromJson(Map<String, dynamic> json) => _$CommentReplyFromJson(json);

@override final  String? id;
@override final  String userId;
@override final  String username;
@override final  String? displayName;
@override final  String? penName;
@override final  String text;
@override final  int timestamp;
@override final  String? userPhotoURL;
 final  List<String>? _likes;
@override List<String>? get likes {
  final value = _likes;
  if (value == null) return null;
  if (_likes is EqualUnmodifiableListView) return _likes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, String>? _mentions;
@override Map<String, String>? get mentions {
  final value = _mentions;
  if (value == null) return null;
  if (_mentions is EqualUnmodifiableMapView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of CommentReply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentReplyCopyWith<_CommentReply> get copyWith => __$CommentReplyCopyWithImpl<_CommentReply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentReply&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&(identical(other.text, text) || other.text == text)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userPhotoURL, userPhotoURL) || other.userPhotoURL == userPhotoURL)&&const DeepCollectionEquality().equals(other._likes, _likes)&&const DeepCollectionEquality().equals(other._mentions, _mentions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,username,displayName,penName,text,timestamp,userPhotoURL,const DeepCollectionEquality().hash(_likes),const DeepCollectionEquality().hash(_mentions));

@override
String toString() {
  return 'CommentReply(id: $id, userId: $userId, username: $username, displayName: $displayName, penName: $penName, text: $text, timestamp: $timestamp, userPhotoURL: $userPhotoURL, likes: $likes, mentions: $mentions)';
}


}

/// @nodoc
abstract mixin class _$CommentReplyCopyWith<$Res> implements $CommentReplyCopyWith<$Res> {
  factory _$CommentReplyCopyWith(_CommentReply value, $Res Function(_CommentReply) _then) = __$CommentReplyCopyWithImpl;
@override @useResult
$Res call({
 String? id, String userId, String username, String? displayName, String? penName, String text, int timestamp, String? userPhotoURL, List<String>? likes, Map<String, String>? mentions
});




}
/// @nodoc
class __$CommentReplyCopyWithImpl<$Res>
    implements _$CommentReplyCopyWith<$Res> {
  __$CommentReplyCopyWithImpl(this._self, this._then);

  final _CommentReply _self;
  final $Res Function(_CommentReply) _then;

/// Create a copy of CommentReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? username = null,Object? displayName = freezed,Object? penName = freezed,Object? text = null,Object? timestamp = null,Object? userPhotoURL = freezed,Object? likes = freezed,Object? mentions = freezed,}) {
  return _then(_CommentReply(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,userPhotoURL: freezed == userPhotoURL ? _self.userPhotoURL : userPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,likes: freezed == likes ? _self._likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>?,mentions: freezed == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,
  ));
}


}


/// @nodoc
mixin _$Comment {

 String? get id; dynamic get bookId; String? get bookTitle; String get userId; String get username; String get text; int? get rating; String? get chapterTitle; int? get chapterIndex; String? get chapterId; String? get quote; int get timestamp; String? get feedPostId; String? get userPhotoURL; String? get displayName; String? get penName; List<CommentReply>? get replies; List<String>? get likes; Map<String, String>? get mentions; bool? get isHighlighted; int? get highlightedAt; String? get highlightedByUserId; String? get audioUrl; String? get audioObjectKey; int? get audioDurationMs; String? get audioMimeType; int? get audioSizeBytes;
/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentCopyWith<Comment> get copyWith => _$CommentCopyWithImpl<Comment>(this as Comment, _$identity);

  /// Serializes this Comment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comment&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.bookId, bookId)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.text, text) || other.text == text)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.feedPostId, feedPostId) || other.feedPostId == feedPostId)&&(identical(other.userPhotoURL, userPhotoURL) || other.userPhotoURL == userPhotoURL)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&const DeepCollectionEquality().equals(other.replies, replies)&&const DeepCollectionEquality().equals(other.likes, likes)&&const DeepCollectionEquality().equals(other.mentions, mentions)&&(identical(other.isHighlighted, isHighlighted) || other.isHighlighted == isHighlighted)&&(identical(other.highlightedAt, highlightedAt) || other.highlightedAt == highlightedAt)&&(identical(other.highlightedByUserId, highlightedByUserId) || other.highlightedByUserId == highlightedByUserId)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.audioObjectKey, audioObjectKey) || other.audioObjectKey == audioObjectKey)&&(identical(other.audioDurationMs, audioDurationMs) || other.audioDurationMs == audioDurationMs)&&(identical(other.audioMimeType, audioMimeType) || other.audioMimeType == audioMimeType)&&(identical(other.audioSizeBytes, audioSizeBytes) || other.audioSizeBytes == audioSizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,const DeepCollectionEquality().hash(bookId),bookTitle,userId,username,text,rating,chapterTitle,chapterIndex,chapterId,quote,timestamp,feedPostId,userPhotoURL,displayName,penName,const DeepCollectionEquality().hash(replies),const DeepCollectionEquality().hash(likes),const DeepCollectionEquality().hash(mentions),isHighlighted,highlightedAt,highlightedByUserId,audioUrl,audioObjectKey,audioDurationMs,audioMimeType,audioSizeBytes]);

@override
String toString() {
  return 'Comment(id: $id, bookId: $bookId, bookTitle: $bookTitle, userId: $userId, username: $username, text: $text, rating: $rating, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, chapterId: $chapterId, quote: $quote, timestamp: $timestamp, feedPostId: $feedPostId, userPhotoURL: $userPhotoURL, displayName: $displayName, penName: $penName, replies: $replies, likes: $likes, mentions: $mentions, isHighlighted: $isHighlighted, highlightedAt: $highlightedAt, highlightedByUserId: $highlightedByUserId, audioUrl: $audioUrl, audioObjectKey: $audioObjectKey, audioDurationMs: $audioDurationMs, audioMimeType: $audioMimeType, audioSizeBytes: $audioSizeBytes)';
}


}

/// @nodoc
abstract mixin class $CommentCopyWith<$Res>  {
  factory $CommentCopyWith(Comment value, $Res Function(Comment) _then) = _$CommentCopyWithImpl;
@useResult
$Res call({
 String? id, dynamic bookId, String? bookTitle, String userId, String username, String text, int? rating, String? chapterTitle, int? chapterIndex, String? chapterId, String? quote, int timestamp, String? feedPostId, String? userPhotoURL, String? displayName, String? penName, List<CommentReply>? replies, List<String>? likes, Map<String, String>? mentions, bool? isHighlighted, int? highlightedAt, String? highlightedByUserId, String? audioUrl, String? audioObjectKey, int? audioDurationMs, String? audioMimeType, int? audioSizeBytes
});




}
/// @nodoc
class _$CommentCopyWithImpl<$Res>
    implements $CommentCopyWith<$Res> {
  _$CommentCopyWithImpl(this._self, this._then);

  final Comment _self;
  final $Res Function(Comment) _then;

/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? bookId = freezed,Object? bookTitle = freezed,Object? userId = null,Object? username = null,Object? text = null,Object? rating = freezed,Object? chapterTitle = freezed,Object? chapterIndex = freezed,Object? chapterId = freezed,Object? quote = freezed,Object? timestamp = null,Object? feedPostId = freezed,Object? userPhotoURL = freezed,Object? displayName = freezed,Object? penName = freezed,Object? replies = freezed,Object? likes = freezed,Object? mentions = freezed,Object? isHighlighted = freezed,Object? highlightedAt = freezed,Object? highlightedByUserId = freezed,Object? audioUrl = freezed,Object? audioObjectKey = freezed,Object? audioDurationMs = freezed,Object? audioMimeType = freezed,Object? audioSizeBytes = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as dynamic,bookTitle: freezed == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterIndex: freezed == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,feedPostId: freezed == feedPostId ? _self.feedPostId : feedPostId // ignore: cast_nullable_to_non_nullable
as String?,userPhotoURL: freezed == userPhotoURL ? _self.userPhotoURL : userPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,replies: freezed == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentReply>?,likes: freezed == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>?,mentions: freezed == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,isHighlighted: freezed == isHighlighted ? _self.isHighlighted : isHighlighted // ignore: cast_nullable_to_non_nullable
as bool?,highlightedAt: freezed == highlightedAt ? _self.highlightedAt : highlightedAt // ignore: cast_nullable_to_non_nullable
as int?,highlightedByUserId: freezed == highlightedByUserId ? _self.highlightedByUserId : highlightedByUserId // ignore: cast_nullable_to_non_nullable
as String?,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,audioObjectKey: freezed == audioObjectKey ? _self.audioObjectKey : audioObjectKey // ignore: cast_nullable_to_non_nullable
as String?,audioDurationMs: freezed == audioDurationMs ? _self.audioDurationMs : audioDurationMs // ignore: cast_nullable_to_non_nullable
as int?,audioMimeType: freezed == audioMimeType ? _self.audioMimeType : audioMimeType // ignore: cast_nullable_to_non_nullable
as String?,audioSizeBytes: freezed == audioSizeBytes ? _self.audioSizeBytes : audioSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Comment].
extension CommentPatterns on Comment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comment value)  $default,){
final _that = this;
switch (_that) {
case _Comment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comment value)?  $default,){
final _that = this;
switch (_that) {
case _Comment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  dynamic bookId,  String? bookTitle,  String userId,  String username,  String text,  int? rating,  String? chapterTitle,  int? chapterIndex,  String? chapterId,  String? quote,  int timestamp,  String? feedPostId,  String? userPhotoURL,  String? displayName,  String? penName,  List<CommentReply>? replies,  List<String>? likes,  Map<String, String>? mentions,  bool? isHighlighted,  int? highlightedAt,  String? highlightedByUserId,  String? audioUrl,  String? audioObjectKey,  int? audioDurationMs,  String? audioMimeType,  int? audioSizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comment() when $default != null:
return $default(_that.id,_that.bookId,_that.bookTitle,_that.userId,_that.username,_that.text,_that.rating,_that.chapterTitle,_that.chapterIndex,_that.chapterId,_that.quote,_that.timestamp,_that.feedPostId,_that.userPhotoURL,_that.displayName,_that.penName,_that.replies,_that.likes,_that.mentions,_that.isHighlighted,_that.highlightedAt,_that.highlightedByUserId,_that.audioUrl,_that.audioObjectKey,_that.audioDurationMs,_that.audioMimeType,_that.audioSizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  dynamic bookId,  String? bookTitle,  String userId,  String username,  String text,  int? rating,  String? chapterTitle,  int? chapterIndex,  String? chapterId,  String? quote,  int timestamp,  String? feedPostId,  String? userPhotoURL,  String? displayName,  String? penName,  List<CommentReply>? replies,  List<String>? likes,  Map<String, String>? mentions,  bool? isHighlighted,  int? highlightedAt,  String? highlightedByUserId,  String? audioUrl,  String? audioObjectKey,  int? audioDurationMs,  String? audioMimeType,  int? audioSizeBytes)  $default,) {final _that = this;
switch (_that) {
case _Comment():
return $default(_that.id,_that.bookId,_that.bookTitle,_that.userId,_that.username,_that.text,_that.rating,_that.chapterTitle,_that.chapterIndex,_that.chapterId,_that.quote,_that.timestamp,_that.feedPostId,_that.userPhotoURL,_that.displayName,_that.penName,_that.replies,_that.likes,_that.mentions,_that.isHighlighted,_that.highlightedAt,_that.highlightedByUserId,_that.audioUrl,_that.audioObjectKey,_that.audioDurationMs,_that.audioMimeType,_that.audioSizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  dynamic bookId,  String? bookTitle,  String userId,  String username,  String text,  int? rating,  String? chapterTitle,  int? chapterIndex,  String? chapterId,  String? quote,  int timestamp,  String? feedPostId,  String? userPhotoURL,  String? displayName,  String? penName,  List<CommentReply>? replies,  List<String>? likes,  Map<String, String>? mentions,  bool? isHighlighted,  int? highlightedAt,  String? highlightedByUserId,  String? audioUrl,  String? audioObjectKey,  int? audioDurationMs,  String? audioMimeType,  int? audioSizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _Comment() when $default != null:
return $default(_that.id,_that.bookId,_that.bookTitle,_that.userId,_that.username,_that.text,_that.rating,_that.chapterTitle,_that.chapterIndex,_that.chapterId,_that.quote,_that.timestamp,_that.feedPostId,_that.userPhotoURL,_that.displayName,_that.penName,_that.replies,_that.likes,_that.mentions,_that.isHighlighted,_that.highlightedAt,_that.highlightedByUserId,_that.audioUrl,_that.audioObjectKey,_that.audioDurationMs,_that.audioMimeType,_that.audioSizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comment implements Comment {
  const _Comment({this.id, this.bookId, this.bookTitle, required this.userId, required this.username, required this.text, this.rating, this.chapterTitle, this.chapterIndex, this.chapterId, this.quote, required this.timestamp, this.feedPostId, this.userPhotoURL, this.displayName, this.penName, final  List<CommentReply>? replies, final  List<String>? likes, final  Map<String, String>? mentions, this.isHighlighted, this.highlightedAt, this.highlightedByUserId, this.audioUrl, this.audioObjectKey, this.audioDurationMs, this.audioMimeType, this.audioSizeBytes}): _replies = replies,_likes = likes,_mentions = mentions;
  factory _Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);

@override final  String? id;
@override final  dynamic bookId;
@override final  String? bookTitle;
@override final  String userId;
@override final  String username;
@override final  String text;
@override final  int? rating;
@override final  String? chapterTitle;
@override final  int? chapterIndex;
@override final  String? chapterId;
@override final  String? quote;
@override final  int timestamp;
@override final  String? feedPostId;
@override final  String? userPhotoURL;
@override final  String? displayName;
@override final  String? penName;
 final  List<CommentReply>? _replies;
@override List<CommentReply>? get replies {
  final value = _replies;
  if (value == null) return null;
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _likes;
@override List<String>? get likes {
  final value = _likes;
  if (value == null) return null;
  if (_likes is EqualUnmodifiableListView) return _likes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, String>? _mentions;
@override Map<String, String>? get mentions {
  final value = _mentions;
  if (value == null) return null;
  if (_mentions is EqualUnmodifiableMapView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  bool? isHighlighted;
@override final  int? highlightedAt;
@override final  String? highlightedByUserId;
@override final  String? audioUrl;
@override final  String? audioObjectKey;
@override final  int? audioDurationMs;
@override final  String? audioMimeType;
@override final  int? audioSizeBytes;

/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentCopyWith<_Comment> get copyWith => __$CommentCopyWithImpl<_Comment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comment&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.bookId, bookId)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.text, text) || other.text == text)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.feedPostId, feedPostId) || other.feedPostId == feedPostId)&&(identical(other.userPhotoURL, userPhotoURL) || other.userPhotoURL == userPhotoURL)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&const DeepCollectionEquality().equals(other._replies, _replies)&&const DeepCollectionEquality().equals(other._likes, _likes)&&const DeepCollectionEquality().equals(other._mentions, _mentions)&&(identical(other.isHighlighted, isHighlighted) || other.isHighlighted == isHighlighted)&&(identical(other.highlightedAt, highlightedAt) || other.highlightedAt == highlightedAt)&&(identical(other.highlightedByUserId, highlightedByUserId) || other.highlightedByUserId == highlightedByUserId)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&(identical(other.audioObjectKey, audioObjectKey) || other.audioObjectKey == audioObjectKey)&&(identical(other.audioDurationMs, audioDurationMs) || other.audioDurationMs == audioDurationMs)&&(identical(other.audioMimeType, audioMimeType) || other.audioMimeType == audioMimeType)&&(identical(other.audioSizeBytes, audioSizeBytes) || other.audioSizeBytes == audioSizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,const DeepCollectionEquality().hash(bookId),bookTitle,userId,username,text,rating,chapterTitle,chapterIndex,chapterId,quote,timestamp,feedPostId,userPhotoURL,displayName,penName,const DeepCollectionEquality().hash(_replies),const DeepCollectionEquality().hash(_likes),const DeepCollectionEquality().hash(_mentions),isHighlighted,highlightedAt,highlightedByUserId,audioUrl,audioObjectKey,audioDurationMs,audioMimeType,audioSizeBytes]);

@override
String toString() {
  return 'Comment(id: $id, bookId: $bookId, bookTitle: $bookTitle, userId: $userId, username: $username, text: $text, rating: $rating, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, chapterId: $chapterId, quote: $quote, timestamp: $timestamp, feedPostId: $feedPostId, userPhotoURL: $userPhotoURL, displayName: $displayName, penName: $penName, replies: $replies, likes: $likes, mentions: $mentions, isHighlighted: $isHighlighted, highlightedAt: $highlightedAt, highlightedByUserId: $highlightedByUserId, audioUrl: $audioUrl, audioObjectKey: $audioObjectKey, audioDurationMs: $audioDurationMs, audioMimeType: $audioMimeType, audioSizeBytes: $audioSizeBytes)';
}


}

/// @nodoc
abstract mixin class _$CommentCopyWith<$Res> implements $CommentCopyWith<$Res> {
  factory _$CommentCopyWith(_Comment value, $Res Function(_Comment) _then) = __$CommentCopyWithImpl;
@override @useResult
$Res call({
 String? id, dynamic bookId, String? bookTitle, String userId, String username, String text, int? rating, String? chapterTitle, int? chapterIndex, String? chapterId, String? quote, int timestamp, String? feedPostId, String? userPhotoURL, String? displayName, String? penName, List<CommentReply>? replies, List<String>? likes, Map<String, String>? mentions, bool? isHighlighted, int? highlightedAt, String? highlightedByUserId, String? audioUrl, String? audioObjectKey, int? audioDurationMs, String? audioMimeType, int? audioSizeBytes
});




}
/// @nodoc
class __$CommentCopyWithImpl<$Res>
    implements _$CommentCopyWith<$Res> {
  __$CommentCopyWithImpl(this._self, this._then);

  final _Comment _self;
  final $Res Function(_Comment) _then;

/// Create a copy of Comment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? bookId = freezed,Object? bookTitle = freezed,Object? userId = null,Object? username = null,Object? text = null,Object? rating = freezed,Object? chapterTitle = freezed,Object? chapterIndex = freezed,Object? chapterId = freezed,Object? quote = freezed,Object? timestamp = null,Object? feedPostId = freezed,Object? userPhotoURL = freezed,Object? displayName = freezed,Object? penName = freezed,Object? replies = freezed,Object? likes = freezed,Object? mentions = freezed,Object? isHighlighted = freezed,Object? highlightedAt = freezed,Object? highlightedByUserId = freezed,Object? audioUrl = freezed,Object? audioObjectKey = freezed,Object? audioDurationMs = freezed,Object? audioMimeType = freezed,Object? audioSizeBytes = freezed,}) {
  return _then(_Comment(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as dynamic,bookTitle: freezed == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterIndex: freezed == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,feedPostId: freezed == feedPostId ? _self.feedPostId : feedPostId // ignore: cast_nullable_to_non_nullable
as String?,userPhotoURL: freezed == userPhotoURL ? _self.userPhotoURL : userPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,replies: freezed == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentReply>?,likes: freezed == likes ? _self._likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>?,mentions: freezed == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,isHighlighted: freezed == isHighlighted ? _self.isHighlighted : isHighlighted // ignore: cast_nullable_to_non_nullable
as bool?,highlightedAt: freezed == highlightedAt ? _self.highlightedAt : highlightedAt // ignore: cast_nullable_to_non_nullable
as int?,highlightedByUserId: freezed == highlightedByUserId ? _self.highlightedByUserId : highlightedByUserId // ignore: cast_nullable_to_non_nullable
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
