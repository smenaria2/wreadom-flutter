// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chapter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChapterVersion {

 String get content; int get timestamp; int get wordCount;
/// Create a copy of ChapterVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterVersionCopyWith<ChapterVersion> get copyWith => _$ChapterVersionCopyWithImpl<ChapterVersion>(this as ChapterVersion, _$identity);

  /// Serializes this ChapterVersion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterVersion&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.wordCount, wordCount) || other.wordCount == wordCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,timestamp,wordCount);

@override
String toString() {
  return 'ChapterVersion(content: $content, timestamp: $timestamp, wordCount: $wordCount)';
}


}

/// @nodoc
abstract mixin class $ChapterVersionCopyWith<$Res>  {
  factory $ChapterVersionCopyWith(ChapterVersion value, $Res Function(ChapterVersion) _then) = _$ChapterVersionCopyWithImpl;
@useResult
$Res call({
 String content, int timestamp, int wordCount
});




}
/// @nodoc
class _$ChapterVersionCopyWithImpl<$Res>
    implements $ChapterVersionCopyWith<$Res> {
  _$ChapterVersionCopyWithImpl(this._self, this._then);

  final ChapterVersion _self;
  final $Res Function(ChapterVersion) _then;

/// Create a copy of ChapterVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? timestamp = null,Object? wordCount = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,wordCount: null == wordCount ? _self.wordCount : wordCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterVersion].
extension ChapterVersionPatterns on ChapterVersion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterVersion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterVersion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterVersion value)  $default,){
final _that = this;
switch (_that) {
case _ChapterVersion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterVersion value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterVersion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  int timestamp,  int wordCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterVersion() when $default != null:
return $default(_that.content,_that.timestamp,_that.wordCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  int timestamp,  int wordCount)  $default,) {final _that = this;
switch (_that) {
case _ChapterVersion():
return $default(_that.content,_that.timestamp,_that.wordCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  int timestamp,  int wordCount)?  $default,) {final _that = this;
switch (_that) {
case _ChapterVersion() when $default != null:
return $default(_that.content,_that.timestamp,_that.wordCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChapterVersion implements ChapterVersion {
  const _ChapterVersion({required this.content, required this.timestamp, required this.wordCount});
  factory _ChapterVersion.fromJson(Map<String, dynamic> json) => _$ChapterVersionFromJson(json);

@override final  String content;
@override final  int timestamp;
@override final  int wordCount;

/// Create a copy of ChapterVersion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterVersionCopyWith<_ChapterVersion> get copyWith => __$ChapterVersionCopyWithImpl<_ChapterVersion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterVersionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterVersion&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.wordCount, wordCount) || other.wordCount == wordCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,timestamp,wordCount);

@override
String toString() {
  return 'ChapterVersion(content: $content, timestamp: $timestamp, wordCount: $wordCount)';
}


}

/// @nodoc
abstract mixin class _$ChapterVersionCopyWith<$Res> implements $ChapterVersionCopyWith<$Res> {
  factory _$ChapterVersionCopyWith(_ChapterVersion value, $Res Function(_ChapterVersion) _then) = __$ChapterVersionCopyWithImpl;
@override @useResult
$Res call({
 String content, int timestamp, int wordCount
});




}
/// @nodoc
class __$ChapterVersionCopyWithImpl<$Res>
    implements _$ChapterVersionCopyWith<$Res> {
  __$ChapterVersionCopyWithImpl(this._self, this._then);

  final _ChapterVersion _self;
  final $Res Function(_ChapterVersion) _then;

/// Create a copy of ChapterVersion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? timestamp = null,Object? wordCount = null,}) {
  return _then(_ChapterVersion(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,wordCount: null == wordCount ? _self.wordCount : wordCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Chapter {

 String get id; String get title; String get content; int get index; String? get status; List<ChapterVersion>? get versions; int? get lastSavedAt; bool? get isTitleLocked; String? get originalBookId;
/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterCopyWith<Chapter> get copyWith => _$ChapterCopyWithImpl<Chapter>(this as Chapter, _$identity);

  /// Serializes this Chapter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Chapter&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.index, index) || other.index == index)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.versions, versions)&&(identical(other.lastSavedAt, lastSavedAt) || other.lastSavedAt == lastSavedAt)&&(identical(other.isTitleLocked, isTitleLocked) || other.isTitleLocked == isTitleLocked)&&(identical(other.originalBookId, originalBookId) || other.originalBookId == originalBookId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,index,status,const DeepCollectionEquality().hash(versions),lastSavedAt,isTitleLocked,originalBookId);

@override
String toString() {
  return 'Chapter(id: $id, title: $title, content: $content, index: $index, status: $status, versions: $versions, lastSavedAt: $lastSavedAt, isTitleLocked: $isTitleLocked, originalBookId: $originalBookId)';
}


}

/// @nodoc
abstract mixin class $ChapterCopyWith<$Res>  {
  factory $ChapterCopyWith(Chapter value, $Res Function(Chapter) _then) = _$ChapterCopyWithImpl;
@useResult
$Res call({
 String id, String title, String content, int index, String? status, List<ChapterVersion>? versions, int? lastSavedAt, bool? isTitleLocked, String? originalBookId
});




}
/// @nodoc
class _$ChapterCopyWithImpl<$Res>
    implements $ChapterCopyWith<$Res> {
  _$ChapterCopyWithImpl(this._self, this._then);

  final Chapter _self;
  final $Res Function(Chapter) _then;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? index = null,Object? status = freezed,Object? versions = freezed,Object? lastSavedAt = freezed,Object? isTitleLocked = freezed,Object? originalBookId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,versions: freezed == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as List<ChapterVersion>?,lastSavedAt: freezed == lastSavedAt ? _self.lastSavedAt : lastSavedAt // ignore: cast_nullable_to_non_nullable
as int?,isTitleLocked: freezed == isTitleLocked ? _self.isTitleLocked : isTitleLocked // ignore: cast_nullable_to_non_nullable
as bool?,originalBookId: freezed == originalBookId ? _self.originalBookId : originalBookId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Chapter].
extension ChapterPatterns on Chapter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Chapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Chapter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Chapter value)  $default,){
final _that = this;
switch (_that) {
case _Chapter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Chapter value)?  $default,){
final _that = this;
switch (_that) {
case _Chapter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String content,  int index,  String? status,  List<ChapterVersion>? versions,  int? lastSavedAt,  bool? isTitleLocked,  String? originalBookId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Chapter() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.index,_that.status,_that.versions,_that.lastSavedAt,_that.isTitleLocked,_that.originalBookId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String content,  int index,  String? status,  List<ChapterVersion>? versions,  int? lastSavedAt,  bool? isTitleLocked,  String? originalBookId)  $default,) {final _that = this;
switch (_that) {
case _Chapter():
return $default(_that.id,_that.title,_that.content,_that.index,_that.status,_that.versions,_that.lastSavedAt,_that.isTitleLocked,_that.originalBookId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String content,  int index,  String? status,  List<ChapterVersion>? versions,  int? lastSavedAt,  bool? isTitleLocked,  String? originalBookId)?  $default,) {final _that = this;
switch (_that) {
case _Chapter() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.index,_that.status,_that.versions,_that.lastSavedAt,_that.isTitleLocked,_that.originalBookId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Chapter implements Chapter {
  const _Chapter({required this.id, required this.title, required this.content, required this.index, this.status, final  List<ChapterVersion>? versions, this.lastSavedAt, this.isTitleLocked, this.originalBookId}): _versions = versions;
  factory _Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);

@override final  String id;
@override final  String title;
@override final  String content;
@override final  int index;
@override final  String? status;
 final  List<ChapterVersion>? _versions;
@override List<ChapterVersion>? get versions {
  final value = _versions;
  if (value == null) return null;
  if (_versions is EqualUnmodifiableListView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? lastSavedAt;
@override final  bool? isTitleLocked;
@override final  String? originalBookId;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterCopyWith<_Chapter> get copyWith => __$ChapterCopyWithImpl<_Chapter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Chapter&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.index, index) || other.index == index)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._versions, _versions)&&(identical(other.lastSavedAt, lastSavedAt) || other.lastSavedAt == lastSavedAt)&&(identical(other.isTitleLocked, isTitleLocked) || other.isTitleLocked == isTitleLocked)&&(identical(other.originalBookId, originalBookId) || other.originalBookId == originalBookId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,index,status,const DeepCollectionEquality().hash(_versions),lastSavedAt,isTitleLocked,originalBookId);

@override
String toString() {
  return 'Chapter(id: $id, title: $title, content: $content, index: $index, status: $status, versions: $versions, lastSavedAt: $lastSavedAt, isTitleLocked: $isTitleLocked, originalBookId: $originalBookId)';
}


}

/// @nodoc
abstract mixin class _$ChapterCopyWith<$Res> implements $ChapterCopyWith<$Res> {
  factory _$ChapterCopyWith(_Chapter value, $Res Function(_Chapter) _then) = __$ChapterCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String content, int index, String? status, List<ChapterVersion>? versions, int? lastSavedAt, bool? isTitleLocked, String? originalBookId
});




}
/// @nodoc
class __$ChapterCopyWithImpl<$Res>
    implements _$ChapterCopyWith<$Res> {
  __$ChapterCopyWithImpl(this._self, this._then);

  final _Chapter _self;
  final $Res Function(_Chapter) _then;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? index = null,Object? status = freezed,Object? versions = freezed,Object? lastSavedAt = freezed,Object? isTitleLocked = freezed,Object? originalBookId = freezed,}) {
  return _then(_Chapter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,versions: freezed == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as List<ChapterVersion>?,lastSavedAt: freezed == lastSavedAt ? _self.lastSavedAt : lastSavedAt // ignore: cast_nullable_to_non_nullable
as int?,isTitleLocked: freezed == isTitleLocked ? _self.isTitleLocked : isTitleLocked // ignore: cast_nullable_to_non_nullable
as bool?,originalBookId: freezed == originalBookId ? _self.originalBookId : originalBookId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
