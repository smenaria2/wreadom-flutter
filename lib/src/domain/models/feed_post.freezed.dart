// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoryImage {

 String get id; String get url; String? get caption; List<String> get likes;
/// Create a copy of StoryImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryImageCopyWith<StoryImage> get copyWith => _$StoryImageCopyWithImpl<StoryImage>(this as StoryImage, _$identity);

  /// Serializes this StoryImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other.likes, likes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,caption,const DeepCollectionEquality().hash(likes));

@override
String toString() {
  return 'StoryImage(id: $id, url: $url, caption: $caption, likes: $likes)';
}


}

/// @nodoc
abstract mixin class $StoryImageCopyWith<$Res>  {
  factory $StoryImageCopyWith(StoryImage value, $Res Function(StoryImage) _then) = _$StoryImageCopyWithImpl;
@useResult
$Res call({
 String id, String url, String? caption, List<String> likes
});




}
/// @nodoc
class _$StoryImageCopyWithImpl<$Res>
    implements $StoryImageCopyWith<$Res> {
  _$StoryImageCopyWithImpl(this._self, this._then);

  final StoryImage _self;
  final $Res Function(StoryImage) _then;

/// Create a copy of StoryImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? caption = freezed,Object? likes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryImage].
extension StoryImagePatterns on StoryImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryImage value)  $default,){
final _that = this;
switch (_that) {
case _StoryImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryImage value)?  $default,){
final _that = this;
switch (_that) {
case _StoryImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String url,  String? caption,  List<String> likes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryImage() when $default != null:
return $default(_that.id,_that.url,_that.caption,_that.likes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String url,  String? caption,  List<String> likes)  $default,) {final _that = this;
switch (_that) {
case _StoryImage():
return $default(_that.id,_that.url,_that.caption,_that.likes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String url,  String? caption,  List<String> likes)?  $default,) {final _that = this;
switch (_that) {
case _StoryImage() when $default != null:
return $default(_that.id,_that.url,_that.caption,_that.likes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryImage implements StoryImage {
  const _StoryImage({required this.id, required this.url, this.caption, required final  List<String> likes}): _likes = likes;
  factory _StoryImage.fromJson(Map<String, dynamic> json) => _$StoryImageFromJson(json);

@override final  String id;
@override final  String url;
@override final  String? caption;
 final  List<String> _likes;
@override List<String> get likes {
  if (_likes is EqualUnmodifiableListView) return _likes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_likes);
}


/// Create a copy of StoryImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryImageCopyWith<_StoryImage> get copyWith => __$StoryImageCopyWithImpl<_StoryImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoryImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.caption, caption) || other.caption == caption)&&const DeepCollectionEquality().equals(other._likes, _likes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,caption,const DeepCollectionEquality().hash(_likes));

@override
String toString() {
  return 'StoryImage(id: $id, url: $url, caption: $caption, likes: $likes)';
}


}

/// @nodoc
abstract mixin class _$StoryImageCopyWith<$Res> implements $StoryImageCopyWith<$Res> {
  factory _$StoryImageCopyWith(_StoryImage value, $Res Function(_StoryImage) _then) = __$StoryImageCopyWithImpl;
@override @useResult
$Res call({
 String id, String url, String? caption, List<String> likes
});




}
/// @nodoc
class __$StoryImageCopyWithImpl<$Res>
    implements _$StoryImageCopyWith<$Res> {
  __$StoryImageCopyWithImpl(this._self, this._then);

  final _StoryImage _self;
  final $Res Function(_StoryImage) _then;

/// Create a copy of StoryImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? caption = freezed,Object? likes = null,}) {
  return _then(_StoryImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,likes: null == likes ? _self._likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$FeedPost {

 String? get id; String get userId; String get username; String get type;// 'comment' | 'quote' | 'review' | 'testimony' | 'post'
 dynamic get bookId; String? get bookTitle; String? get bookCover; String get text; String? get quote; int? get rating; String? get chapterTitle; String? get chapterId; int get timestamp; List<String> get likes; String? get userPhotoURL; String? get displayName; String? get penName; List<CommentReply>? get comments; String? get targetUserId; String? get targetUsername; String? get targetUserDisplayName; String? get targetUserPenName; String? get privacy; String get visibility; String? get imageUrl; List<StoryImage>? get images; bool? get userIsDeactivated; Map<String, String>? get mentions;
/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedPostCopyWith<FeedPost> get copyWith => _$FeedPostCopyWithImpl<FeedPost>(this as FeedPost, _$identity);

  /// Serializes this FeedPost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedPost&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.bookId, bookId)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.bookCover, bookCover) || other.bookCover == bookCover)&&(identical(other.text, text) || other.text == text)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.likes, likes)&&(identical(other.userPhotoURL, userPhotoURL) || other.userPhotoURL == userPhotoURL)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&const DeepCollectionEquality().equals(other.comments, comments)&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId)&&(identical(other.targetUsername, targetUsername) || other.targetUsername == targetUsername)&&(identical(other.targetUserDisplayName, targetUserDisplayName) || other.targetUserDisplayName == targetUserDisplayName)&&(identical(other.targetUserPenName, targetUserPenName) || other.targetUserPenName == targetUserPenName)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.userIsDeactivated, userIsDeactivated) || other.userIsDeactivated == userIsDeactivated)&&const DeepCollectionEquality().equals(other.mentions, mentions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,username,type,const DeepCollectionEquality().hash(bookId),bookTitle,bookCover,text,quote,rating,chapterTitle,chapterId,timestamp,const DeepCollectionEquality().hash(likes),userPhotoURL,displayName,penName,const DeepCollectionEquality().hash(comments),targetUserId,targetUsername,targetUserDisplayName,targetUserPenName,privacy,visibility,imageUrl,const DeepCollectionEquality().hash(images),userIsDeactivated,const DeepCollectionEquality().hash(mentions)]);

@override
String toString() {
  return 'FeedPost(id: $id, userId: $userId, username: $username, type: $type, bookId: $bookId, bookTitle: $bookTitle, bookCover: $bookCover, text: $text, quote: $quote, rating: $rating, chapterTitle: $chapterTitle, chapterId: $chapterId, timestamp: $timestamp, likes: $likes, userPhotoURL: $userPhotoURL, displayName: $displayName, penName: $penName, comments: $comments, targetUserId: $targetUserId, targetUsername: $targetUsername, targetUserDisplayName: $targetUserDisplayName, targetUserPenName: $targetUserPenName, privacy: $privacy, visibility: $visibility, imageUrl: $imageUrl, images: $images, userIsDeactivated: $userIsDeactivated, mentions: $mentions)';
}


}

/// @nodoc
abstract mixin class $FeedPostCopyWith<$Res>  {
  factory $FeedPostCopyWith(FeedPost value, $Res Function(FeedPost) _then) = _$FeedPostCopyWithImpl;
@useResult
$Res call({
 String? id, String userId, String username, String type, dynamic bookId, String? bookTitle, String? bookCover, String text, String? quote, int? rating, String? chapterTitle, String? chapterId, int timestamp, List<String> likes, String? userPhotoURL, String? displayName, String? penName, List<CommentReply>? comments, String? targetUserId, String? targetUsername, String? targetUserDisplayName, String? targetUserPenName, String? privacy, String visibility, String? imageUrl, List<StoryImage>? images, bool? userIsDeactivated, Map<String, String>? mentions
});




}
/// @nodoc
class _$FeedPostCopyWithImpl<$Res>
    implements $FeedPostCopyWith<$Res> {
  _$FeedPostCopyWithImpl(this._self, this._then);

  final FeedPost _self;
  final $Res Function(FeedPost) _then;

/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? username = null,Object? type = null,Object? bookId = freezed,Object? bookTitle = freezed,Object? bookCover = freezed,Object? text = null,Object? quote = freezed,Object? rating = freezed,Object? chapterTitle = freezed,Object? chapterId = freezed,Object? timestamp = null,Object? likes = null,Object? userPhotoURL = freezed,Object? displayName = freezed,Object? penName = freezed,Object? comments = freezed,Object? targetUserId = freezed,Object? targetUsername = freezed,Object? targetUserDisplayName = freezed,Object? targetUserPenName = freezed,Object? privacy = freezed,Object? visibility = null,Object? imageUrl = freezed,Object? images = freezed,Object? userIsDeactivated = freezed,Object? mentions = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as dynamic,bookTitle: freezed == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String?,bookCover: freezed == bookCover ? _self.bookCover : bookCover // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>,userPhotoURL: freezed == userPhotoURL ? _self.userPhotoURL : userPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,comments: freezed == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as List<CommentReply>?,targetUserId: freezed == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String?,targetUsername: freezed == targetUsername ? _self.targetUsername : targetUsername // ignore: cast_nullable_to_non_nullable
as String?,targetUserDisplayName: freezed == targetUserDisplayName ? _self.targetUserDisplayName : targetUserDisplayName // ignore: cast_nullable_to_non_nullable
as String?,targetUserPenName: freezed == targetUserPenName ? _self.targetUserPenName : targetUserPenName // ignore: cast_nullable_to_non_nullable
as String?,privacy: freezed == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,images: freezed == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<StoryImage>?,userIsDeactivated: freezed == userIsDeactivated ? _self.userIsDeactivated : userIsDeactivated // ignore: cast_nullable_to_non_nullable
as bool?,mentions: freezed == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedPost].
extension FeedPostPatterns on FeedPost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedPost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedPost value)  $default,){
final _that = this;
switch (_that) {
case _FeedPost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedPost value)?  $default,){
final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String userId,  String username,  String type,  dynamic bookId,  String? bookTitle,  String? bookCover,  String text,  String? quote,  int? rating,  String? chapterTitle,  String? chapterId,  int timestamp,  List<String> likes,  String? userPhotoURL,  String? displayName,  String? penName,  List<CommentReply>? comments,  String? targetUserId,  String? targetUsername,  String? targetUserDisplayName,  String? targetUserPenName,  String? privacy,  String visibility,  String? imageUrl,  List<StoryImage>? images,  bool? userIsDeactivated,  Map<String, String>? mentions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
return $default(_that.id,_that.userId,_that.username,_that.type,_that.bookId,_that.bookTitle,_that.bookCover,_that.text,_that.quote,_that.rating,_that.chapterTitle,_that.chapterId,_that.timestamp,_that.likes,_that.userPhotoURL,_that.displayName,_that.penName,_that.comments,_that.targetUserId,_that.targetUsername,_that.targetUserDisplayName,_that.targetUserPenName,_that.privacy,_that.visibility,_that.imageUrl,_that.images,_that.userIsDeactivated,_that.mentions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String userId,  String username,  String type,  dynamic bookId,  String? bookTitle,  String? bookCover,  String text,  String? quote,  int? rating,  String? chapterTitle,  String? chapterId,  int timestamp,  List<String> likes,  String? userPhotoURL,  String? displayName,  String? penName,  List<CommentReply>? comments,  String? targetUserId,  String? targetUsername,  String? targetUserDisplayName,  String? targetUserPenName,  String? privacy,  String visibility,  String? imageUrl,  List<StoryImage>? images,  bool? userIsDeactivated,  Map<String, String>? mentions)  $default,) {final _that = this;
switch (_that) {
case _FeedPost():
return $default(_that.id,_that.userId,_that.username,_that.type,_that.bookId,_that.bookTitle,_that.bookCover,_that.text,_that.quote,_that.rating,_that.chapterTitle,_that.chapterId,_that.timestamp,_that.likes,_that.userPhotoURL,_that.displayName,_that.penName,_that.comments,_that.targetUserId,_that.targetUsername,_that.targetUserDisplayName,_that.targetUserPenName,_that.privacy,_that.visibility,_that.imageUrl,_that.images,_that.userIsDeactivated,_that.mentions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String userId,  String username,  String type,  dynamic bookId,  String? bookTitle,  String? bookCover,  String text,  String? quote,  int? rating,  String? chapterTitle,  String? chapterId,  int timestamp,  List<String> likes,  String? userPhotoURL,  String? displayName,  String? penName,  List<CommentReply>? comments,  String? targetUserId,  String? targetUsername,  String? targetUserDisplayName,  String? targetUserPenName,  String? privacy,  String visibility,  String? imageUrl,  List<StoryImage>? images,  bool? userIsDeactivated,  Map<String, String>? mentions)?  $default,) {final _that = this;
switch (_that) {
case _FeedPost() when $default != null:
return $default(_that.id,_that.userId,_that.username,_that.type,_that.bookId,_that.bookTitle,_that.bookCover,_that.text,_that.quote,_that.rating,_that.chapterTitle,_that.chapterId,_that.timestamp,_that.likes,_that.userPhotoURL,_that.displayName,_that.penName,_that.comments,_that.targetUserId,_that.targetUsername,_that.targetUserDisplayName,_that.targetUserPenName,_that.privacy,_that.visibility,_that.imageUrl,_that.images,_that.userIsDeactivated,_that.mentions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedPost implements FeedPost {
  const _FeedPost({this.id, required this.userId, required this.username, required this.type, this.bookId, this.bookTitle, this.bookCover, required this.text, this.quote, this.rating, this.chapterTitle, this.chapterId, required this.timestamp, required final  List<String> likes, this.userPhotoURL, this.displayName, this.penName, final  List<CommentReply>? comments, this.targetUserId, this.targetUsername, this.targetUserDisplayName, this.targetUserPenName, this.privacy, required this.visibility, this.imageUrl, final  List<StoryImage>? images, this.userIsDeactivated, final  Map<String, String>? mentions}): _likes = likes,_comments = comments,_images = images,_mentions = mentions;
  factory _FeedPost.fromJson(Map<String, dynamic> json) => _$FeedPostFromJson(json);

@override final  String? id;
@override final  String userId;
@override final  String username;
@override final  String type;
// 'comment' | 'quote' | 'review' | 'testimony' | 'post'
@override final  dynamic bookId;
@override final  String? bookTitle;
@override final  String? bookCover;
@override final  String text;
@override final  String? quote;
@override final  int? rating;
@override final  String? chapterTitle;
@override final  String? chapterId;
@override final  int timestamp;
 final  List<String> _likes;
@override List<String> get likes {
  if (_likes is EqualUnmodifiableListView) return _likes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_likes);
}

@override final  String? userPhotoURL;
@override final  String? displayName;
@override final  String? penName;
 final  List<CommentReply>? _comments;
@override List<CommentReply>? get comments {
  final value = _comments;
  if (value == null) return null;
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? targetUserId;
@override final  String? targetUsername;
@override final  String? targetUserDisplayName;
@override final  String? targetUserPenName;
@override final  String? privacy;
@override final  String visibility;
@override final  String? imageUrl;
 final  List<StoryImage>? _images;
@override List<StoryImage>? get images {
  final value = _images;
  if (value == null) return null;
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  bool? userIsDeactivated;
 final  Map<String, String>? _mentions;
@override Map<String, String>? get mentions {
  final value = _mentions;
  if (value == null) return null;
  if (_mentions is EqualUnmodifiableMapView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedPostCopyWith<_FeedPost> get copyWith => __$FeedPostCopyWithImpl<_FeedPost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedPostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedPost&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.bookId, bookId)&&(identical(other.bookTitle, bookTitle) || other.bookTitle == bookTitle)&&(identical(other.bookCover, bookCover) || other.bookCover == bookCover)&&(identical(other.text, text) || other.text == text)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._likes, _likes)&&(identical(other.userPhotoURL, userPhotoURL) || other.userPhotoURL == userPhotoURL)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&const DeepCollectionEquality().equals(other._comments, _comments)&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId)&&(identical(other.targetUsername, targetUsername) || other.targetUsername == targetUsername)&&(identical(other.targetUserDisplayName, targetUserDisplayName) || other.targetUserDisplayName == targetUserDisplayName)&&(identical(other.targetUserPenName, targetUserPenName) || other.targetUserPenName == targetUserPenName)&&(identical(other.privacy, privacy) || other.privacy == privacy)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.userIsDeactivated, userIsDeactivated) || other.userIsDeactivated == userIsDeactivated)&&const DeepCollectionEquality().equals(other._mentions, _mentions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,username,type,const DeepCollectionEquality().hash(bookId),bookTitle,bookCover,text,quote,rating,chapterTitle,chapterId,timestamp,const DeepCollectionEquality().hash(_likes),userPhotoURL,displayName,penName,const DeepCollectionEquality().hash(_comments),targetUserId,targetUsername,targetUserDisplayName,targetUserPenName,privacy,visibility,imageUrl,const DeepCollectionEquality().hash(_images),userIsDeactivated,const DeepCollectionEquality().hash(_mentions)]);

@override
String toString() {
  return 'FeedPost(id: $id, userId: $userId, username: $username, type: $type, bookId: $bookId, bookTitle: $bookTitle, bookCover: $bookCover, text: $text, quote: $quote, rating: $rating, chapterTitle: $chapterTitle, chapterId: $chapterId, timestamp: $timestamp, likes: $likes, userPhotoURL: $userPhotoURL, displayName: $displayName, penName: $penName, comments: $comments, targetUserId: $targetUserId, targetUsername: $targetUsername, targetUserDisplayName: $targetUserDisplayName, targetUserPenName: $targetUserPenName, privacy: $privacy, visibility: $visibility, imageUrl: $imageUrl, images: $images, userIsDeactivated: $userIsDeactivated, mentions: $mentions)';
}


}

/// @nodoc
abstract mixin class _$FeedPostCopyWith<$Res> implements $FeedPostCopyWith<$Res> {
  factory _$FeedPostCopyWith(_FeedPost value, $Res Function(_FeedPost) _then) = __$FeedPostCopyWithImpl;
@override @useResult
$Res call({
 String? id, String userId, String username, String type, dynamic bookId, String? bookTitle, String? bookCover, String text, String? quote, int? rating, String? chapterTitle, String? chapterId, int timestamp, List<String> likes, String? userPhotoURL, String? displayName, String? penName, List<CommentReply>? comments, String? targetUserId, String? targetUsername, String? targetUserDisplayName, String? targetUserPenName, String? privacy, String visibility, String? imageUrl, List<StoryImage>? images, bool? userIsDeactivated, Map<String, String>? mentions
});




}
/// @nodoc
class __$FeedPostCopyWithImpl<$Res>
    implements _$FeedPostCopyWith<$Res> {
  __$FeedPostCopyWithImpl(this._self, this._then);

  final _FeedPost _self;
  final $Res Function(_FeedPost) _then;

/// Create a copy of FeedPost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? username = null,Object? type = null,Object? bookId = freezed,Object? bookTitle = freezed,Object? bookCover = freezed,Object? text = null,Object? quote = freezed,Object? rating = freezed,Object? chapterTitle = freezed,Object? chapterId = freezed,Object? timestamp = null,Object? likes = null,Object? userPhotoURL = freezed,Object? displayName = freezed,Object? penName = freezed,Object? comments = freezed,Object? targetUserId = freezed,Object? targetUsername = freezed,Object? targetUserDisplayName = freezed,Object? targetUserPenName = freezed,Object? privacy = freezed,Object? visibility = null,Object? imageUrl = freezed,Object? images = freezed,Object? userIsDeactivated = freezed,Object? mentions = freezed,}) {
  return _then(_FeedPost(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as dynamic,bookTitle: freezed == bookTitle ? _self.bookTitle : bookTitle // ignore: cast_nullable_to_non_nullable
as String?,bookCover: freezed == bookCover ? _self.bookCover : bookCover // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,likes: null == likes ? _self._likes : likes // ignore: cast_nullable_to_non_nullable
as List<String>,userPhotoURL: freezed == userPhotoURL ? _self.userPhotoURL : userPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,comments: freezed == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<CommentReply>?,targetUserId: freezed == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String?,targetUsername: freezed == targetUsername ? _self.targetUsername : targetUsername // ignore: cast_nullable_to_non_nullable
as String?,targetUserDisplayName: freezed == targetUserDisplayName ? _self.targetUserDisplayName : targetUserDisplayName // ignore: cast_nullable_to_non_nullable
as String?,targetUserPenName: freezed == targetUserPenName ? _self.targetUserPenName : targetUserPenName // ignore: cast_nullable_to_non_nullable
as String?,privacy: freezed == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,images: freezed == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<StoryImage>?,userIsDeactivated: freezed == userIsDeactivated ? _self.userIsDeactivated : userIsDeactivated // ignore: cast_nullable_to_non_nullable
as bool?,mentions: freezed == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,
  ));
}


}

// dart format on
