// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageStoryData {

 String get id; String get title; String? get coverUrl; String get authorNames;
/// Create a copy of MessageStoryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageStoryDataCopyWith<MessageStoryData> get copyWith => _$MessageStoryDataCopyWithImpl<MessageStoryData>(this as MessageStoryData, _$identity);

  /// Serializes this MessageStoryData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageStoryData&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.authorNames, authorNames) || other.authorNames == authorNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,coverUrl,authorNames);

@override
String toString() {
  return 'MessageStoryData(id: $id, title: $title, coverUrl: $coverUrl, authorNames: $authorNames)';
}


}

/// @nodoc
abstract mixin class $MessageStoryDataCopyWith<$Res>  {
  factory $MessageStoryDataCopyWith(MessageStoryData value, $Res Function(MessageStoryData) _then) = _$MessageStoryDataCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? coverUrl, String authorNames
});




}
/// @nodoc
class _$MessageStoryDataCopyWithImpl<$Res>
    implements $MessageStoryDataCopyWith<$Res> {
  _$MessageStoryDataCopyWithImpl(this._self, this._then);

  final MessageStoryData _self;
  final $Res Function(MessageStoryData) _then;

/// Create a copy of MessageStoryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? coverUrl = freezed,Object? authorNames = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,authorNames: null == authorNames ? _self.authorNames : authorNames // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageStoryData].
extension MessageStoryDataPatterns on MessageStoryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageStoryData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageStoryData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageStoryData value)  $default,){
final _that = this;
switch (_that) {
case _MessageStoryData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageStoryData value)?  $default,){
final _that = this;
switch (_that) {
case _MessageStoryData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? coverUrl,  String authorNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageStoryData() when $default != null:
return $default(_that.id,_that.title,_that.coverUrl,_that.authorNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? coverUrl,  String authorNames)  $default,) {final _that = this;
switch (_that) {
case _MessageStoryData():
return $default(_that.id,_that.title,_that.coverUrl,_that.authorNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? coverUrl,  String authorNames)?  $default,) {final _that = this;
switch (_that) {
case _MessageStoryData() when $default != null:
return $default(_that.id,_that.title,_that.coverUrl,_that.authorNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageStoryData implements MessageStoryData {
  const _MessageStoryData({required this.id, required this.title, this.coverUrl, required this.authorNames});
  factory _MessageStoryData.fromJson(Map<String, dynamic> json) => _$MessageStoryDataFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? coverUrl;
@override final  String authorNames;

/// Create a copy of MessageStoryData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageStoryDataCopyWith<_MessageStoryData> get copyWith => __$MessageStoryDataCopyWithImpl<_MessageStoryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageStoryDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageStoryData&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.authorNames, authorNames) || other.authorNames == authorNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,coverUrl,authorNames);

@override
String toString() {
  return 'MessageStoryData(id: $id, title: $title, coverUrl: $coverUrl, authorNames: $authorNames)';
}


}

/// @nodoc
abstract mixin class _$MessageStoryDataCopyWith<$Res> implements $MessageStoryDataCopyWith<$Res> {
  factory _$MessageStoryDataCopyWith(_MessageStoryData value, $Res Function(_MessageStoryData) _then) = __$MessageStoryDataCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? coverUrl, String authorNames
});




}
/// @nodoc
class __$MessageStoryDataCopyWithImpl<$Res>
    implements _$MessageStoryDataCopyWith<$Res> {
  __$MessageStoryDataCopyWithImpl(this._self, this._then);

  final _MessageStoryData _self;
  final $Res Function(_MessageStoryData) _then;

/// Create a copy of MessageStoryData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? coverUrl = freezed,Object? authorNames = null,}) {
  return _then(_MessageStoryData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,authorNames: null == authorNames ? _self.authorNames : authorNames // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Message {

 String? get id; String get senderId; String get senderName; String? get senderPhotoURL; String? get text; int get timestamp; String get type;// 'text' | 'story' | 'system'
 MessageStoryData? get storyData; List<String> get readBy;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderPhotoURL, senderPhotoURL) || other.senderPhotoURL == senderPhotoURL)&&(identical(other.text, text) || other.text == text)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.type, type) || other.type == type)&&(identical(other.storyData, storyData) || other.storyData == storyData)&&const DeepCollectionEquality().equals(other.readBy, readBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,senderName,senderPhotoURL,text,timestamp,type,storyData,const DeepCollectionEquality().hash(readBy));

@override
String toString() {
  return 'Message(id: $id, senderId: $senderId, senderName: $senderName, senderPhotoURL: $senderPhotoURL, text: $text, timestamp: $timestamp, type: $type, storyData: $storyData, readBy: $readBy)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String? id, String senderId, String senderName, String? senderPhotoURL, String? text, int timestamp, String type, MessageStoryData? storyData, List<String> readBy
});


$MessageStoryDataCopyWith<$Res>? get storyData;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? senderId = null,Object? senderName = null,Object? senderPhotoURL = freezed,Object? text = freezed,Object? timestamp = null,Object? type = null,Object? storyData = freezed,Object? readBy = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderPhotoURL: freezed == senderPhotoURL ? _self.senderPhotoURL : senderPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,storyData: freezed == storyData ? _self.storyData : storyData // ignore: cast_nullable_to_non_nullable
as MessageStoryData?,readBy: null == readBy ? _self.readBy : readBy // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageStoryDataCopyWith<$Res>? get storyData {
    if (_self.storyData == null) {
    return null;
  }

  return $MessageStoryDataCopyWith<$Res>(_self.storyData!, (value) {
    return _then(_self.copyWith(storyData: value));
  });
}
}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String senderId,  String senderName,  String? senderPhotoURL,  String? text,  int timestamp,  String type,  MessageStoryData? storyData,  List<String> readBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.senderId,_that.senderName,_that.senderPhotoURL,_that.text,_that.timestamp,_that.type,_that.storyData,_that.readBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String senderId,  String senderName,  String? senderPhotoURL,  String? text,  int timestamp,  String type,  MessageStoryData? storyData,  List<String> readBy)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.id,_that.senderId,_that.senderName,_that.senderPhotoURL,_that.text,_that.timestamp,_that.type,_that.storyData,_that.readBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String senderId,  String senderName,  String? senderPhotoURL,  String? text,  int timestamp,  String type,  MessageStoryData? storyData,  List<String> readBy)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.id,_that.senderId,_that.senderName,_that.senderPhotoURL,_that.text,_that.timestamp,_that.type,_that.storyData,_that.readBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message implements Message {
  const _Message({this.id, required this.senderId, required this.senderName, this.senderPhotoURL, this.text, required this.timestamp, required this.type, this.storyData, required final  List<String> readBy}): _readBy = readBy;
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String? id;
@override final  String senderId;
@override final  String senderName;
@override final  String? senderPhotoURL;
@override final  String? text;
@override final  int timestamp;
@override final  String type;
// 'text' | 'story' | 'system'
@override final  MessageStoryData? storyData;
 final  List<String> _readBy;
@override List<String> get readBy {
  if (_readBy is EqualUnmodifiableListView) return _readBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readBy);
}


/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderPhotoURL, senderPhotoURL) || other.senderPhotoURL == senderPhotoURL)&&(identical(other.text, text) || other.text == text)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.type, type) || other.type == type)&&(identical(other.storyData, storyData) || other.storyData == storyData)&&const DeepCollectionEquality().equals(other._readBy, _readBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,senderName,senderPhotoURL,text,timestamp,type,storyData,const DeepCollectionEquality().hash(_readBy));

@override
String toString() {
  return 'Message(id: $id, senderId: $senderId, senderName: $senderName, senderPhotoURL: $senderPhotoURL, text: $text, timestamp: $timestamp, type: $type, storyData: $storyData, readBy: $readBy)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String? id, String senderId, String senderName, String? senderPhotoURL, String? text, int timestamp, String type, MessageStoryData? storyData, List<String> readBy
});


@override $MessageStoryDataCopyWith<$Res>? get storyData;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? senderId = null,Object? senderName = null,Object? senderPhotoURL = freezed,Object? text = freezed,Object? timestamp = null,Object? type = null,Object? storyData = freezed,Object? readBy = null,}) {
  return _then(_Message(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderPhotoURL: freezed == senderPhotoURL ? _self.senderPhotoURL : senderPhotoURL // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,storyData: freezed == storyData ? _self.storyData : storyData // ignore: cast_nullable_to_non_nullable
as MessageStoryData?,readBy: null == readBy ? _self._readBy : readBy // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageStoryDataCopyWith<$Res>? get storyData {
    if (_self.storyData == null) {
    return null;
  }

  return $MessageStoryDataCopyWith<$Res>(_self.storyData!, (value) {
    return _then(_self.copyWith(storyData: value));
  });
}
}


/// @nodoc
mixin _$ParticipantDetail {

 String get username; String? get displayName; String? get penName; String? get photoURL;
/// Create a copy of ParticipantDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantDetailCopyWith<ParticipantDetail> get copyWith => _$ParticipantDetailCopyWithImpl<ParticipantDetail>(this as ParticipantDetail, _$identity);

  /// Serializes this ParticipantDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParticipantDetail&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&(identical(other.photoURL, photoURL) || other.photoURL == photoURL));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,displayName,penName,photoURL);

@override
String toString() {
  return 'ParticipantDetail(username: $username, displayName: $displayName, penName: $penName, photoURL: $photoURL)';
}


}

/// @nodoc
abstract mixin class $ParticipantDetailCopyWith<$Res>  {
  factory $ParticipantDetailCopyWith(ParticipantDetail value, $Res Function(ParticipantDetail) _then) = _$ParticipantDetailCopyWithImpl;
@useResult
$Res call({
 String username, String? displayName, String? penName, String? photoURL
});




}
/// @nodoc
class _$ParticipantDetailCopyWithImpl<$Res>
    implements $ParticipantDetailCopyWith<$Res> {
  _$ParticipantDetailCopyWithImpl(this._self, this._then);

  final ParticipantDetail _self;
  final $Res Function(ParticipantDetail) _then;

/// Create a copy of ParticipantDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? displayName = freezed,Object? penName = freezed,Object? photoURL = freezed,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,photoURL: freezed == photoURL ? _self.photoURL : photoURL // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParticipantDetail].
extension ParticipantDetailPatterns on ParticipantDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParticipantDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParticipantDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParticipantDetail value)  $default,){
final _that = this;
switch (_that) {
case _ParticipantDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParticipantDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ParticipantDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String? displayName,  String? penName,  String? photoURL)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParticipantDetail() when $default != null:
return $default(_that.username,_that.displayName,_that.penName,_that.photoURL);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String? displayName,  String? penName,  String? photoURL)  $default,) {final _that = this;
switch (_that) {
case _ParticipantDetail():
return $default(_that.username,_that.displayName,_that.penName,_that.photoURL);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String? displayName,  String? penName,  String? photoURL)?  $default,) {final _that = this;
switch (_that) {
case _ParticipantDetail() when $default != null:
return $default(_that.username,_that.displayName,_that.penName,_that.photoURL);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParticipantDetail implements ParticipantDetail {
  const _ParticipantDetail({required this.username, this.displayName, this.penName, this.photoURL});
  factory _ParticipantDetail.fromJson(Map<String, dynamic> json) => _$ParticipantDetailFromJson(json);

@override final  String username;
@override final  String? displayName;
@override final  String? penName;
@override final  String? photoURL;

/// Create a copy of ParticipantDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantDetailCopyWith<_ParticipantDetail> get copyWith => __$ParticipantDetailCopyWithImpl<_ParticipantDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParticipantDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParticipantDetail&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.penName, penName) || other.penName == penName)&&(identical(other.photoURL, photoURL) || other.photoURL == photoURL));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,displayName,penName,photoURL);

@override
String toString() {
  return 'ParticipantDetail(username: $username, displayName: $displayName, penName: $penName, photoURL: $photoURL)';
}


}

/// @nodoc
abstract mixin class _$ParticipantDetailCopyWith<$Res> implements $ParticipantDetailCopyWith<$Res> {
  factory _$ParticipantDetailCopyWith(_ParticipantDetail value, $Res Function(_ParticipantDetail) _then) = __$ParticipantDetailCopyWithImpl;
@override @useResult
$Res call({
 String username, String? displayName, String? penName, String? photoURL
});




}
/// @nodoc
class __$ParticipantDetailCopyWithImpl<$Res>
    implements _$ParticipantDetailCopyWith<$Res> {
  __$ParticipantDetailCopyWithImpl(this._self, this._then);

  final _ParticipantDetail _self;
  final $Res Function(_ParticipantDetail) _then;

/// Create a copy of ParticipantDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? displayName = freezed,Object? penName = freezed,Object? photoURL = freezed,}) {
  return _then(_ParticipantDetail(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,penName: freezed == penName ? _self.penName : penName // ignore: cast_nullable_to_non_nullable
as String?,photoURL: freezed == photoURL ? _self.photoURL : photoURL // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LastMessageInfo {

 String get text; String get senderId; int get timestamp; List<String> get readBy;
/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastMessageInfoCopyWith<LastMessageInfo> get copyWith => _$LastMessageInfoCopyWithImpl<LastMessageInfo>(this as LastMessageInfo, _$identity);

  /// Serializes this LastMessageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastMessageInfo&&(identical(other.text, text) || other.text == text)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.readBy, readBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,senderId,timestamp,const DeepCollectionEquality().hash(readBy));

@override
String toString() {
  return 'LastMessageInfo(text: $text, senderId: $senderId, timestamp: $timestamp, readBy: $readBy)';
}


}

/// @nodoc
abstract mixin class $LastMessageInfoCopyWith<$Res>  {
  factory $LastMessageInfoCopyWith(LastMessageInfo value, $Res Function(LastMessageInfo) _then) = _$LastMessageInfoCopyWithImpl;
@useResult
$Res call({
 String text, String senderId, int timestamp, List<String> readBy
});




}
/// @nodoc
class _$LastMessageInfoCopyWithImpl<$Res>
    implements $LastMessageInfoCopyWith<$Res> {
  _$LastMessageInfoCopyWithImpl(this._self, this._then);

  final LastMessageInfo _self;
  final $Res Function(LastMessageInfo) _then;

/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? senderId = null,Object? timestamp = null,Object? readBy = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,readBy: null == readBy ? _self.readBy : readBy // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LastMessageInfo].
extension LastMessageInfoPatterns on LastMessageInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastMessageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastMessageInfo value)  $default,){
final _that = this;
switch (_that) {
case _LastMessageInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastMessageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String senderId,  int timestamp,  List<String> readBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
return $default(_that.text,_that.senderId,_that.timestamp,_that.readBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String senderId,  int timestamp,  List<String> readBy)  $default,) {final _that = this;
switch (_that) {
case _LastMessageInfo():
return $default(_that.text,_that.senderId,_that.timestamp,_that.readBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String senderId,  int timestamp,  List<String> readBy)?  $default,) {final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
return $default(_that.text,_that.senderId,_that.timestamp,_that.readBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastMessageInfo implements LastMessageInfo {
  const _LastMessageInfo({required this.text, required this.senderId, required this.timestamp, required final  List<String> readBy}): _readBy = readBy;
  factory _LastMessageInfo.fromJson(Map<String, dynamic> json) => _$LastMessageInfoFromJson(json);

@override final  String text;
@override final  String senderId;
@override final  int timestamp;
 final  List<String> _readBy;
@override List<String> get readBy {
  if (_readBy is EqualUnmodifiableListView) return _readBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readBy);
}


/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastMessageInfoCopyWith<_LastMessageInfo> get copyWith => __$LastMessageInfoCopyWithImpl<_LastMessageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastMessageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastMessageInfo&&(identical(other.text, text) || other.text == text)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._readBy, _readBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,senderId,timestamp,const DeepCollectionEquality().hash(_readBy));

@override
String toString() {
  return 'LastMessageInfo(text: $text, senderId: $senderId, timestamp: $timestamp, readBy: $readBy)';
}


}

/// @nodoc
abstract mixin class _$LastMessageInfoCopyWith<$Res> implements $LastMessageInfoCopyWith<$Res> {
  factory _$LastMessageInfoCopyWith(_LastMessageInfo value, $Res Function(_LastMessageInfo) _then) = __$LastMessageInfoCopyWithImpl;
@override @useResult
$Res call({
 String text, String senderId, int timestamp, List<String> readBy
});




}
/// @nodoc
class __$LastMessageInfoCopyWithImpl<$Res>
    implements _$LastMessageInfoCopyWith<$Res> {
  __$LastMessageInfoCopyWithImpl(this._self, this._then);

  final _LastMessageInfo _self;
  final $Res Function(_LastMessageInfo) _then;

/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? senderId = null,Object? timestamp = null,Object? readBy = null,}) {
  return _then(_LastMessageInfo(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,readBy: null == readBy ? _self._readBy : readBy // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Conversation {

 String get id; List<String> get participants; Map<String, ParticipantDetail> get participantDetails; Map<String, String> get memberStatus;// 'pending' | 'accepted' | 'blocked'
 LastMessageInfo? get lastMessage; String get type;// 'direct' | 'group'
 String? get name; int get createdAt; int get updatedAt; String get createdBy;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.participants, participants)&&const DeepCollectionEquality().equals(other.participantDetails, participantDetails)&&const DeepCollectionEquality().equals(other.memberStatus, memberStatus)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(participants),const DeepCollectionEquality().hash(participantDetails),const DeepCollectionEquality().hash(memberStatus),lastMessage,type,name,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'Conversation(id: $id, participants: $participants, participantDetails: $participantDetails, memberStatus: $memberStatus, lastMessage: $lastMessage, type: $type, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id, List<String> participants, Map<String, ParticipantDetail> participantDetails, Map<String, String> memberStatus, LastMessageInfo? lastMessage, String type, String? name, int createdAt, int updatedAt, String createdBy
});


$LastMessageInfoCopyWith<$Res>? get lastMessage;

}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? participants = null,Object? participantDetails = null,Object? memberStatus = null,Object? lastMessage = freezed,Object? type = null,Object? name = freezed,Object? createdAt = null,Object? updatedAt = null,Object? createdBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,participantDetails: null == participantDetails ? _self.participantDetails : participantDetails // ignore: cast_nullable_to_non_nullable
as Map<String, ParticipantDetail>,memberStatus: null == memberStatus ? _self.memberStatus : memberStatus // ignore: cast_nullable_to_non_nullable
as Map<String, String>,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as LastMessageInfo?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageInfoCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $LastMessageInfoCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<String> participants,  Map<String, ParticipantDetail> participantDetails,  Map<String, String> memberStatus,  LastMessageInfo? lastMessage,  String type,  String? name,  int createdAt,  int updatedAt,  String createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.participants,_that.participantDetails,_that.memberStatus,_that.lastMessage,_that.type,_that.name,_that.createdAt,_that.updatedAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<String> participants,  Map<String, ParticipantDetail> participantDetails,  Map<String, String> memberStatus,  LastMessageInfo? lastMessage,  String type,  String? name,  int createdAt,  int updatedAt,  String createdBy)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.id,_that.participants,_that.participantDetails,_that.memberStatus,_that.lastMessage,_that.type,_that.name,_that.createdAt,_that.updatedAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<String> participants,  Map<String, ParticipantDetail> participantDetails,  Map<String, String> memberStatus,  LastMessageInfo? lastMessage,  String type,  String? name,  int createdAt,  int updatedAt,  String createdBy)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.participants,_that.participantDetails,_that.memberStatus,_that.lastMessage,_that.type,_that.name,_that.createdAt,_that.updatedAt,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation implements Conversation {
  const _Conversation({required this.id, required final  List<String> participants, required final  Map<String, ParticipantDetail> participantDetails, required final  Map<String, String> memberStatus, this.lastMessage, required this.type, this.name, required this.createdAt, required this.updatedAt, required this.createdBy}): _participants = participants,_participantDetails = participantDetails,_memberStatus = memberStatus;
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String id;
 final  List<String> _participants;
@override List<String> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

 final  Map<String, ParticipantDetail> _participantDetails;
@override Map<String, ParticipantDetail> get participantDetails {
  if (_participantDetails is EqualUnmodifiableMapView) return _participantDetails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_participantDetails);
}

 final  Map<String, String> _memberStatus;
@override Map<String, String> get memberStatus {
  if (_memberStatus is EqualUnmodifiableMapView) return _memberStatus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_memberStatus);
}

// 'pending' | 'accepted' | 'blocked'
@override final  LastMessageInfo? lastMessage;
@override final  String type;
// 'direct' | 'group'
@override final  String? name;
@override final  int createdAt;
@override final  int updatedAt;
@override final  String createdBy;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._participants, _participants)&&const DeepCollectionEquality().equals(other._participantDetails, _participantDetails)&&const DeepCollectionEquality().equals(other._memberStatus, _memberStatus)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_participants),const DeepCollectionEquality().hash(_participantDetails),const DeepCollectionEquality().hash(_memberStatus),lastMessage,type,name,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'Conversation(id: $id, participants: $participants, participantDetails: $participantDetails, memberStatus: $memberStatus, lastMessage: $lastMessage, type: $type, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id, List<String> participants, Map<String, ParticipantDetail> participantDetails, Map<String, String> memberStatus, LastMessageInfo? lastMessage, String type, String? name, int createdAt, int updatedAt, String createdBy
});


@override $LastMessageInfoCopyWith<$Res>? get lastMessage;

}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? participants = null,Object? participantDetails = null,Object? memberStatus = null,Object? lastMessage = freezed,Object? type = null,Object? name = freezed,Object? createdAt = null,Object? updatedAt = null,Object? createdBy = null,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,participantDetails: null == participantDetails ? _self._participantDetails : participantDetails // ignore: cast_nullable_to_non_nullable
as Map<String, ParticipantDetail>,memberStatus: null == memberStatus ? _self._memberStatus : memberStatus // ignore: cast_nullable_to_non_nullable
as Map<String, String>,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as LastMessageInfo?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageInfoCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $LastMessageInfoCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}

// dart format on
