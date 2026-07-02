import '../../domain/models/book.dart';

class WriterPadArguments {
  const WriterPadArguments({
    this.book,
    this.initialTopic,
    this.optOutComplementary,
    this.initialText,
  });

  final Book? book;
  final String? initialTopic;
  final bool? optOutComplementary;
  final String? initialText;
}
