// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'points_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PointsHistoryItem {

 String? get id; String get userId; String get type;// 'earn' | 'deduct'
 int get points; String get actionType; String get description; int get timestamp; String? get targetId;
/// Create a copy of PointsHistoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointsHistoryItemCopyWith<PointsHistoryItem> get copyWith => _$PointsHistoryItemCopyWithImpl<PointsHistoryItem>(this as PointsHistoryItem, _$identity);

  /// Serializes this PointsHistoryItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointsHistoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.points, points) || other.points == points)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.description, description) || other.description == description)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.targetId, targetId) || other.targetId == targetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,type,points,actionType,description,timestamp,targetId);

@override
String toString() {
  return 'PointsHistoryItem(id: $id, userId: $userId, type: $type, points: $points, actionType: $actionType, description: $description, timestamp: $timestamp, targetId: $targetId)';
}


}

/// @nodoc
abstract mixin class $PointsHistoryItemCopyWith<$Res>  {
  factory $PointsHistoryItemCopyWith(PointsHistoryItem value, $Res Function(PointsHistoryItem) _then) = _$PointsHistoryItemCopyWithImpl;
@useResult
$Res call({
 String? id, String userId, String type, int points, String actionType, String description, int timestamp, String? targetId
});




}
/// @nodoc
class _$PointsHistoryItemCopyWithImpl<$Res>
    implements $PointsHistoryItemCopyWith<$Res> {
  _$PointsHistoryItemCopyWithImpl(this._self, this._then);

  final PointsHistoryItem _self;
  final $Res Function(PointsHistoryItem) _then;

/// Create a copy of PointsHistoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? type = null,Object? points = null,Object? actionType = null,Object? description = null,Object? timestamp = null,Object? targetId = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PointsHistoryItem].
extension PointsHistoryItemPatterns on PointsHistoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PointsHistoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PointsHistoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PointsHistoryItem value)  $default,){
final _that = this;
switch (_that) {
case _PointsHistoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PointsHistoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _PointsHistoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String userId,  String type,  int points,  String actionType,  String description,  int timestamp,  String? targetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PointsHistoryItem() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.points,_that.actionType,_that.description,_that.timestamp,_that.targetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String userId,  String type,  int points,  String actionType,  String description,  int timestamp,  String? targetId)  $default,) {final _that = this;
switch (_that) {
case _PointsHistoryItem():
return $default(_that.id,_that.userId,_that.type,_that.points,_that.actionType,_that.description,_that.timestamp,_that.targetId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String userId,  String type,  int points,  String actionType,  String description,  int timestamp,  String? targetId)?  $default,) {final _that = this;
switch (_that) {
case _PointsHistoryItem() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.points,_that.actionType,_that.description,_that.timestamp,_that.targetId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PointsHistoryItem implements PointsHistoryItem {
  const _PointsHistoryItem({this.id, required this.userId, required this.type, required this.points, required this.actionType, required this.description, required this.timestamp, this.targetId});
  factory _PointsHistoryItem.fromJson(Map<String, dynamic> json) => _$PointsHistoryItemFromJson(json);

@override final  String? id;
@override final  String userId;
@override final  String type;
// 'earn' | 'deduct'
@override final  int points;
@override final  String actionType;
@override final  String description;
@override final  int timestamp;
@override final  String? targetId;

/// Create a copy of PointsHistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointsHistoryItemCopyWith<_PointsHistoryItem> get copyWith => __$PointsHistoryItemCopyWithImpl<_PointsHistoryItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointsHistoryItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PointsHistoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.points, points) || other.points == points)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.description, description) || other.description == description)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.targetId, targetId) || other.targetId == targetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,type,points,actionType,description,timestamp,targetId);

@override
String toString() {
  return 'PointsHistoryItem(id: $id, userId: $userId, type: $type, points: $points, actionType: $actionType, description: $description, timestamp: $timestamp, targetId: $targetId)';
}


}

/// @nodoc
abstract mixin class _$PointsHistoryItemCopyWith<$Res> implements $PointsHistoryItemCopyWith<$Res> {
  factory _$PointsHistoryItemCopyWith(_PointsHistoryItem value, $Res Function(_PointsHistoryItem) _then) = __$PointsHistoryItemCopyWithImpl;
@override @useResult
$Res call({
 String? id, String userId, String type, int points, String actionType, String description, int timestamp, String? targetId
});




}
/// @nodoc
class __$PointsHistoryItemCopyWithImpl<$Res>
    implements _$PointsHistoryItemCopyWith<$Res> {
  __$PointsHistoryItemCopyWithImpl(this._self, this._then);

  final _PointsHistoryItem _self;
  final $Res Function(_PointsHistoryItem) _then;

/// Create a copy of PointsHistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? type = null,Object? points = null,Object? actionType = null,Object? description = null,Object? timestamp = null,Object? targetId = freezed,}) {
  return _then(_PointsHistoryItem(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
