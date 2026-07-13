import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection_book.freezed.dart';
part 'collection_book.g.dart';

@freezed
abstract class CollectionBook with _$CollectionBook {
  const factory CollectionBook({
    required String bookId,
    @Default(0) int position,
    int? addedAt,
  }) = _CollectionBook;

  factory CollectionBook.fromJson(Map<String, dynamic> json) =>
      _$CollectionBookFromJson(json);
}
