import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

@freezed
abstract class Report with _$Report {
  const factory Report({
    String? id,
    required String reporterId,
    required String targetId,
    required String targetType, // 'book', 'comment', 'post', 'user'
    required String reason,
    String? details,
    required int timestamp,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
}
