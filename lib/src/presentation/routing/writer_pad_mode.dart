import '../../domain/models/book.dart';

enum WriterPadMode { content, chapterDraft }

class WriterPadArguments {
  const WriterPadArguments({
    this.book,
    this.initialTopic,
    this.mode = WriterPadMode.content,
    this.optOutComplementary,
  });

  final Book? book;
  final String? initialTopic;
  final WriterPadMode mode;
  final bool? optOutComplementary;
}
