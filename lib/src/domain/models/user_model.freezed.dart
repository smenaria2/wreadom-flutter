// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileVisibility {

 bool? get followers; bool? get following; bool? get testimonies; bool? get feedPosts; bool? get profilePicture;
/// Create a copy of ProfileVisibility
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileVisibilityCopyWith<ProfileVisibility> get copyWith => _$ProfileVisibilityCopyWithImpl<ProfileVisibility>(this as ProfileVisibility, _$identity);

  /// Serializes this ProfileVisibility to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileVisibility&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.following, following) || other.following == following)&&(identical(other.testimonies, testimonies) || other.testimonies == testimonies)&&(identical(other.feedPosts, feedPosts) || other.feedPosts == feedPosts)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,followers,following,testimonies,feedPosts,profilePicture);

@override
String toString() {
  return 'ProfileVisibility(followers: $followers, following: $following, testimonies: $testimonies, feedPosts: $feedPosts, profilePicture: $profilePicture)';
}


}

/// @nodoc
abstract mixin class $ProfileVisibilityCopyWith<$Res>  {
  factory $ProfileVisibilityCopyWith(ProfileVisibility value, $Res Function(ProfileVisibility) _then) = _$ProfileVisibilityCopyWithImpl;
@useResult
$Res call({
 bool? followers, bool? following, bool? testimonies, bool? feedPosts, bool? profilePicture
});




}
/// @nodoc
class _$ProfileVisibilityCopyWithImpl<$Res>
    implements $ProfileVisibilityCopyWith<$Res> {
  _$ProfileVisibilityCopyWithImpl(this._self, this._then);

  final ProfileVisibility _self;
  final $Res Function(ProfileVisibility) _then;

/// Create a copy of ProfileVisibility
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? followers = freezed,Object? following = freezed,Object? testimonies = freezed,Object? feedPosts = freezed,Object? profilePicture = freezed,}) {
  return _then(_self.copyWith(
followers: freezed == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as bool?,following: freezed == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as bool?,testimonies: freezed == testimonies ? _self.testimonies : testimonies // ignore: cast_nullable_to_non_nullable
as bool?,feedPosts: freezed == feedPosts ? _self.feedPosts : feedPosts // ignore: cast_nullable_to_non_nullable
as bool?,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileVisibility].
extension ProfileVisibilityPatterns on ProfileVisibility {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileVisibility value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileVisibility() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileVisibility value)  $default,){
final _that = this;
switch (_that) {
case _ProfileVisibility():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileVisibility value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileVisibility() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? followers,  bool? following,  bool? testimonies,  bool? feedPosts,  bool? profilePicture)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileVisibility() when $default != null:
return $default(_that.followers,_that.following,_that.testimonies,_that.feedPosts,_that.profilePicture);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? followers,  bool? following,  bool? testimonies,  bool? feedPosts,  bool? profilePicture)  $default,) {final _that = this;
switch (_that) {
case _ProfileVisibility():
return $default(_that.followers,_that.following,_that.testimonies,_that.feedPosts,_that.profilePicture);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? followers,  bool? following,  bool? testimonies,  bool? feedPosts,  bool? profilePicture)?  $default,) {final _that = this;
switch (_that) {
case _ProfileVisibility() when $default != null:
return $default(_that.followers,_that.following,_that.testimonies,_that.feedPosts,_that.profilePicture);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileVisibility implements ProfileVisibility {
  const _ProfileVisibility({this.followers, this.following, this.testimonies, this.feedPosts, this.profilePicture});
  factory _ProfileVisibility.fromJson(Map<String, dynamic> json) => _$ProfileVisibilityFromJson(json);

@override final  bool? followers;
@override final  bool? following;
@override final  bool? testimonies;
@override final  bool? feedPosts;
@override final  bool? profilePicture;

/// Create a copy of ProfileVisibility
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileVisibilityCopyWith<_ProfileVisibility> get copyWith => __$ProfileVisibilityCopyWithImpl<_ProfileVisibility>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileVisibilityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileVisibility&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.following, following) || other.following == following)&&(identical(other.testimonies, testimonies) || other.testimonies == testimonies)&&(identical(other.feedPosts, feedPosts) || other.feedPosts == feedPosts)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,followers,following,testimonies,feedPosts,profilePicture);

@override
String toString() {
  return 'ProfileVisibility(followers: $followers, following: $following, testimonies: $testimonies, feedPosts: $feedPosts, profilePicture: $profilePicture)';
}


}

/// @nodoc
abstract mixin class _$ProfileVisibilityCopyWith<$Res> implements $ProfileVisibilityCopyWith<$Res> {
  factory _$ProfileVisibilityCopyWith(_ProfileVisibility value, $Res Function(_ProfileVisibility) _then) = __$ProfileVisibilityCopyWithImpl;
@override @useResult
$Res call({
 bool? followers, bool? following, bool? testimonies, bool? feedPosts, bool? profilePicture
});




}
/// @nodoc
class __$ProfileVisibilityCopyWithImpl<$Res>
    implements _$ProfileVisibilityCopyWith<$Res> {
  __$ProfileVisibilityCopyWithImpl(this._self, this._then);

  final _ProfileVisibility _self;
  final $Res Function(_ProfileVisibility) _then;

/// Create a copy of ProfileVisibility
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? followers = freezed,Object? following = freezed,Object? testimonies = freezed,Object? feedPosts = freezed,Object? profilePicture = freezed,}) {
  return _then(_ProfileVisibility(
followers: freezed == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as bool?,following: freezed == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as bool?,testimonies: freezed == testimonies ? _self.testimonies : testimonies // ignore: cast_nullable_to_non_nullable
as bool?,feedPosts: freezed == feedPosts ? _self.feedPosts : feedPosts // ignore: cast_nullable_to_non_nullable
as bool?,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$NotificationPreference {

 bool get app; bool get browser;
/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<NotificationPreference> get copyWith => _$NotificationPreferenceCopyWithImpl<NotificationPreference>(this as NotificationPreference, _$identity);

  /// Serializes this NotificationPreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreference&&(identical(other.app, app) || other.app == app)&&(identical(other.browser, browser) || other.browser == browser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,app,browser);

@override
String toString() {
  return 'NotificationPreference(app: $app, browser: $browser)';
}


}

/// @nodoc
abstract mixin class $NotificationPreferenceCopyWith<$Res>  {
  factory $NotificationPreferenceCopyWith(NotificationPreference value, $Res Function(NotificationPreference) _then) = _$NotificationPreferenceCopyWithImpl;
@useResult
$Res call({
 bool app, bool browser
});




}
/// @nodoc
class _$NotificationPreferenceCopyWithImpl<$Res>
    implements $NotificationPreferenceCopyWith<$Res> {
  _$NotificationPreferenceCopyWithImpl(this._self, this._then);

  final NotificationPreference _self;
  final $Res Function(NotificationPreference) _then;

/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? app = null,Object? browser = null,}) {
  return _then(_self.copyWith(
app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as bool,browser: null == browser ? _self.browser : browser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreference].
extension NotificationPreferencePatterns on NotificationPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreference value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreference value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool app,  bool browser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
return $default(_that.app,_that.browser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool app,  bool browser)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreference():
return $default(_that.app,_that.browser);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool app,  bool browser)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
return $default(_that.app,_that.browser);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPreference implements NotificationPreference {
  const _NotificationPreference({required this.app, required this.browser});
  factory _NotificationPreference.fromJson(Map<String, dynamic> json) => _$NotificationPreferenceFromJson(json);

@override final  bool app;
@override final  bool browser;

/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferenceCopyWith<_NotificationPreference> get copyWith => __$NotificationPreferenceCopyWithImpl<_NotificationPreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreference&&(identical(other.app, app) || other.app == app)&&(identical(other.browser, browser) || other.browser == browser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,app,browser);

@override
String toString() {
  return 'NotificationPreference(app: $app, browser: $browser)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferenceCopyWith<$Res> implements $NotificationPreferenceCopyWith<$Res> {
  factory _$NotificationPreferenceCopyWith(_NotificationPreference value, $Res Function(_NotificationPreference) _then) = __$NotificationPreferenceCopyWithImpl;
@override @useResult
$Res call({
 bool app, bool browser
});




}
/// @nodoc
class __$NotificationPreferenceCopyWithImpl<$Res>
    implements _$NotificationPreferenceCopyWith<$Res> {
  __$NotificationPreferenceCopyWithImpl(this._self, this._then);

  final _NotificationPreference _self;
  final $Res Function(_NotificationPreference) _then;

/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? app = null,Object? browser = null,}) {
  return _then(_NotificationPreference(
app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as bool,browser: null == browser ? _self.browser : browser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NotificationSettings {

 NotificationPreference get messages; NotificationPreference get groupMessages; NotificationPreference get comments; NotificationPreference get replies; NotificationPreference get followers; NotificationPreference get testimonials; NotificationPreference get likes; NotificationPreference get followedAuthorPosts; NotificationPreference get newCreations; bool get browserNotifications;
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingsCopyWith<NotificationSettings> get copyWith => _$NotificationSettingsCopyWithImpl<NotificationSettings>(this as NotificationSettings, _$identity);

  /// Serializes this NotificationSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettings&&(identical(other.messages, messages) || other.messages == messages)&&(identical(other.groupMessages, groupMessages) || other.groupMessages == groupMessages)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.replies, replies) || other.replies == replies)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.testimonials, testimonials) || other.testimonials == testimonials)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.followedAuthorPosts, followedAuthorPosts) || other.followedAuthorPosts == followedAuthorPosts)&&(identical(other.newCreations, newCreations) || other.newCreations == newCreations)&&(identical(other.browserNotifications, browserNotifications) || other.browserNotifications == browserNotifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messages,groupMessages,comments,replies,followers,testimonials,likes,followedAuthorPosts,newCreations,browserNotifications);

@override
String toString() {
  return 'NotificationSettings(messages: $messages, groupMessages: $groupMessages, comments: $comments, replies: $replies, followers: $followers, testimonials: $testimonials, likes: $likes, followedAuthorPosts: $followedAuthorPosts, newCreations: $newCreations, browserNotifications: $browserNotifications)';
}


}

/// @nodoc
abstract mixin class $NotificationSettingsCopyWith<$Res>  {
  factory $NotificationSettingsCopyWith(NotificationSettings value, $Res Function(NotificationSettings) _then) = _$NotificationSettingsCopyWithImpl;
@useResult
$Res call({
 NotificationPreference messages, NotificationPreference groupMessages, NotificationPreference comments, NotificationPreference replies, NotificationPreference followers, NotificationPreference testimonials, NotificationPreference likes, NotificationPreference followedAuthorPosts, NotificationPreference newCreations, bool browserNotifications
});


$NotificationPreferenceCopyWith<$Res> get messages;$NotificationPreferenceCopyWith<$Res> get groupMessages;$NotificationPreferenceCopyWith<$Res> get comments;$NotificationPreferenceCopyWith<$Res> get replies;$NotificationPreferenceCopyWith<$Res> get followers;$NotificationPreferenceCopyWith<$Res> get testimonials;$NotificationPreferenceCopyWith<$Res> get likes;$NotificationPreferenceCopyWith<$Res> get followedAuthorPosts;$NotificationPreferenceCopyWith<$Res> get newCreations;

}
/// @nodoc
class _$NotificationSettingsCopyWithImpl<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._self, this._then);

  final NotificationSettings _self;
  final $Res Function(NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? groupMessages = null,Object? comments = null,Object? replies = null,Object? followers = null,Object? testimonials = null,Object? likes = null,Object? followedAuthorPosts = null,Object? newCreations = null,Object? browserNotifications = null,}) {
  return _then(_self.copyWith(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as NotificationPreference,groupMessages: null == groupMessages ? _self.groupMessages : groupMessages // ignore: cast_nullable_to_non_nullable
as NotificationPreference,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as NotificationPreference,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as NotificationPreference,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as NotificationPreference,testimonials: null == testimonials ? _self.testimonials : testimonials // ignore: cast_nullable_to_non_nullable
as NotificationPreference,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as NotificationPreference,followedAuthorPosts: null == followedAuthorPosts ? _self.followedAuthorPosts : followedAuthorPosts // ignore: cast_nullable_to_non_nullable
as NotificationPreference,newCreations: null == newCreations ? _self.newCreations : newCreations // ignore: cast_nullable_to_non_nullable
as NotificationPreference,browserNotifications: null == browserNotifications ? _self.browserNotifications : browserNotifications // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get messages {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.messages, (value) {
    return _then(_self.copyWith(messages: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get groupMessages {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.groupMessages, (value) {
    return _then(_self.copyWith(groupMessages: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get comments {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get replies {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.replies, (value) {
    return _then(_self.copyWith(replies: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get followers {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.followers, (value) {
    return _then(_self.copyWith(followers: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get testimonials {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.testimonials, (value) {
    return _then(_self.copyWith(testimonials: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get likes {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.likes, (value) {
    return _then(_self.copyWith(likes: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get followedAuthorPosts {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.followedAuthorPosts, (value) {
    return _then(_self.copyWith(followedAuthorPosts: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get newCreations {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.newCreations, (value) {
    return _then(_self.copyWith(newCreations: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationSettings].
extension NotificationSettingsPatterns on NotificationSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettings value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NotificationPreference messages,  NotificationPreference groupMessages,  NotificationPreference comments,  NotificationPreference replies,  NotificationPreference followers,  NotificationPreference testimonials,  NotificationPreference likes,  NotificationPreference followedAuthorPosts,  NotificationPreference newCreations,  bool browserNotifications)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.messages,_that.groupMessages,_that.comments,_that.replies,_that.followers,_that.testimonials,_that.likes,_that.followedAuthorPosts,_that.newCreations,_that.browserNotifications);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NotificationPreference messages,  NotificationPreference groupMessages,  NotificationPreference comments,  NotificationPreference replies,  NotificationPreference followers,  NotificationPreference testimonials,  NotificationPreference likes,  NotificationPreference followedAuthorPosts,  NotificationPreference newCreations,  bool browserNotifications)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings():
return $default(_that.messages,_that.groupMessages,_that.comments,_that.replies,_that.followers,_that.testimonials,_that.likes,_that.followedAuthorPosts,_that.newCreations,_that.browserNotifications);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NotificationPreference messages,  NotificationPreference groupMessages,  NotificationPreference comments,  NotificationPreference replies,  NotificationPreference followers,  NotificationPreference testimonials,  NotificationPreference likes,  NotificationPreference followedAuthorPosts,  NotificationPreference newCreations,  bool browserNotifications)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.messages,_that.groupMessages,_that.comments,_that.replies,_that.followers,_that.testimonials,_that.likes,_that.followedAuthorPosts,_that.newCreations,_that.browserNotifications);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationSettings implements NotificationSettings {
  const _NotificationSettings({required this.messages, required this.groupMessages, required this.comments, required this.replies, required this.followers, required this.testimonials, required this.likes, required this.followedAuthorPosts, required this.newCreations, required this.browserNotifications});
  factory _NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);

@override final  NotificationPreference messages;
@override final  NotificationPreference groupMessages;
@override final  NotificationPreference comments;
@override final  NotificationPreference replies;
@override final  NotificationPreference followers;
@override final  NotificationPreference testimonials;
@override final  NotificationPreference likes;
@override final  NotificationPreference followedAuthorPosts;
@override final  NotificationPreference newCreations;
@override final  bool browserNotifications;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingsCopyWith<_NotificationSettings> get copyWith => __$NotificationSettingsCopyWithImpl<_NotificationSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettings&&(identical(other.messages, messages) || other.messages == messages)&&(identical(other.groupMessages, groupMessages) || other.groupMessages == groupMessages)&&(identical(other.comments, comments) || other.comments == comments)&&(identical(other.replies, replies) || other.replies == replies)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.testimonials, testimonials) || other.testimonials == testimonials)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.followedAuthorPosts, followedAuthorPosts) || other.followedAuthorPosts == followedAuthorPosts)&&(identical(other.newCreations, newCreations) || other.newCreations == newCreations)&&(identical(other.browserNotifications, browserNotifications) || other.browserNotifications == browserNotifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messages,groupMessages,comments,replies,followers,testimonials,likes,followedAuthorPosts,newCreations,browserNotifications);

@override
String toString() {
  return 'NotificationSettings(messages: $messages, groupMessages: $groupMessages, comments: $comments, replies: $replies, followers: $followers, testimonials: $testimonials, likes: $likes, followedAuthorPosts: $followedAuthorPosts, newCreations: $newCreations, browserNotifications: $browserNotifications)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingsCopyWith<$Res> implements $NotificationSettingsCopyWith<$Res> {
  factory _$NotificationSettingsCopyWith(_NotificationSettings value, $Res Function(_NotificationSettings) _then) = __$NotificationSettingsCopyWithImpl;
@override @useResult
$Res call({
 NotificationPreference messages, NotificationPreference groupMessages, NotificationPreference comments, NotificationPreference replies, NotificationPreference followers, NotificationPreference testimonials, NotificationPreference likes, NotificationPreference followedAuthorPosts, NotificationPreference newCreations, bool browserNotifications
});


@override $NotificationPreferenceCopyWith<$Res> get messages;@override $NotificationPreferenceCopyWith<$Res> get groupMessages;@override $NotificationPreferenceCopyWith<$Res> get comments;@override $NotificationPreferenceCopyWith<$Res> get replies;@override $NotificationPreferenceCopyWith<$Res> get followers;@override $NotificationPreferenceCopyWith<$Res> get testimonials;@override $NotificationPreferenceCopyWith<$Res> get likes;@override $NotificationPreferenceCopyWith<$Res> get followedAuthorPosts;@override $NotificationPreferenceCopyWith<$Res> get newCreations;

}
/// @nodoc
class __$NotificationSettingsCopyWithImpl<$Res>
    implements _$NotificationSettingsCopyWith<$Res> {
  __$NotificationSettingsCopyWithImpl(this._self, this._then);

  final _NotificationSettings _self;
  final $Res Function(_NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? groupMessages = null,Object? comments = null,Object? replies = null,Object? followers = null,Object? testimonials = null,Object? likes = null,Object? followedAuthorPosts = null,Object? newCreations = null,Object? browserNotifications = null,}) {
  return _then(_NotificationSettings(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as NotificationPreference,groupMessages: null == groupMessages ? _self.groupMessages : groupMessages // ignore: cast_nullable_to_non_nullable
as NotificationPreference,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as NotificationPreference,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as NotificationPreference,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as NotificationPreference,testimonials: null == testimonials ? _self.testimonials : testimonials // ignore: cast_nullable_to_non_nullable
as NotificationPreference,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as NotificationPreference,followedAuthorPosts: null == followedAuthorPosts ? _self.followedAuthorPosts : followedAuthorPosts // ignore: cast_nullable_to_non_nullable
as NotificationPreference,newCreations: null == newCreations ? _self.newCreations : newCreations // ignore: cast_nullable_to_non_nullable
as NotificationPreference,browserNotifications: null == browserNotifications ? _self.browserNotifications : browserNotifications // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get messages {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.messages, (value) {
    return _then(_self.copyWith(messages: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get groupMessages {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.groupMessages, (value) {
    return _then(_self.copyWith(groupMessages: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get comments {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get replies {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.replies, (value) {
    return _then(_self.copyWith(replies: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get followers {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.followers, (value) {
    return _then(_self.copyWith(followers: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get testimonials {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.testimonials, (value) {
    return _then(_self.copyWith(testimonials: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get likes {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.likes, (value) {
    return _then(_self.copyWith(likes: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get followedAuthorPosts {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.followedAuthorPosts, (value) {
    return _then(_self.copyWith(followedAuthorPosts: value));
  });
}/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<$Res> get newCreations {
  
  return $NotificationPreferenceCopyWith<$Res>(_self.newCreations, (value) {
    return _then(_self.copyWith(newCreations: value));
  });
}
}


/// @nodoc
mixin _$Bookmark {

 String? get id; String get userId; dynamic get bookId; double get position; String get label; int get timestamp; String? get chapterTitle; int? get chapterIndex; String? get highlightedText;
/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkCopyWith<Bookmark> get copyWith => _$BookmarkCopyWithImpl<Bookmark>(this as Bookmark, _$identity);

  /// Serializes this Bookmark to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bookmark&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.bookId, bookId)&&(identical(other.position, position) || other.position == position)&&(identical(other.label, label) || other.label == label)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.highlightedText, highlightedText) || other.highlightedText == highlightedText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,const DeepCollectionEquality().hash(bookId),position,label,timestamp,chapterTitle,chapterIndex,highlightedText);

@override
String toString() {
  return 'Bookmark(id: $id, userId: $userId, bookId: $bookId, position: $position, label: $label, timestamp: $timestamp, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, highlightedText: $highlightedText)';
}


}

/// @nodoc
abstract mixin class $BookmarkCopyWith<$Res>  {
  factory $BookmarkCopyWith(Bookmark value, $Res Function(Bookmark) _then) = _$BookmarkCopyWithImpl;
@useResult
$Res call({
 String? id, String userId, dynamic bookId, double position, String label, int timestamp, String? chapterTitle, int? chapterIndex, String? highlightedText
});




}
/// @nodoc
class _$BookmarkCopyWithImpl<$Res>
    implements $BookmarkCopyWith<$Res> {
  _$BookmarkCopyWithImpl(this._self, this._then);

  final Bookmark _self;
  final $Res Function(Bookmark) _then;

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? bookId = freezed,Object? position = null,Object? label = null,Object? timestamp = null,Object? chapterTitle = freezed,Object? chapterIndex = freezed,Object? highlightedText = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as dynamic,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterIndex: freezed == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int?,highlightedText: freezed == highlightedText ? _self.highlightedText : highlightedText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Bookmark].
extension BookmarkPatterns on Bookmark {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bookmark value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bookmark value)  $default,){
final _that = this;
switch (_that) {
case _Bookmark():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bookmark value)?  $default,){
final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String userId,  dynamic bookId,  double position,  String label,  int timestamp,  String? chapterTitle,  int? chapterIndex,  String? highlightedText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
return $default(_that.id,_that.userId,_that.bookId,_that.position,_that.label,_that.timestamp,_that.chapterTitle,_that.chapterIndex,_that.highlightedText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String userId,  dynamic bookId,  double position,  String label,  int timestamp,  String? chapterTitle,  int? chapterIndex,  String? highlightedText)  $default,) {final _that = this;
switch (_that) {
case _Bookmark():
return $default(_that.id,_that.userId,_that.bookId,_that.position,_that.label,_that.timestamp,_that.chapterTitle,_that.chapterIndex,_that.highlightedText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String userId,  dynamic bookId,  double position,  String label,  int timestamp,  String? chapterTitle,  int? chapterIndex,  String? highlightedText)?  $default,) {final _that = this;
switch (_that) {
case _Bookmark() when $default != null:
return $default(_that.id,_that.userId,_that.bookId,_that.position,_that.label,_that.timestamp,_that.chapterTitle,_that.chapterIndex,_that.highlightedText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Bookmark implements Bookmark {
  const _Bookmark({this.id, required this.userId, required this.bookId, required this.position, required this.label, required this.timestamp, this.chapterTitle, this.chapterIndex, this.highlightedText});
  factory _Bookmark.fromJson(Map<String, dynamic> json) => _$BookmarkFromJson(json);

@override final  String? id;
@override final  String userId;
@override final  dynamic bookId;
@override final  double position;
@override final  String label;
@override final  int timestamp;
@override final  String? chapterTitle;
@override final  int? chapterIndex;
@override final  String? highlightedText;

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookmarkCopyWith<_Bookmark> get copyWith => __$BookmarkCopyWithImpl<_Bookmark>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookmarkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bookmark&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.bookId, bookId)&&(identical(other.position, position) || other.position == position)&&(identical(other.label, label) || other.label == label)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.highlightedText, highlightedText) || other.highlightedText == highlightedText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,const DeepCollectionEquality().hash(bookId),position,label,timestamp,chapterTitle,chapterIndex,highlightedText);

@override
String toString() {
  return 'Bookmark(id: $id, userId: $userId, bookId: $bookId, position: $position, label: $label, timestamp: $timestamp, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, highlightedText: $highlightedText)';
}


}

/// @nodoc
abstract mixin class _$BookmarkCopyWith<$Res> implements $BookmarkCopyWith<$Res> {
  factory _$BookmarkCopyWith(_Bookmark value, $Res Function(_Bookmark) _then) = __$BookmarkCopyWithImpl;
@override @useResult
$Res call({
 String? id, String userId, dynamic bookId, double position, String label, int timestamp, String? chapterTitle, int? chapterIndex, String? highlightedText
});




}
/// @nodoc
class __$BookmarkCopyWithImpl<$Res>
    implements _$BookmarkCopyWith<$Res> {
  __$BookmarkCopyWithImpl(this._self, this._then);

  final _Bookmark _self;
  final $Res Function(_Bookmark) _then;

/// Create a copy of Bookmark
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? bookId = freezed,Object? position = null,Object? label = null,Object? timestamp = null,Object? chapterTitle = freezed,Object? chapterIndex = freezed,Object? highlightedText = freezed,}) {
  return _then(_Bookmark(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,bookId: freezed == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as dynamic,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterIndex: freezed == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int?,highlightedText: freezed == highlightedText ? _self.highlightedText : highlightedText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UserModel {

 String get id; String get username; String get email; String? get displayName; String? get photoURL; String? get bio; String? get penName; String? get privacyLevel; bool? get isDeactivated; ProfileVisibility? get profileVisibility; int? get followersCount; int? get followingCount; int? get totalPoints; int? get tier; int? get pointsLastUpdatedAt; List<dynamic> get readingHistory; List<dynamic> get savedBooks; List<Bookmark> get bookmarks; String? get preferredLanguage; List<String>? get pinnedWorks; int? get createdAt; int? get lastLogin; Map<String, dynamic>? get readingProgress; List<String>? get fcmTokens; NotificationSettings? get notificationSettings;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoURL, photoURL) || other.photoURL == photoURL)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.penName, penName) || other.penName == penName)&&(identical(other.privacyLevel, privacyLevel) || other.privacyLevel == privacyLevel)&&(identical(other.isDeactivated, isDeactivated) || other.isDeactivated == isDeactivated)&&(identical(other.profileVisibility, profileVisibility) || other.profileVisibility == profileVisibility)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.pointsLastUpdatedAt, pointsLastUpdatedAt) || other.pointsLastUpdatedAt == pointsLastUpdatedAt)&&const DeepCollectionEquality().equals(other.readingHistory, readingHistory)&&const DeepCollectionEquality().equals(other.savedBooks, savedBooks)&&const DeepCollectionEquality().equals(other.bookmarks, bookmarks)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&const DeepCollectionEquality().equals(other.pinnedWorks, pinnedWorks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastLogin, lastLogin) || other.lastLogin == lastLogin)&&const DeepCollectionEquality().equals(other.readingProgress, readingProgress)&&const DeepCollectionEquality().equals(other.fcmTokens, fcmTokens)&&(identical(other.notificationSettings, notificationSettings) || other.notificationSettings == notificationSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,username,email,displayName,photoURL,bio,penName,privacyLevel,isDeactivated,profileVisibility,followersCount,followingCount,totalPoints,tier,pointsLastUpdatedAt,const DeepCollectionEquality().hash(readingHistory),const DeepCollectionEquality().hash(savedBooks),const DeepCollectionEquality().hash(bookmarks),preferredLanguage,const DeepCollectionEquality().hash(pinnedWorks),createdAt,lastLogin,const DeepCollectionEquality().hash(readingProgress),const DeepCollectionEquality().hash(fcmTokens),notificationSettings]);

@override
String toString() {
  return 'UserModel(id: $id, username: $username, email: $email, displayName: $displayName, photoURL: $photoURL, bio: $bio, penName: $penName, privacyLevel: $privacyLevel, isDeactivated: $isDeactivated, profileVisibility: $profileVisibility, followersCount: $followersCount, followingCount: $followingCount, totalPoints: $totalPoints, tier: $tier, pointsLastUpdatedAt: $pointsLastUpdatedAt, readingHistory: $readingHistory, savedBooks: $savedBooks, bookmarks: $bookmarks, preferredLanguage: $preferredLanguage, pinnedWorks: $pinnedWorks, createdAt: $createdAt, lastLogin: $lastLogin, readingProgress: $readingProgress, fcmTokens: $fcmTokens, notificationSettings: $notificationSettings)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String id, String username, String email, String? displayName, String? photoURL, String? bio, String? penName, String? privacyLevel, bool? isDeactivated, ProfileVisibility? profileVisibility, int? followersCount, int? followingCount, int? totalPoints, int? tier, int? pointsLastUpdatedAt, List<dynamic> readingHistory, List<dynamic> savedBooks, List<Bookmark> bookmarks, String? preferredLanguage, List<String>? pinnedWorks, int? createdAt, int? lastLogin, Map<String, dynamic>? readingProgress, List<String>? fcmTokens, NotificationSettings? notificationSettings
});


$ProfileVisibilityCopyWith<$Res>? get profileVisibility;$NotificationSettingsCopyWith<$Res>? get notificationSettings;

}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? email = null,Object? displayName = freezed,Object? photoURL = freezed,Object? bio = freezed,Object? penName = freezed,Object? privacyLevel = freezed,Object? isDeactivated = freezed,Object? profileVisibility = freezed,Object? followersCount = freezed,Object? followingCount = freezed,Object? totalPoints = freezed,Object? tier = freezed,Object? pointsLastUpdatedAt = freezed,Object? readingHistory = null,Object? savedBooks = null,Object? bookmarks = null,Object? preferredLanguage = freezed,Object? pinnedWorks = freezed,Object? createdAt = freezed,Object? lastLogin = freezed,Object? readingProgress = freezed,Object? fcmTokens = freezed,Object? notificationSettings = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoURL: freezed == photoURL ? _self.photoURL : photoURL // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,privacyLevel: freezed == privacyLevel ? _self.privacyLevel : privacyLevel // ignore: cast_nullable_to_non_nullable
as String?,isDeactivated: freezed == isDeactivated ? _self.isDeactivated : isDeactivated // ignore: cast_nullable_to_non_nullable
as bool?,profileVisibility: freezed == profileVisibility ? _self.profileVisibility : profileVisibility // ignore: cast_nullable_to_non_nullable
as ProfileVisibility?,followersCount: freezed == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int?,followingCount: freezed == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int?,totalPoints: freezed == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int?,tier: freezed == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int?,pointsLastUpdatedAt: freezed == pointsLastUpdatedAt ? _self.pointsLastUpdatedAt : pointsLastUpdatedAt // ignore: cast_nullable_to_non_nullable
as int?,readingHistory: null == readingHistory ? _self.readingHistory : readingHistory // ignore: cast_nullable_to_non_nullable
as List<dynamic>,savedBooks: null == savedBooks ? _self.savedBooks : savedBooks // ignore: cast_nullable_to_non_nullable
as List<dynamic>,bookmarks: null == bookmarks ? _self.bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String?,pinnedWorks: freezed == pinnedWorks ? _self.pinnedWorks : pinnedWorks // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,lastLogin: freezed == lastLogin ? _self.lastLogin : lastLogin // ignore: cast_nullable_to_non_nullable
as int?,readingProgress: freezed == readingProgress ? _self.readingProgress : readingProgress // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,fcmTokens: freezed == fcmTokens ? _self.fcmTokens : fcmTokens // ignore: cast_nullable_to_non_nullable
as List<String>?,notificationSettings: freezed == notificationSettings ? _self.notificationSettings : notificationSettings // ignore: cast_nullable_to_non_nullable
as NotificationSettings?,
  ));
}
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileVisibilityCopyWith<$Res>? get profileVisibility {
    if (_self.profileVisibility == null) {
    return null;
  }

  return $ProfileVisibilityCopyWith<$Res>(_self.profileVisibility!, (value) {
    return _then(_self.copyWith(profileVisibility: value));
  });
}/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationSettingsCopyWith<$Res>? get notificationSettings {
    if (_self.notificationSettings == null) {
    return null;
  }

  return $NotificationSettingsCopyWith<$Res>(_self.notificationSettings!, (value) {
    return _then(_self.copyWith(notificationSettings: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username,  String email,  String? displayName,  String? photoURL,  String? bio,  String? penName,  String? privacyLevel,  bool? isDeactivated,  ProfileVisibility? profileVisibility,  int? followersCount,  int? followingCount,  int? totalPoints,  int? tier,  int? pointsLastUpdatedAt,  List<dynamic> readingHistory,  List<dynamic> savedBooks,  List<Bookmark> bookmarks,  String? preferredLanguage,  List<String>? pinnedWorks,  int? createdAt,  int? lastLogin,  Map<String, dynamic>? readingProgress,  List<String>? fcmTokens,  NotificationSettings? notificationSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.photoURL,_that.bio,_that.penName,_that.privacyLevel,_that.isDeactivated,_that.profileVisibility,_that.followersCount,_that.followingCount,_that.totalPoints,_that.tier,_that.pointsLastUpdatedAt,_that.readingHistory,_that.savedBooks,_that.bookmarks,_that.preferredLanguage,_that.pinnedWorks,_that.createdAt,_that.lastLogin,_that.readingProgress,_that.fcmTokens,_that.notificationSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username,  String email,  String? displayName,  String? photoURL,  String? bio,  String? penName,  String? privacyLevel,  bool? isDeactivated,  ProfileVisibility? profileVisibility,  int? followersCount,  int? followingCount,  int? totalPoints,  int? tier,  int? pointsLastUpdatedAt,  List<dynamic> readingHistory,  List<dynamic> savedBooks,  List<Bookmark> bookmarks,  String? preferredLanguage,  List<String>? pinnedWorks,  int? createdAt,  int? lastLogin,  Map<String, dynamic>? readingProgress,  List<String>? fcmTokens,  NotificationSettings? notificationSettings)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.photoURL,_that.bio,_that.penName,_that.privacyLevel,_that.isDeactivated,_that.profileVisibility,_that.followersCount,_that.followingCount,_that.totalPoints,_that.tier,_that.pointsLastUpdatedAt,_that.readingHistory,_that.savedBooks,_that.bookmarks,_that.preferredLanguage,_that.pinnedWorks,_that.createdAt,_that.lastLogin,_that.readingProgress,_that.fcmTokens,_that.notificationSettings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username,  String email,  String? displayName,  String? photoURL,  String? bio,  String? penName,  String? privacyLevel,  bool? isDeactivated,  ProfileVisibility? profileVisibility,  int? followersCount,  int? followingCount,  int? totalPoints,  int? tier,  int? pointsLastUpdatedAt,  List<dynamic> readingHistory,  List<dynamic> savedBooks,  List<Bookmark> bookmarks,  String? preferredLanguage,  List<String>? pinnedWorks,  int? createdAt,  int? lastLogin,  Map<String, dynamic>? readingProgress,  List<String>? fcmTokens,  NotificationSettings? notificationSettings)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.photoURL,_that.bio,_that.penName,_that.privacyLevel,_that.isDeactivated,_that.profileVisibility,_that.followersCount,_that.followingCount,_that.totalPoints,_that.tier,_that.pointsLastUpdatedAt,_that.readingHistory,_that.savedBooks,_that.bookmarks,_that.preferredLanguage,_that.pinnedWorks,_that.createdAt,_that.lastLogin,_that.readingProgress,_that.fcmTokens,_that.notificationSettings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({required this.id, required this.username, required this.email, this.displayName, this.photoURL, this.bio, this.penName, this.privacyLevel, this.isDeactivated, this.profileVisibility, this.followersCount, this.followingCount, this.totalPoints, this.tier, this.pointsLastUpdatedAt, required final  List<dynamic> readingHistory, required final  List<dynamic> savedBooks, required final  List<Bookmark> bookmarks, this.preferredLanguage, final  List<String>? pinnedWorks, this.createdAt, this.lastLogin, final  Map<String, dynamic>? readingProgress, final  List<String>? fcmTokens, this.notificationSettings}): _readingHistory = readingHistory,_savedBooks = savedBooks,_bookmarks = bookmarks,_pinnedWorks = pinnedWorks,_readingProgress = readingProgress,_fcmTokens = fcmTokens;
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String id;
@override final  String username;
@override final  String email;
@override final  String? displayName;
@override final  String? photoURL;
@override final  String? bio;
@override final  String? penName;
@override final  String? privacyLevel;
@override final  bool? isDeactivated;
@override final  ProfileVisibility? profileVisibility;
@override final  int? followersCount;
@override final  int? followingCount;
@override final  int? totalPoints;
@override final  int? tier;
@override final  int? pointsLastUpdatedAt;
 final  List<dynamic> _readingHistory;
@override List<dynamic> get readingHistory {
  if (_readingHistory is EqualUnmodifiableListView) return _readingHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readingHistory);
}

 final  List<dynamic> _savedBooks;
@override List<dynamic> get savedBooks {
  if (_savedBooks is EqualUnmodifiableListView) return _savedBooks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedBooks);
}

 final  List<Bookmark> _bookmarks;
@override List<Bookmark> get bookmarks {
  if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookmarks);
}

@override final  String? preferredLanguage;
 final  List<String>? _pinnedWorks;
@override List<String>? get pinnedWorks {
  final value = _pinnedWorks;
  if (value == null) return null;
  if (_pinnedWorks is EqualUnmodifiableListView) return _pinnedWorks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? createdAt;
@override final  int? lastLogin;
 final  Map<String, dynamic>? _readingProgress;
@override Map<String, dynamic>? get readingProgress {
  final value = _readingProgress;
  if (value == null) return null;
  if (_readingProgress is EqualUnmodifiableMapView) return _readingProgress;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _fcmTokens;
@override List<String>? get fcmTokens {
  final value = _fcmTokens;
  if (value == null) return null;
  if (_fcmTokens is EqualUnmodifiableListView) return _fcmTokens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  NotificationSettings? notificationSettings;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoURL, photoURL) || other.photoURL == photoURL)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.penName, penName) || other.penName == penName)&&(identical(other.privacyLevel, privacyLevel) || other.privacyLevel == privacyLevel)&&(identical(other.isDeactivated, isDeactivated) || other.isDeactivated == isDeactivated)&&(identical(other.profileVisibility, profileVisibility) || other.profileVisibility == profileVisibility)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.pointsLastUpdatedAt, pointsLastUpdatedAt) || other.pointsLastUpdatedAt == pointsLastUpdatedAt)&&const DeepCollectionEquality().equals(other._readingHistory, _readingHistory)&&const DeepCollectionEquality().equals(other._savedBooks, _savedBooks)&&const DeepCollectionEquality().equals(other._bookmarks, _bookmarks)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&const DeepCollectionEquality().equals(other._pinnedWorks, _pinnedWorks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastLogin, lastLogin) || other.lastLogin == lastLogin)&&const DeepCollectionEquality().equals(other._readingProgress, _readingProgress)&&const DeepCollectionEquality().equals(other._fcmTokens, _fcmTokens)&&(identical(other.notificationSettings, notificationSettings) || other.notificationSettings == notificationSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,username,email,displayName,photoURL,bio,penName,privacyLevel,isDeactivated,profileVisibility,followersCount,followingCount,totalPoints,tier,pointsLastUpdatedAt,const DeepCollectionEquality().hash(_readingHistory),const DeepCollectionEquality().hash(_savedBooks),const DeepCollectionEquality().hash(_bookmarks),preferredLanguage,const DeepCollectionEquality().hash(_pinnedWorks),createdAt,lastLogin,const DeepCollectionEquality().hash(_readingProgress),const DeepCollectionEquality().hash(_fcmTokens),notificationSettings]);

@override
String toString() {
  return 'UserModel(id: $id, username: $username, email: $email, displayName: $displayName, photoURL: $photoURL, bio: $bio, penName: $penName, privacyLevel: $privacyLevel, isDeactivated: $isDeactivated, profileVisibility: $profileVisibility, followersCount: $followersCount, followingCount: $followingCount, totalPoints: $totalPoints, tier: $tier, pointsLastUpdatedAt: $pointsLastUpdatedAt, readingHistory: $readingHistory, savedBooks: $savedBooks, bookmarks: $bookmarks, preferredLanguage: $preferredLanguage, pinnedWorks: $pinnedWorks, createdAt: $createdAt, lastLogin: $lastLogin, readingProgress: $readingProgress, fcmTokens: $fcmTokens, notificationSettings: $notificationSettings)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String username, String email, String? displayName, String? photoURL, String? bio, String? penName, String? privacyLevel, bool? isDeactivated, ProfileVisibility? profileVisibility, int? followersCount, int? followingCount, int? totalPoints, int? tier, int? pointsLastUpdatedAt, List<dynamic> readingHistory, List<dynamic> savedBooks, List<Bookmark> bookmarks, String? preferredLanguage, List<String>? pinnedWorks, int? createdAt, int? lastLogin, Map<String, dynamic>? readingProgress, List<String>? fcmTokens, NotificationSettings? notificationSettings
});


@override $ProfileVisibilityCopyWith<$Res>? get profileVisibility;@override $NotificationSettingsCopyWith<$Res>? get notificationSettings;

}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? email = null,Object? displayName = freezed,Object? photoURL = freezed,Object? bio = freezed,Object? penName = freezed,Object? privacyLevel = freezed,Object? isDeactivated = freezed,Object? profileVisibility = freezed,Object? followersCount = freezed,Object? followingCount = freezed,Object? totalPoints = freezed,Object? tier = freezed,Object? pointsLastUpdatedAt = freezed,Object? readingHistory = null,Object? savedBooks = null,Object? bookmarks = null,Object? preferredLanguage = freezed,Object? pinnedWorks = freezed,Object? createdAt = freezed,Object? lastLogin = freezed,Object? readingProgress = freezed,Object? fcmTokens = freezed,Object? notificationSettings = freezed,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,photoURL: freezed == photoURL ? _self.photoURL : photoURL // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,privacyLevel: freezed == privacyLevel ? _self.privacyLevel : privacyLevel // ignore: cast_nullable_to_non_nullable
as String?,isDeactivated: freezed == isDeactivated ? _self.isDeactivated : isDeactivated // ignore: cast_nullable_to_non_nullable
as bool?,profileVisibility: freezed == profileVisibility ? _self.profileVisibility : profileVisibility // ignore: cast_nullable_to_non_nullable
as ProfileVisibility?,followersCount: freezed == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int?,followingCount: freezed == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int?,totalPoints: freezed == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int?,tier: freezed == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int?,pointsLastUpdatedAt: freezed == pointsLastUpdatedAt ? _self.pointsLastUpdatedAt : pointsLastUpdatedAt // ignore: cast_nullable_to_non_nullable
as int?,readingHistory: null == readingHistory ? _self._readingHistory : readingHistory // ignore: cast_nullable_to_non_nullable
as List<dynamic>,savedBooks: null == savedBooks ? _self._savedBooks : savedBooks // ignore: cast_nullable_to_non_nullable
as List<dynamic>,bookmarks: null == bookmarks ? _self._bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as List<Bookmark>,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String?,pinnedWorks: freezed == pinnedWorks ? _self._pinnedWorks : pinnedWorks // ignore: cast_nullable_to_non_nullable
as List<String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,lastLogin: freezed == lastLogin ? _self.lastLogin : lastLogin // ignore: cast_nullable_to_non_nullable
as int?,readingProgress: freezed == readingProgress ? _self._readingProgress : readingProgress // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,fcmTokens: freezed == fcmTokens ? _self._fcmTokens : fcmTokens // ignore: cast_nullable_to_non_nullable
as List<String>?,notificationSettings: freezed == notificationSettings ? _self.notificationSettings : notificationSettings // ignore: cast_nullable_to_non_nullable
as NotificationSettings?,
  ));
}

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileVisibilityCopyWith<$Res>? get profileVisibility {
    if (_self.profileVisibility == null) {
    return null;
  }

  return $ProfileVisibilityCopyWith<$Res>(_self.profileVisibility!, (value) {
    return _then(_self.copyWith(profileVisibility: value));
  });
}/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationSettingsCopyWith<$Res>? get notificationSettings {
    if (_self.notificationSettings == null) {
    return null;
  }

  return $NotificationSettingsCopyWith<$Res>(_self.notificationSettings!, (value) {
    return _then(_self.copyWith(notificationSettings: value));
  });
}
}

// dart format on
