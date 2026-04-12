// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PointsHistoryItem _$PointsHistoryItemFromJson(Map<String, dynamic> json) =>
    _PointsHistoryItem(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      type: json['type'] as String,
      points: (json['points'] as num).toInt(),
      actionType: json['actionType'] as String,
      description: json['description'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      targetId: json['targetId'] as String?,
    );

Map<String, dynamic> _$PointsHistoryItemToJson(_PointsHistoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'points': instance.points,
      'actionType': instance.actionType,
      'description': instance.description,
      'timestamp': instance.timestamp,
      'targetId': instance.targetId,
    };
