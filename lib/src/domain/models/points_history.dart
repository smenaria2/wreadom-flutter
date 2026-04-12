import 'package:freezed_annotation/freezed_annotation.dart';

part 'points_history.freezed.dart';
part 'points_history.g.dart';

@freezed
abstract class PointsHistoryItem with _$PointsHistoryItem {
  const factory PointsHistoryItem({
    String? id,
    required String userId,
    required String type, // 'earn' | 'deduct'
    required int points,
    required String actionType,
    required String description,
    required int timestamp,
    String? targetId,
  }) = _PointsHistoryItem;

  factory PointsHistoryItem.fromJson(Map<String, dynamic> json) => _$PointsHistoryItemFromJson(json);
}
