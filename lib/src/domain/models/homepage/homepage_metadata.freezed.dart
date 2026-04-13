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

 Map<String, BookRecommendationStats> get recommendationStats; List<DailyTopic> get dailyTopics;
/// Create a copy of HomepageMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomepageMetadataCopyWith<HomepageMetadata> get copyWith => _$HomepageMetadataCopyWithImpl<HomepageMetadata>(this as HomepageMetadata, _$identity);

  /// Serializes this HomepageMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomepageMetadata&&const DeepCollectionEquality().equals(other.recommendationStats, recommendationStats)&&const DeepCollectionEquality().equals(other.dailyTopics, dailyTopics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(recommendationStats),const DeepCollectionEquality().hash(dailyTopics));

@override
String toString() {
  return 'HomepageMetadata(recommendationStats: $recommendationStats, dailyTopics: $dailyTopics)';
}


}

/// @nodoc
abstract mixin class $HomepageMetadataCopyWith<$Res>  {
  factory $HomepageMetadataCopyWith(HomepageMetadata value, $Res Function(HomepageMetadata) _then) = _$HomepageMetadataCopyWithImpl;
@useResult
$Res call({
 Map<String, BookRecommendationStats> recommendationStats, List<DailyTopic> dailyTopics
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
@pragma('vm:prefer-inline') @override $Res call({Object? recommendationStats = null,Object? dailyTopics = null,}) {
  return _then(_self.copyWith(
recommendationStats: null == recommendationStats ? _self.recommendationStats : recommendationStats // ignore: cast_nullable_to_non_nullable
as Map<String, BookRecommendationStats>,dailyTopics: null == dailyTopics ? _self.dailyTopics : dailyTopics // ignore: cast_nullable_to_non_nullable
as List<DailyTopic>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, BookRecommendationStats> recommendationStats,  List<DailyTopic> dailyTopics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomepageMetadata() when $default != null:
return $default(_that.recommendationStats,_that.dailyTopics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, BookRecommendationStats> recommendationStats,  List<DailyTopic> dailyTopics)  $default,) {final _that = this;
switch (_that) {
case _HomepageMetadata():
return $default(_that.recommendationStats,_that.dailyTopics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, BookRecommendationStats> recommendationStats,  List<DailyTopic> dailyTopics)?  $default,) {final _that = this;
switch (_that) {
case _HomepageMetadata() when $default != null:
return $default(_that.recommendationStats,_that.dailyTopics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomepageMetadata implements HomepageMetadata {
  const _HomepageMetadata({final  Map<String, BookRecommendationStats> recommendationStats = const {}, final  List<DailyTopic> dailyTopics = const []}): _recommendationStats = recommendationStats,_dailyTopics = dailyTopics;
  factory _HomepageMetadata.fromJson(Map<String, dynamic> json) => _$HomepageMetadataFromJson(json);

 final  Map<String, BookRecommendationStats> _recommendationStats;
@override@JsonKey() Map<String, BookRecommendationStats> get recommendationStats {
  if (_recommendationStats is EqualUnmodifiableMapView) return _recommendationStats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_recommendationStats);
}

 final  List<DailyTopic> _dailyTopics;
@override@JsonKey() List<DailyTopic> get dailyTopics {
  if (_dailyTopics is EqualUnmodifiableListView) return _dailyTopics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyTopics);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomepageMetadata&&const DeepCollectionEquality().equals(other._recommendationStats, _recommendationStats)&&const DeepCollectionEquality().equals(other._dailyTopics, _dailyTopics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recommendationStats),const DeepCollectionEquality().hash(_dailyTopics));

@override
String toString() {
  return 'HomepageMetadata(recommendationStats: $recommendationStats, dailyTopics: $dailyTopics)';
}


}

/// @nodoc
abstract mixin class _$HomepageMetadataCopyWith<$Res> implements $HomepageMetadataCopyWith<$Res> {
  factory _$HomepageMetadataCopyWith(_HomepageMetadata value, $Res Function(_HomepageMetadata) _then) = __$HomepageMetadataCopyWithImpl;
@override @useResult
$Res call({
 Map<String, BookRecommendationStats> recommendationStats, List<DailyTopic> dailyTopics
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
@override @pragma('vm:prefer-inline') $Res call({Object? recommendationStats = null,Object? dailyTopics = null,}) {
  return _then(_HomepageMetadata(
recommendationStats: null == recommendationStats ? _self._recommendationStats : recommendationStats // ignore: cast_nullable_to_non_nullable
as Map<String, BookRecommendationStats>,dailyTopics: null == dailyTopics ? _self._dailyTopics : dailyTopics // ignore: cast_nullable_to_non_nullable
as List<DailyTopic>,
  ));
}


}


/// @nodoc
mixin _$BookRecommendationStats {

 int get downvotes; int get recommendationCount; int get upvotes; int get viewCount;
/// Create a copy of BookRecommendationStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookRecommendationStatsCopyWith<BookRecommendationStats> get copyWith => _$BookRecommendationStatsCopyWithImpl<BookRecommendationStats>(this as BookRecommendationStats, _$identity);

  /// Serializes this BookRecommendationStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookRecommendationStats&&(identical(other.downvotes, downvotes) || other.downvotes == downvotes)&&(identical(other.recommendationCount, recommendationCount) || other.recommendationCount == recommendationCount)&&(identical(other.upvotes, upvotes) || other.upvotes == upvotes)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,downvotes,recommendationCount,upvotes,viewCount);

@override
String toString() {
  return 'BookRecommendationStats(downvotes: $downvotes, recommendationCount: $recommendationCount, upvotes: $upvotes, viewCount: $viewCount)';
}


}

/// @nodoc
abstract mixin class $BookRecommendationStatsCopyWith<$Res>  {
  factory $BookRecommendationStatsCopyWith(BookRecommendationStats value, $Res Function(BookRecommendationStats) _then) = _$BookRecommendationStatsCopyWithImpl;
@useResult
$Res call({
 int downvotes, int recommendationCount, int upvotes, int viewCount
});




}
/// @nodoc
class _$BookRecommendationStatsCopyWithImpl<$Res>
    implements $BookRecommendationStatsCopyWith<$Res> {
  _$BookRecommendationStatsCopyWithImpl(this._self, this._then);

  final BookRecommendationStats _self;
  final $Res Function(BookRecommendationStats) _then;

/// Create a copy of BookRecommendationStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? downvotes = null,Object? recommendationCount = null,Object? upvotes = null,Object? viewCount = null,}) {
  return _then(_self.copyWith(
downvotes: null == downvotes ? _self.downvotes : downvotes // ignore: cast_nullable_to_non_nullable
as int,recommendationCount: null == recommendationCount ? _self.recommendationCount : recommendationCount // ignore: cast_nullable_to_non_nullable
as int,upvotes: null == upvotes ? _self.upvotes : upvotes // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BookRecommendationStats].
extension BookRecommendationStatsPatterns on BookRecommendationStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookRecommendationStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookRecommendationStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookRecommendationStats value)  $default,){
final _that = this;
switch (_that) {
case _BookRecommendationStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookRecommendationStats value)?  $default,){
final _that = this;
switch (_that) {
case _BookRecommendationStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int downvotes,  int recommendationCount,  int upvotes,  int viewCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookRecommendationStats() when $default != null:
return $default(_that.downvotes,_that.recommendationCount,_that.upvotes,_that.viewCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int downvotes,  int recommendationCount,  int upvotes,  int viewCount)  $default,) {final _that = this;
switch (_that) {
case _BookRecommendationStats():
return $default(_that.downvotes,_that.recommendationCount,_that.upvotes,_that.viewCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int downvotes,  int recommendationCount,  int upvotes,  int viewCount)?  $default,) {final _that = this;
switch (_that) {
case _BookRecommendationStats() when $default != null:
return $default(_that.downvotes,_that.recommendationCount,_that.upvotes,_that.viewCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookRecommendationStats implements BookRecommendationStats {
  const _BookRecommendationStats({this.downvotes = 0, this.recommendationCount = 0, this.upvotes = 0, this.viewCount = 0});
  factory _BookRecommendationStats.fromJson(Map<String, dynamic> json) => _$BookRecommendationStatsFromJson(json);

@override@JsonKey() final  int downvotes;
@override@JsonKey() final  int recommendationCount;
@override@JsonKey() final  int upvotes;
@override@JsonKey() final  int viewCount;

/// Create a copy of BookRecommendationStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookRecommendationStatsCopyWith<_BookRecommendationStats> get copyWith => __$BookRecommendationStatsCopyWithImpl<_BookRecommendationStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookRecommendationStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookRecommendationStats&&(identical(other.downvotes, downvotes) || other.downvotes == downvotes)&&(identical(other.recommendationCount, recommendationCount) || other.recommendationCount == recommendationCount)&&(identical(other.upvotes, upvotes) || other.upvotes == upvotes)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,downvotes,recommendationCount,upvotes,viewCount);

@override
String toString() {
  return 'BookRecommendationStats(downvotes: $downvotes, recommendationCount: $recommendationCount, upvotes: $upvotes, viewCount: $viewCount)';
}


}

/// @nodoc
abstract mixin class _$BookRecommendationStatsCopyWith<$Res> implements $BookRecommendationStatsCopyWith<$Res> {
  factory _$BookRecommendationStatsCopyWith(_BookRecommendationStats value, $Res Function(_BookRecommendationStats) _then) = __$BookRecommendationStatsCopyWithImpl;
@override @useResult
$Res call({
 int downvotes, int recommendationCount, int upvotes, int viewCount
});




}
/// @nodoc
class __$BookRecommendationStatsCopyWithImpl<$Res>
    implements _$BookRecommendationStatsCopyWith<$Res> {
  __$BookRecommendationStatsCopyWithImpl(this._self, this._then);

  final _BookRecommendationStats _self;
  final $Res Function(_BookRecommendationStats) _then;

/// Create a copy of BookRecommendationStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? downvotes = null,Object? recommendationCount = null,Object? upvotes = null,Object? viewCount = null,}) {
  return _then(_BookRecommendationStats(
downvotes: null == downvotes ? _self.downvotes : downvotes // ignore: cast_nullable_to_non_nullable
as int,recommendationCount: null == recommendationCount ? _self.recommendationCount : recommendationCount // ignore: cast_nullable_to_non_nullable
as int,upvotes: null == upvotes ? _self.upvotes : upvotes // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DailyTopic {

 String get id; String get topicName; String get description; String get fullDescription; String get coverImageUrl; bool get isEnabled;
/// Create a copy of DailyTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyTopicCopyWith<DailyTopic> get copyWith => _$DailyTopicCopyWithImpl<DailyTopic>(this as DailyTopic, _$identity);

  /// Serializes this DailyTopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.topicName, topicName) || other.topicName == topicName)&&(identical(other.description, description) || other.description == description)&&(identical(other.fullDescription, fullDescription) || other.fullDescription == fullDescription)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,topicName,description,fullDescription,coverImageUrl,isEnabled);

@override
String toString() {
  return 'DailyTopic(id: $id, topicName: $topicName, description: $description, fullDescription: $fullDescription, coverImageUrl: $coverImageUrl, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $DailyTopicCopyWith<$Res>  {
  factory $DailyTopicCopyWith(DailyTopic value, $Res Function(DailyTopic) _then) = _$DailyTopicCopyWithImpl;
@useResult
$Res call({
 String id, String topicName, String description, String fullDescription, String coverImageUrl, bool isEnabled
});




}
/// @nodoc
class _$DailyTopicCopyWithImpl<$Res>
    implements $DailyTopicCopyWith<$Res> {
  _$DailyTopicCopyWithImpl(this._self, this._then);

  final DailyTopic _self;
  final $Res Function(DailyTopic) _then;

/// Create a copy of DailyTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? topicName = null,Object? description = null,Object? fullDescription = null,Object? coverImageUrl = null,Object? isEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topicName: null == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fullDescription: null == fullDescription ? _self.fullDescription : fullDescription // ignore: cast_nullable_to_non_nullable
as String,coverImageUrl: null == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyTopic].
extension DailyTopicPatterns on DailyTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyTopic value)  $default,){
final _that = this;
switch (_that) {
case _DailyTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyTopic value)?  $default,){
final _that = this;
switch (_that) {
case _DailyTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String topicName,  String description,  String fullDescription,  String coverImageUrl,  bool isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyTopic() when $default != null:
return $default(_that.id,_that.topicName,_that.description,_that.fullDescription,_that.coverImageUrl,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String topicName,  String description,  String fullDescription,  String coverImageUrl,  bool isEnabled)  $default,) {final _that = this;
switch (_that) {
case _DailyTopic():
return $default(_that.id,_that.topicName,_that.description,_that.fullDescription,_that.coverImageUrl,_that.isEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String topicName,  String description,  String fullDescription,  String coverImageUrl,  bool isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _DailyTopic() when $default != null:
return $default(_that.id,_that.topicName,_that.description,_that.fullDescription,_that.coverImageUrl,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyTopic implements DailyTopic {
  const _DailyTopic({this.id = '', this.topicName = '', this.description = '', this.fullDescription = '', this.coverImageUrl = '', this.isEnabled = true});
  factory _DailyTopic.fromJson(Map<String, dynamic> json) => _$DailyTopicFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String topicName;
@override@JsonKey() final  String description;
@override@JsonKey() final  String fullDescription;
@override@JsonKey() final  String coverImageUrl;
@override@JsonKey() final  bool isEnabled;

/// Create a copy of DailyTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyTopicCopyWith<_DailyTopic> get copyWith => __$DailyTopicCopyWithImpl<_DailyTopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyTopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.topicName, topicName) || other.topicName == topicName)&&(identical(other.description, description) || other.description == description)&&(identical(other.fullDescription, fullDescription) || other.fullDescription == fullDescription)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,topicName,description,fullDescription,coverImageUrl,isEnabled);

@override
String toString() {
  return 'DailyTopic(id: $id, topicName: $topicName, description: $description, fullDescription: $fullDescription, coverImageUrl: $coverImageUrl, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$DailyTopicCopyWith<$Res> implements $DailyTopicCopyWith<$Res> {
  factory _$DailyTopicCopyWith(_DailyTopic value, $Res Function(_DailyTopic) _then) = __$DailyTopicCopyWithImpl;
@override @useResult
$Res call({
 String id, String topicName, String description, String fullDescription, String coverImageUrl, bool isEnabled
});




}
/// @nodoc
class __$DailyTopicCopyWithImpl<$Res>
    implements _$DailyTopicCopyWith<$Res> {
  __$DailyTopicCopyWithImpl(this._self, this._then);

  final _DailyTopic _self;
  final $Res Function(_DailyTopic) _then;

/// Create a copy of DailyTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? topicName = null,Object? description = null,Object? fullDescription = null,Object? coverImageUrl = null,Object? isEnabled = null,}) {
  return _then(_DailyTopic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topicName: null == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,fullDescription: null == fullDescription ? _self.fullDescription : fullDescription // ignore: cast_nullable_to_non_nullable
as String,coverImageUrl: null == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
