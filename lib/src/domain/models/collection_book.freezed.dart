// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CollectionBook {

 String get bookId; int get position; int? get addedAt;
/// Create a copy of CollectionBook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionBookCopyWith<CollectionBook> get copyWith => _$CollectionBookCopyWithImpl<CollectionBook>(this as CollectionBook, _$identity);

  /// Serializes this CollectionBook to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionBook&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.position, position) || other.position == position)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookId,position,addedAt);

@override
String toString() {
  return 'CollectionBook(bookId: $bookId, position: $position, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $CollectionBookCopyWith<$Res>  {
  factory $CollectionBookCopyWith(CollectionBook value, $Res Function(CollectionBook) _then) = _$CollectionBookCopyWithImpl;
@useResult
$Res call({
 String bookId, int position, int? addedAt
});




}
/// @nodoc
class _$CollectionBookCopyWithImpl<$Res>
    implements $CollectionBookCopyWith<$Res> {
  _$CollectionBookCopyWithImpl(this._self, this._then);

  final CollectionBook _self;
  final $Res Function(CollectionBook) _then;

/// Create a copy of CollectionBook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookId = null,Object? position = null,Object? addedAt = freezed,}) {
  return _then(_self.copyWith(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionBook].
extension CollectionBookPatterns on CollectionBook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionBook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionBook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionBook value)  $default,){
final _that = this;
switch (_that) {
case _CollectionBook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionBook value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionBook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bookId,  int position,  int? addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionBook() when $default != null:
return $default(_that.bookId,_that.position,_that.addedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bookId,  int position,  int? addedAt)  $default,) {final _that = this;
switch (_that) {
case _CollectionBook():
return $default(_that.bookId,_that.position,_that.addedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bookId,  int position,  int? addedAt)?  $default,) {final _that = this;
switch (_that) {
case _CollectionBook() when $default != null:
return $default(_that.bookId,_that.position,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionBook implements CollectionBook {
  const _CollectionBook({required this.bookId, this.position = 0, this.addedAt});
  factory _CollectionBook.fromJson(Map<String, dynamic> json) => _$CollectionBookFromJson(json);

@override final  String bookId;
@override@JsonKey() final  int position;
@override final  int? addedAt;

/// Create a copy of CollectionBook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionBookCopyWith<_CollectionBook> get copyWith => __$CollectionBookCopyWithImpl<_CollectionBook>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionBookToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionBook&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.position, position) || other.position == position)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookId,position,addedAt);

@override
String toString() {
  return 'CollectionBook(bookId: $bookId, position: $position, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$CollectionBookCopyWith<$Res> implements $CollectionBookCopyWith<$Res> {
  factory _$CollectionBookCopyWith(_CollectionBook value, $Res Function(_CollectionBook) _then) = __$CollectionBookCopyWithImpl;
@override @useResult
$Res call({
 String bookId, int position, int? addedAt
});




}
/// @nodoc
class __$CollectionBookCopyWithImpl<$Res>
    implements _$CollectionBookCopyWith<$Res> {
  __$CollectionBookCopyWithImpl(this._self, this._then);

  final _CollectionBook _self;
  final $Res Function(_CollectionBook) _then;

/// Create a copy of CollectionBook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookId = null,Object? position = null,Object? addedAt = freezed,}) {
  return _then(_CollectionBook(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
