// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Book {

 String get id; String get title; String? get description; String? get coverUrl; List<Author> get authors; List<String> get subjects; List<String> get languages; Map<String, String> get formats;@JsonKey(name: 'download_count') int get downloadCount;@JsonKey(name: 'media_type') String get mediaType; List<String> get bookshelves; dynamic get year;// can be int or String
 String? get source; bool? get isOriginal; String? get contentType; String? get authorId; List<Chapter>? get chapters; String? get status; int? get createdAt; int? get updatedAt; String? get identifier; int? get recommendationCount; double? get weightedScore; double? get averageRating; int? get viewCount; int? get ratingsCount; List<String>? get topics; int? get chapterCount;
/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookCopyWith<Book> get copyWith => _$BookCopyWithImpl<Book>(this as Book, _$identity);

  /// Serializes this Book to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Book&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&const DeepCollectionEquality().equals(other.authors, authors)&&const DeepCollectionEquality().equals(other.subjects, subjects)&&const DeepCollectionEquality().equals(other.languages, languages)&&const DeepCollectionEquality().equals(other.formats, formats)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&const DeepCollectionEquality().equals(other.bookshelves, bookshelves)&&const DeepCollectionEquality().equals(other.year, year)&&(identical(other.source, source) || other.source == source)&&(identical(other.isOriginal, isOriginal) || other.isOriginal == isOriginal)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.recommendationCount, recommendationCount) || other.recommendationCount == recommendationCount)&&(identical(other.weightedScore, weightedScore) || other.weightedScore == weightedScore)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.ratingsCount, ratingsCount) || other.ratingsCount == ratingsCount)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.chapterCount, chapterCount) || other.chapterCount == chapterCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,coverUrl,const DeepCollectionEquality().hash(authors),const DeepCollectionEquality().hash(subjects),const DeepCollectionEquality().hash(languages),const DeepCollectionEquality().hash(formats),downloadCount,mediaType,const DeepCollectionEquality().hash(bookshelves),const DeepCollectionEquality().hash(year),source,isOriginal,contentType,authorId,const DeepCollectionEquality().hash(chapters),status,createdAt,updatedAt,identifier,recommendationCount,weightedScore,averageRating,viewCount,ratingsCount,const DeepCollectionEquality().hash(topics),chapterCount]);

@override
String toString() {
  return 'Book(id: $id, title: $title, description: $description, coverUrl: $coverUrl, authors: $authors, subjects: $subjects, languages: $languages, formats: $formats, downloadCount: $downloadCount, mediaType: $mediaType, bookshelves: $bookshelves, year: $year, source: $source, isOriginal: $isOriginal, contentType: $contentType, authorId: $authorId, chapters: $chapters, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, identifier: $identifier, recommendationCount: $recommendationCount, weightedScore: $weightedScore, averageRating: $averageRating, viewCount: $viewCount, ratingsCount: $ratingsCount, topics: $topics, chapterCount: $chapterCount)';
}


}

/// @nodoc
abstract mixin class $BookCopyWith<$Res>  {
  factory $BookCopyWith(Book value, $Res Function(Book) _then) = _$BookCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, String? coverUrl, List<Author> authors, List<String> subjects, List<String> languages, Map<String, String> formats,@JsonKey(name: 'download_count') int downloadCount,@JsonKey(name: 'media_type') String mediaType, List<String> bookshelves, dynamic year, String? source, bool? isOriginal, String? contentType, String? authorId, List<Chapter>? chapters, String? status, int? createdAt, int? updatedAt, String? identifier, int? recommendationCount, double? weightedScore, double? averageRating, int? viewCount, int? ratingsCount, List<String>? topics, int? chapterCount
});




}
/// @nodoc
class _$BookCopyWithImpl<$Res>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._self, this._then);

  final Book _self;
  final $Res Function(Book) _then;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? coverUrl = freezed,Object? authors = null,Object? subjects = null,Object? languages = null,Object? formats = null,Object? downloadCount = null,Object? mediaType = null,Object? bookshelves = null,Object? year = freezed,Object? source = freezed,Object? isOriginal = freezed,Object? contentType = freezed,Object? authorId = freezed,Object? chapters = freezed,Object? status = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? identifier = freezed,Object? recommendationCount = freezed,Object? weightedScore = freezed,Object? averageRating = freezed,Object? viewCount = freezed,Object? ratingsCount = freezed,Object? topics = freezed,Object? chapterCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as List<Author>,subjects: null == subjects ? _self.subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,formats: null == formats ? _self.formats : formats // ignore: cast_nullable_to_non_nullable
as Map<String, String>,downloadCount: null == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,bookshelves: null == bookshelves ? _self.bookshelves : bookshelves // ignore: cast_nullable_to_non_nullable
as List<String>,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as dynamic,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,isOriginal: freezed == isOriginal ? _self.isOriginal : isOriginal // ignore: cast_nullable_to_non_nullable
as bool?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,chapters: freezed == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,identifier: freezed == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String?,recommendationCount: freezed == recommendationCount ? _self.recommendationCount : recommendationCount // ignore: cast_nullable_to_non_nullable
as int?,weightedScore: freezed == weightedScore ? _self.weightedScore : weightedScore // ignore: cast_nullable_to_non_nullable
as double?,averageRating: freezed == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,ratingsCount: freezed == ratingsCount ? _self.ratingsCount : ratingsCount // ignore: cast_nullable_to_non_nullable
as int?,topics: freezed == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>?,chapterCount: freezed == chapterCount ? _self.chapterCount : chapterCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Book].
extension BookPatterns on Book {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Book value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Book() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Book value)  $default,){
final _that = this;
switch (_that) {
case _Book():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Book value)?  $default,){
final _that = this;
switch (_that) {
case _Book() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String? coverUrl,  List<Author> authors,  List<String> subjects,  List<String> languages,  Map<String, String> formats, @JsonKey(name: 'download_count')  int downloadCount, @JsonKey(name: 'media_type')  String mediaType,  List<String> bookshelves,  dynamic year,  String? source,  bool? isOriginal,  String? contentType,  String? authorId,  List<Chapter>? chapters,  String? status,  int? createdAt,  int? updatedAt,  String? identifier,  int? recommendationCount,  double? weightedScore,  double? averageRating,  int? viewCount,  int? ratingsCount,  List<String>? topics,  int? chapterCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Book() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.coverUrl,_that.authors,_that.subjects,_that.languages,_that.formats,_that.downloadCount,_that.mediaType,_that.bookshelves,_that.year,_that.source,_that.isOriginal,_that.contentType,_that.authorId,_that.chapters,_that.status,_that.createdAt,_that.updatedAt,_that.identifier,_that.recommendationCount,_that.weightedScore,_that.averageRating,_that.viewCount,_that.ratingsCount,_that.topics,_that.chapterCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String? coverUrl,  List<Author> authors,  List<String> subjects,  List<String> languages,  Map<String, String> formats, @JsonKey(name: 'download_count')  int downloadCount, @JsonKey(name: 'media_type')  String mediaType,  List<String> bookshelves,  dynamic year,  String? source,  bool? isOriginal,  String? contentType,  String? authorId,  List<Chapter>? chapters,  String? status,  int? createdAt,  int? updatedAt,  String? identifier,  int? recommendationCount,  double? weightedScore,  double? averageRating,  int? viewCount,  int? ratingsCount,  List<String>? topics,  int? chapterCount)  $default,) {final _that = this;
switch (_that) {
case _Book():
return $default(_that.id,_that.title,_that.description,_that.coverUrl,_that.authors,_that.subjects,_that.languages,_that.formats,_that.downloadCount,_that.mediaType,_that.bookshelves,_that.year,_that.source,_that.isOriginal,_that.contentType,_that.authorId,_that.chapters,_that.status,_that.createdAt,_that.updatedAt,_that.identifier,_that.recommendationCount,_that.weightedScore,_that.averageRating,_that.viewCount,_that.ratingsCount,_that.topics,_that.chapterCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  String? coverUrl,  List<Author> authors,  List<String> subjects,  List<String> languages,  Map<String, String> formats, @JsonKey(name: 'download_count')  int downloadCount, @JsonKey(name: 'media_type')  String mediaType,  List<String> bookshelves,  dynamic year,  String? source,  bool? isOriginal,  String? contentType,  String? authorId,  List<Chapter>? chapters,  String? status,  int? createdAt,  int? updatedAt,  String? identifier,  int? recommendationCount,  double? weightedScore,  double? averageRating,  int? viewCount,  int? ratingsCount,  List<String>? topics,  int? chapterCount)?  $default,) {final _that = this;
switch (_that) {
case _Book() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.coverUrl,_that.authors,_that.subjects,_that.languages,_that.formats,_that.downloadCount,_that.mediaType,_that.bookshelves,_that.year,_that.source,_that.isOriginal,_that.contentType,_that.authorId,_that.chapters,_that.status,_that.createdAt,_that.updatedAt,_that.identifier,_that.recommendationCount,_that.weightedScore,_that.averageRating,_that.viewCount,_that.ratingsCount,_that.topics,_that.chapterCount);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Book implements Book {
  const _Book({required this.id, required this.title, this.description, this.coverUrl, required final  List<Author> authors, required final  List<String> subjects, required final  List<String> languages, required final  Map<String, String> formats, @JsonKey(name: 'download_count') required this.downloadCount, @JsonKey(name: 'media_type') required this.mediaType, required final  List<String> bookshelves, this.year, this.source, this.isOriginal, this.contentType, this.authorId, final  List<Chapter>? chapters, this.status, this.createdAt, this.updatedAt, this.identifier, this.recommendationCount, this.weightedScore, this.averageRating, this.viewCount, this.ratingsCount, final  List<String>? topics, this.chapterCount}): _authors = authors,_subjects = subjects,_languages = languages,_formats = formats,_bookshelves = bookshelves,_chapters = chapters,_topics = topics;
  factory _Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  String? coverUrl;
 final  List<Author> _authors;
@override List<Author> get authors {
  if (_authors is EqualUnmodifiableListView) return _authors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authors);
}

 final  List<String> _subjects;
@override List<String> get subjects {
  if (_subjects is EqualUnmodifiableListView) return _subjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subjects);
}

 final  List<String> _languages;
@override List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

 final  Map<String, String> _formats;
@override Map<String, String> get formats {
  if (_formats is EqualUnmodifiableMapView) return _formats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_formats);
}

@override@JsonKey(name: 'download_count') final  int downloadCount;
@override@JsonKey(name: 'media_type') final  String mediaType;
 final  List<String> _bookshelves;
@override List<String> get bookshelves {
  if (_bookshelves is EqualUnmodifiableListView) return _bookshelves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookshelves);
}

@override final  dynamic year;
// can be int or String
@override final  String? source;
@override final  bool? isOriginal;
@override final  String? contentType;
@override final  String? authorId;
 final  List<Chapter>? _chapters;
@override List<Chapter>? get chapters {
  final value = _chapters;
  if (value == null) return null;
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? status;
@override final  int? createdAt;
@override final  int? updatedAt;
@override final  String? identifier;
@override final  int? recommendationCount;
@override final  double? weightedScore;
@override final  double? averageRating;
@override final  int? viewCount;
@override final  int? ratingsCount;
 final  List<String>? _topics;
@override List<String>? get topics {
  final value = _topics;
  if (value == null) return null;
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? chapterCount;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookCopyWith<_Book> get copyWith => __$BookCopyWithImpl<_Book>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Book&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&const DeepCollectionEquality().equals(other._authors, _authors)&&const DeepCollectionEquality().equals(other._subjects, _subjects)&&const DeepCollectionEquality().equals(other._languages, _languages)&&const DeepCollectionEquality().equals(other._formats, _formats)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&const DeepCollectionEquality().equals(other._bookshelves, _bookshelves)&&const DeepCollectionEquality().equals(other.year, year)&&(identical(other.source, source) || other.source == source)&&(identical(other.isOriginal, isOriginal) || other.isOriginal == isOriginal)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.recommendationCount, recommendationCount) || other.recommendationCount == recommendationCount)&&(identical(other.weightedScore, weightedScore) || other.weightedScore == weightedScore)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.ratingsCount, ratingsCount) || other.ratingsCount == ratingsCount)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.chapterCount, chapterCount) || other.chapterCount == chapterCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,coverUrl,const DeepCollectionEquality().hash(_authors),const DeepCollectionEquality().hash(_subjects),const DeepCollectionEquality().hash(_languages),const DeepCollectionEquality().hash(_formats),downloadCount,mediaType,const DeepCollectionEquality().hash(_bookshelves),const DeepCollectionEquality().hash(year),source,isOriginal,contentType,authorId,const DeepCollectionEquality().hash(_chapters),status,createdAt,updatedAt,identifier,recommendationCount,weightedScore,averageRating,viewCount,ratingsCount,const DeepCollectionEquality().hash(_topics),chapterCount]);

@override
String toString() {
  return 'Book(id: $id, title: $title, description: $description, coverUrl: $coverUrl, authors: $authors, subjects: $subjects, languages: $languages, formats: $formats, downloadCount: $downloadCount, mediaType: $mediaType, bookshelves: $bookshelves, year: $year, source: $source, isOriginal: $isOriginal, contentType: $contentType, authorId: $authorId, chapters: $chapters, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, identifier: $identifier, recommendationCount: $recommendationCount, weightedScore: $weightedScore, averageRating: $averageRating, viewCount: $viewCount, ratingsCount: $ratingsCount, topics: $topics, chapterCount: $chapterCount)';
}


}

/// @nodoc
abstract mixin class _$BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$BookCopyWith(_Book value, $Res Function(_Book) _then) = __$BookCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, String? coverUrl, List<Author> authors, List<String> subjects, List<String> languages, Map<String, String> formats,@JsonKey(name: 'download_count') int downloadCount,@JsonKey(name: 'media_type') String mediaType, List<String> bookshelves, dynamic year, String? source, bool? isOriginal, String? contentType, String? authorId, List<Chapter>? chapters, String? status, int? createdAt, int? updatedAt, String? identifier, int? recommendationCount, double? weightedScore, double? averageRating, int? viewCount, int? ratingsCount, List<String>? topics, int? chapterCount
});




}
/// @nodoc
class __$BookCopyWithImpl<$Res>
    implements _$BookCopyWith<$Res> {
  __$BookCopyWithImpl(this._self, this._then);

  final _Book _self;
  final $Res Function(_Book) _then;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? coverUrl = freezed,Object? authors = null,Object? subjects = null,Object? languages = null,Object? formats = null,Object? downloadCount = null,Object? mediaType = null,Object? bookshelves = null,Object? year = freezed,Object? source = freezed,Object? isOriginal = freezed,Object? contentType = freezed,Object? authorId = freezed,Object? chapters = freezed,Object? status = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? identifier = freezed,Object? recommendationCount = freezed,Object? weightedScore = freezed,Object? averageRating = freezed,Object? viewCount = freezed,Object? ratingsCount = freezed,Object? topics = freezed,Object? chapterCount = freezed,}) {
  return _then(_Book(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,authors: null == authors ? _self._authors : authors // ignore: cast_nullable_to_non_nullable
as List<Author>,subjects: null == subjects ? _self._subjects : subjects // ignore: cast_nullable_to_non_nullable
as List<String>,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,formats: null == formats ? _self._formats : formats // ignore: cast_nullable_to_non_nullable
as Map<String, String>,downloadCount: null == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,bookshelves: null == bookshelves ? _self._bookshelves : bookshelves // ignore: cast_nullable_to_non_nullable
as List<String>,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as dynamic,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,isOriginal: freezed == isOriginal ? _self.isOriginal : isOriginal // ignore: cast_nullable_to_non_nullable
as bool?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,chapters: freezed == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,identifier: freezed == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String?,recommendationCount: freezed == recommendationCount ? _self.recommendationCount : recommendationCount // ignore: cast_nullable_to_non_nullable
as int?,weightedScore: freezed == weightedScore ? _self.weightedScore : weightedScore // ignore: cast_nullable_to_non_nullable
as double?,averageRating: freezed == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,ratingsCount: freezed == ratingsCount ? _self.ratingsCount : ratingsCount // ignore: cast_nullable_to_non_nullable
as int?,topics: freezed == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>?,chapterCount: freezed == chapterCount ? _self.chapterCount : chapterCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
