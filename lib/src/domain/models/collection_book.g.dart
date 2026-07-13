// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CollectionBook _$CollectionBookFromJson(Map<String, dynamic> json) =>
    _CollectionBook(
      bookId: json['bookId'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      addedAt: (json['addedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CollectionBookToJson(_CollectionBook instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'position': instance.position,
      'addedAt': instance.addedAt,
    };
