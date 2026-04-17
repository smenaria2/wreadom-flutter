// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Report _$ReportFromJson(Map<String, dynamic> json) => _Report(
  id: json['id'] as String?,
  reporterId: json['reporterId'] as String,
  targetId: json['targetId'] as String,
  targetType: json['targetType'] as String,
  reason: json['reason'] as String,
  details: json['details'] as String?,
  timestamp: (json['timestamp'] as num).toInt(),
);

Map<String, dynamic> _$ReportToJson(_Report instance) => <String, dynamic>{
  'id': instance.id,
  'reporterId': instance.reporterId,
  'targetId': instance.targetId,
  'targetType': instance.targetType,
  'reason': instance.reason,
  'details': instance.details,
  'timestamp': instance.timestamp,
};
