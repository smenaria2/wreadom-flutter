// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CollectionCoverSnapshot {

 String get bookId; String get coverUrl;
/// Create a copy of CollectionCoverSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionCoverSnapshotCopyWith<CollectionCoverSnapshot> get copyWith => _$CollectionCoverSnapshotCopyWithImpl<CollectionCoverSnapshot>(this as CollectionCoverSnapshot, _$identity);

  /// Serializes this CollectionCoverSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionCoverSnapshot&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookId,coverUrl);

@override
String toString() {
  return 'CollectionCoverSnapshot(bookId: $bookId, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class $CollectionCoverSnapshotCopyWith<$Res>  {
  factory $CollectionCoverSnapshotCopyWith(CollectionCoverSnapshot value, $Res Function(CollectionCoverSnapshot) _then) = _$CollectionCoverSnapshotCopyWithImpl;
@useResult
$Res call({
 String bookId, String coverUrl
});




}
/// @nodoc
class _$CollectionCoverSnapshotCopyWithImpl<$Res>
    implements $CollectionCoverSnapshotCopyWith<$Res> {
  _$CollectionCoverSnapshotCopyWithImpl(this._self, this._then);

  final CollectionCoverSnapshot _self;
  final $Res Function(CollectionCoverSnapshot) _then;

/// Create a copy of CollectionCoverSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookId = null,Object? coverUrl = null,}) {
  return _then(_self.copyWith(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionCoverSnapshot].
extension CollectionCoverSnapshotPatterns on CollectionCoverSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionCoverSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionCoverSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionCoverSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _CollectionCoverSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionCoverSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionCoverSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bookId,  String coverUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionCoverSnapshot() when $default != null:
return $default(_that.bookId,_that.coverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bookId,  String coverUrl)  $default,) {final _that = this;
switch (_that) {
case _CollectionCoverSnapshot():
return $default(_that.bookId,_that.coverUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bookId,  String coverUrl)?  $default,) {final _that = this;
switch (_that) {
case _CollectionCoverSnapshot() when $default != null:
return $default(_that.bookId,_that.coverUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionCoverSnapshot implements CollectionCoverSnapshot {
  const _CollectionCoverSnapshot({required this.bookId, required this.coverUrl});
  factory _CollectionCoverSnapshot.fromJson(Map<String, dynamic> json) => _$CollectionCoverSnapshotFromJson(json);

@override final  String bookId;
@override final  String coverUrl;

/// Create a copy of CollectionCoverSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionCoverSnapshotCopyWith<_CollectionCoverSnapshot> get copyWith => __$CollectionCoverSnapshotCopyWithImpl<_CollectionCoverSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionCoverSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionCoverSnapshot&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookId,coverUrl);

@override
String toString() {
  return 'CollectionCoverSnapshot(bookId: $bookId, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class _$CollectionCoverSnapshotCopyWith<$Res> implements $CollectionCoverSnapshotCopyWith<$Res> {
  factory _$CollectionCoverSnapshotCopyWith(_CollectionCoverSnapshot value, $Res Function(_CollectionCoverSnapshot) _then) = __$CollectionCoverSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String bookId, String coverUrl
});




}
/// @nodoc
class __$CollectionCoverSnapshotCopyWithImpl<$Res>
    implements _$CollectionCoverSnapshotCopyWith<$Res> {
  __$CollectionCoverSnapshotCopyWithImpl(this._self, this._then);

  final _CollectionCoverSnapshot _self;
  final $Res Function(_CollectionCoverSnapshot) _then;

/// Create a copy of CollectionCoverSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookId = null,Object? coverUrl = null,}) {
  return _then(_CollectionCoverSnapshot(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookCollection {

 String get id; String get ownerId; String get title; String get description; int get bookCount; List<String> get coverBookIds; List<CollectionCoverSnapshot> get coverBooks; int? get createdAt; int? get updatedAt;
/// Create a copy of BookCollection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookCollectionCopyWith<BookCollection> get copyWith => _$BookCollectionCopyWithImpl<BookCollection>(this as BookCollection, _$identity);

  /// Serializes this BookCollection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookCollection&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.bookCount, bookCount) || other.bookCount == bookCount)&&const DeepCollectionEquality().equals(other.coverBookIds, coverBookIds)&&const DeepCollectionEquality().equals(other.coverBooks, coverBooks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,title,description,bookCount,const DeepCollectionEquality().hash(coverBookIds),const DeepCollectionEquality().hash(coverBooks),createdAt,updatedAt);

@override
String toString() {
  return 'BookCollection(id: $id, ownerId: $ownerId, title: $title, description: $description, bookCount: $bookCount, coverBookIds: $coverBookIds, coverBooks: $coverBooks, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BookCollectionCopyWith<$Res>  {
  factory $BookCollectionCopyWith(BookCollection value, $Res Function(BookCollection) _then) = _$BookCollectionCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String title, String description, int bookCount, List<String> coverBookIds, List<CollectionCoverSnapshot> coverBooks, int? createdAt, int? updatedAt
});




}
/// @nodoc
class _$BookCollectionCopyWithImpl<$Res>
    implements $BookCollectionCopyWith<$Res> {
  _$BookCollectionCopyWithImpl(this._self, this._then);

  final BookCollection _self;
  final $Res Function(BookCollection) _then;

/// Create a copy of BookCollection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? title = null,Object? description = null,Object? bookCount = null,Object? coverBookIds = null,Object? coverBooks = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,bookCount: null == bookCount ? _self.bookCount : bookCount // ignore: cast_nullable_to_non_nullable
as int,coverBookIds: null == coverBookIds ? _self.coverBookIds : coverBookIds // ignore: cast_nullable_to_non_nullable
as List<String>,coverBooks: null == coverBooks ? _self.coverBooks : coverBooks // ignore: cast_nullable_to_non_nullable
as List<CollectionCoverSnapshot>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookCollection].
extension BookCollectionPatterns on BookCollection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookCollection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookCollection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookCollection value)  $default,){
final _that = this;
switch (_that) {
case _BookCollection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookCollection value)?  $default,){
final _that = this;
switch (_that) {
case _BookCollection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String title,  String description,  int bookCount,  List<String> coverBookIds,  List<CollectionCoverSnapshot> coverBooks,  int? createdAt,  int? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookCollection() when $default != null:
return $default(_that.id,_that.ownerId,_that.title,_that.description,_that.bookCount,_that.coverBookIds,_that.coverBooks,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String title,  String description,  int bookCount,  List<String> coverBookIds,  List<CollectionCoverSnapshot> coverBooks,  int? createdAt,  int? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BookCollection():
return $default(_that.id,_that.ownerId,_that.title,_that.description,_that.bookCount,_that.coverBookIds,_that.coverBooks,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String title,  String description,  int bookCount,  List<String> coverBookIds,  List<CollectionCoverSnapshot> coverBooks,  int? createdAt,  int? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookCollection() when $default != null:
return $default(_that.id,_that.ownerId,_that.title,_that.description,_that.bookCount,_that.coverBookIds,_that.coverBooks,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookCollection implements BookCollection {
  const _BookCollection({required this.id, required this.ownerId, required this.title, this.description = '', this.bookCount = 0, final  List<String> coverBookIds = const <String>[], final  List<CollectionCoverSnapshot> coverBooks = const <CollectionCoverSnapshot>[], this.createdAt, this.updatedAt}): _coverBookIds = coverBookIds,_coverBooks = coverBooks;
  factory _BookCollection.fromJson(Map<String, dynamic> json) => _$BookCollectionFromJson(json);

@override final  String id;
@override final  String ownerId;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  int bookCount;
 final  List<String> _coverBookIds;
@override@JsonKey() List<String> get coverBookIds {
  if (_coverBookIds is EqualUnmodifiableListView) return _coverBookIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coverBookIds);
}

 final  List<CollectionCoverSnapshot> _coverBooks;
@override@JsonKey() List<CollectionCoverSnapshot> get coverBooks {
  if (_coverBooks is EqualUnmodifiableListView) return _coverBooks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coverBooks);
}

@override final  int? createdAt;
@override final  int? updatedAt;

/// Create a copy of BookCollection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookCollectionCopyWith<_BookCollection> get copyWith => __$BookCollectionCopyWithImpl<_BookCollection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookCollectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookCollection&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.bookCount, bookCount) || other.bookCount == bookCount)&&const DeepCollectionEquality().equals(other._coverBookIds, _coverBookIds)&&const DeepCollectionEquality().equals(other._coverBooks, _coverBooks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,title,description,bookCount,const DeepCollectionEquality().hash(_coverBookIds),const DeepCollectionEquality().hash(_coverBooks),createdAt,updatedAt);

@override
String toString() {
  return 'BookCollection(id: $id, ownerId: $ownerId, title: $title, description: $description, bookCount: $bookCount, coverBookIds: $coverBookIds, coverBooks: $coverBooks, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BookCollectionCopyWith<$Res> implements $BookCollectionCopyWith<$Res> {
  factory _$BookCollectionCopyWith(_BookCollection value, $Res Function(_BookCollection) _then) = __$BookCollectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String title, String description, int bookCount, List<String> coverBookIds, List<CollectionCoverSnapshot> coverBooks, int? createdAt, int? updatedAt
});




}
/// @nodoc
class __$BookCollectionCopyWithImpl<$Res>
    implements _$BookCollectionCopyWith<$Res> {
  __$BookCollectionCopyWithImpl(this._self, this._then);

  final _BookCollection _self;
  final $Res Function(_BookCollection) _then;

/// Create a copy of BookCollection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? title = null,Object? description = null,Object? bookCount = null,Object? coverBookIds = null,Object? coverBooks = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_BookCollection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,bookCount: null == bookCount ? _self.bookCount : bookCount // ignore: cast_nullable_to_non_nullable
as int,coverBookIds: null == coverBookIds ? _self._coverBookIds : coverBookIds // ignore: cast_nullable_to_non_nullable
as List<String>,coverBooks: null == coverBooks ? _self._coverBooks : coverBooks // ignore: cast_nullable_to_non_nullable
as List<CollectionCoverSnapshot>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
