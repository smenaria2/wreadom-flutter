import '../../domain/models/book.dart';

class WriterPadArguments {
  const WriterPadArguments({
    this.book,
    this.initialTopic,
    this.optOutComplementary,
  });

  final Book? book;
  final String? initialTopic;
  final bool? optOutComplementary;
}
