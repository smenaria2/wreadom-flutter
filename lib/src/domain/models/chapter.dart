import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter.freezed.dart';
part 'chapter.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
abstract class ChapterVersion with _$ChapterVersion {
  const factory ChapterVersion({
    required String content,
    required int timestamp,
    required int wordCount,
  }) = _ChapterVersion;

  factory ChapterVersion.fromJson(Map<String, dynamic> json) => _$ChapterVersionFromJson(json);
}

@freezed
@JsonSerializable(explicitToJson: true)
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String title,
    required String content,
    required int index,
    String? status,
    List<ChapterVersion>? versions,
    int? lastSavedAt,
    bool? isTitleLocked,
    String? originalBookId,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);
}
