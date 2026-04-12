// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'homepage_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomepageMetadata {

 List<UserModel> get authors; List<dynamic> get dailyTopics; Map<String, dynamic> get recommendationStats; dynamic get lastUpdated; String? get appVersion;
/// Create a copy of HomepageMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomepageMetadataCopyWith<HomepageMetadata> get copyWith => _$HomepageMetadataCopyWithImpl<HomepageMetadata>(this as HomepageMetadata, _$identity);

  /// Serializes this HomepageMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomepageMetadata&&const DeepCollectionEquality().equals(other.authors, authors)&&const DeepCollectionEquality().equals(other.dailyTopics, dailyTopics)&&const DeepCollectionEquality().equals(other.recommendationStats, recommendationStats)&&const DeepCollectionEquality().equals(other.lastUpdated, lastUpdated)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(authors),const DeepCollectionEquality().hash(dailyTopics),const DeepCollectionEquality().hash(recommendationStats),const DeepCollectionEquality().hash(lastUpdated),appVersion);

@override
String toString() {
  return 'HomepageMetadata(authors: $authors, dailyTopics: $dailyTopics, recommendationStats: $recommendationStats, lastUpdated: $lastUpdated, appVersion: $appVersion)';
}


}

/// @nodoc
abstract mixin class $HomepageMetadataCopyWith<$Res>  {
  factory $HomepageMetadataCopyWith(HomepageMetadata value, $Res Function(HomepageMetadata) _then) = _$HomepageMetadataCopyWithImpl;
@useResult
$Res call({
 List<UserModel> authors, List<dynamic> dailyTopics, Map<String, dynamic> recommendationStats, dynamic lastUpdated, String? appVersion
});




}
/// @nodoc
class _$HomepageMetadataCopyWithImpl<$Res>
    implements $HomepageMetadataCopyWith<$Res> {
  _$HomepageMetadataCopyWithImpl(this._self, this._then);

  final HomepageMetadata _self;
  final $Res Function(HomepageMetadata) _then;

/// Create a copy of HomepageMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authors = null,Object? dailyTopics = null,Object? recommendationStats = null,Object? lastUpdated = freezed,Object? appVersion = freezed,}) {
  return _then(_self.copyWith(
authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as List<UserModel>,dailyTopics: null == dailyTopics ? _self.dailyTopics : dailyTopics // ignore: cast_nullable_to_non_nullable
as List<dynamic>,recommendationStats: null == recommendationStats ? _self.recommendationStats : recommendationStats // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as dynamic,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomepageMetadata].
extension HomepageMetadataPatterns on HomepageMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomepageMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomepageMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomepageMetadata value)  $default,){
final _that = this;
switch (_that) {
case _HomepageMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomepageMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _HomepageMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserModel> authors,  List<dynamic> dailyTopics,  Map<String, dynamic> recommendationStats,  dynamic lastUpdated,  String? appVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomepageMetadata() when $default != null:
return $default(_that.authors,_that.dailyTopics,_that.recommendationStats,_that.lastUpdated,_that.appVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserModel> authors,  List<dynamic> dailyTopics,  Map<String, dynamic> recommendationStats,  dynamic lastUpdated,  String? appVersion)  $default,) {final _that = this;
switch (_that) {
case _HomepageMetadata():
return $default(_that.authors,_that.dailyTopics,_that.recommendationStats,_that.lastUpdated,_that.appVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserModel> authors,  List<dynamic> dailyTopics,  Map<String, dynamic> recommendationStats,  dynamic lastUpdated,  String? appVersion)?  $default,) {final _that = this;
switch (_that) {
case _HomepageMetadata() when $default != null:
return $default(_that.authors,_that.dailyTopics,_that.recommendationStats,_that.lastUpdated,_that.appVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomepageMetadata implements HomepageMetadata {
  const _HomepageMetadata({required final  List<UserModel> authors, required final  List<dynamic> dailyTopics, required final  Map<String, dynamic> recommendationStats, required this.lastUpdated, this.appVersion}): _authors = authors,_dailyTopics = dailyTopics,_recommendationStats = recommendationStats;
  factory _HomepageMetadata.fromJson(Map<String, dynamic> json) => _$HomepageMetadataFromJson(json);

 final  List<UserModel> _authors;
@override List<UserModel> get authors {
  if (_authors is EqualUnmodifiableListView) return _authors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authors);
}

 final  List<dynamic> _dailyTopics;
@override List<dynamic> get dailyTopics {
  if (_dailyTopics is EqualUnmodifiableListView) return _dailyTopics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyTopics);
}

 final  Map<String, dynamic> _recommendationStats;
@override Map<String, dynamic> get recommendationStats {
  if (_recommendationStats is EqualUnmodifiableMapView) return _recommendationStats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_recommendationStats);
}

@override final  dynamic lastUpdated;
@override final  String? appVersion;

/// Create a copy of HomepageMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomepageMetadataCopyWith<_HomepageMetadata> get copyWith => __$HomepageMetadataCopyWithImpl<_HomepageMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomepageMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomepageMetadata&&const DeepCollectionEquality().equals(other._authors, _authors)&&const DeepCollectionEquality().equals(other._dailyTopics, _dailyTopics)&&const DeepCollectionEquality().equals(other._recommendationStats, _recommendationStats)&&const DeepCollectionEquality().equals(other.lastUpdated, lastUpdated)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_authors),const DeepCollectionEquality().hash(_dailyTopics),const DeepCollectionEquality().hash(_recommendationStats),const DeepCollectionEquality().hash(lastUpdated),appVersion);

@override
String toString() {
  return 'HomepageMetadata(authors: $authors, dailyTopics: $dailyTopics, recommendationStats: $recommendationStats, lastUpdated: $lastUpdated, appVersion: $appVersion)';
}


}

/// @nodoc
abstract mixin class _$HomepageMetadataCopyWith<$Res> implements $HomepageMetadataCopyWith<$Res> {
  factory _$HomepageMetadataCopyWith(_HomepageMetadata value, $Res Function(_HomepageMetadata) _then) = __$HomepageMetadataCopyWithImpl;
@override @useResult
$Res call({
 List<UserModel> authors, List<dynamic> dailyTopics, Map<String, dynamic> recommendationStats, dynamic lastUpdated, String? appVersion
});




}
/// @nodoc
class __$HomepageMetadataCopyWithImpl<$Res>
    implements _$HomepageMetadataCopyWith<$Res> {
  __$HomepageMetadataCopyWithImpl(this._self, this._then);

  final _HomepageMetadata _self;
  final $Res Function(_HomepageMetadata) _then;

/// Create a copy of HomepageMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authors = null,Object? dailyTopics = null,Object? recommendationStats = null,Object? lastUpdated = freezed,Object? appVersion = freezed,}) {
  return _then(_HomepageMetadata(
authors: null == authors ? _self._authors : authors // ignore: cast_nullable_to_non_nullable
as List<UserModel>,dailyTopics: null == dailyTopics ? _self._dailyTopics : dailyTopics // ignore: cast_nullable_to_non_nullable
as List<dynamic>,recommendationStats: null == recommendationStats ? _self._recommendationStats : recommendationStats // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as dynamic,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
