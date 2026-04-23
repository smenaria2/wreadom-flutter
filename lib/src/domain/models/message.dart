import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class MessageStoryData with _$MessageStoryData {
  const factory MessageStoryData({
    required String id,
    required String title,
    String? coverUrl,
    required String authorNames,
  }) = _MessageStoryData;

  factory MessageStoryData.fromJson(Map<String, dynamic> json) =>
      _$MessageStoryDataFromJson(json);
}

@freezed
abstract class Message with _$Message {
  const factory Message({
    String? id,
    required String senderId,
    required String senderName,
    String? senderPhotoURL,
    String? text,
    required int timestamp,
    required String type, // 'text' | 'story' | 'system'
    MessageStoryData? storyData,
    required List<String> readBy,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

@freezed
abstract class ParticipantDetail with _$ParticipantDetail {
  const factory ParticipantDetail({
    required String username,
    String? displayName,
    String? penName,
    String? photoURL,
  }) = _ParticipantDetail;

  factory ParticipantDetail.fromJson(Map<String, dynamic> json) =>
      _$ParticipantDetailFromJson(json);
}

@freezed
abstract class LastMessageInfo with _$LastMessageInfo {
  const factory LastMessageInfo({
    required String text,
    required String senderId,
    required int timestamp,
    required List<String> readBy,
  }) = _LastMessageInfo;

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) =>
      _$LastMessageInfoFromJson(json);
}

@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required List<String> participants,
    required Map<String, ParticipantDetail> participantDetails,
    required Map<String, String>
    memberStatus, // 'pending' | 'accepted' | 'blocked'
    LastMessageInfo? lastMessage,
    required String type, // 'direct' | 'group'
    String? name,
    required int createdAt,
    required int updatedAt,
    required String createdBy,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
