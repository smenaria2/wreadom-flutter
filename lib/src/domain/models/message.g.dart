// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageStoryData _$MessageStoryDataFromJson(Map<String, dynamic> json) =>
    _MessageStoryData(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String?,
      authorNames: json['authorNames'] as String,
    );

Map<String, dynamic> _$MessageStoryDataToJson(_MessageStoryData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'coverUrl': instance.coverUrl,
      'authorNames': instance.authorNames,
    };

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String?,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  senderPhotoURL: json['senderPhotoURL'] as String?,
  text: json['text'] as String?,
  timestamp: (json['timestamp'] as num).toInt(),
  type: json['type'] as String,
  storyData: json['storyData'] == null
      ? null
      : MessageStoryData.fromJson(json['storyData'] as Map<String, dynamic>),
  readBy: (json['readBy'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'senderName': instance.senderName,
  'senderPhotoURL': instance.senderPhotoURL,
  'text': instance.text,
  'timestamp': instance.timestamp,
  'type': instance.type,
  'storyData': instance.storyData,
  'readBy': instance.readBy,
};

_ParticipantDetail _$ParticipantDetailFromJson(Map<String, dynamic> json) =>
    _ParticipantDetail(
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      penName: json['penName'] as String?,
      photoURL: json['photoURL'] as String?,
    );

Map<String, dynamic> _$ParticipantDetailToJson(_ParticipantDetail instance) =>
    <String, dynamic>{
      'username': instance.username,
      'displayName': instance.displayName,
      'penName': instance.penName,
      'photoURL': instance.photoURL,
    };

_LastMessageInfo _$LastMessageInfoFromJson(Map<String, dynamic> json) =>
    _LastMessageInfo(
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      readBy: (json['readBy'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$LastMessageInfoToJson(_LastMessageInfo instance) =>
    <String, dynamic>{
      'text': instance.text,
      'senderId': instance.senderId,
      'timestamp': instance.timestamp,
      'readBy': instance.readBy,
    };

_Conversation _$ConversationFromJson(
  Map<String, dynamic> json,
) => _Conversation(
  id: json['id'] as String,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  participantDetails: (json['participantDetails'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, ParticipantDetail.fromJson(e as Map<String, dynamic>)),
  ),
  memberStatus: Map<String, String>.from(json['memberStatus'] as Map),
  lastMessage: json['lastMessage'] == null
      ? null
      : LastMessageInfo.fromJson(json['lastMessage'] as Map<String, dynamic>),
  type: json['type'] as String,
  name: json['name'] as String?,
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num).toInt(),
  createdBy: json['createdBy'] as String,
);

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'participantDetails': instance.participantDetails,
      'memberStatus': instance.memberStatus,
      'lastMessage': instance.lastMessage,
      'type': instance.type,
      'name': instance.name,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'createdBy': instance.createdBy,
    };
