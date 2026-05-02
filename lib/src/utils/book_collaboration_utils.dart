import '../domain/models/book.dart';
import '../domain/models/user_model.dart';

const collaborationStatusPending = 'pending';
const collaborationStatusAccepted = 'accepted';
const collaborationStatusDeclined = 'declined';

String? cleanCollaboratorId(Book book) {
  final id = book.collaboratorId?.trim();
  return id == null || id.isEmpty ? null : id;
}

bool isPendingCollaboration(Book book) {
  return book.collaborationStatus == collaborationStatusPending &&
      cleanCollaboratorId(book) != null;
}

bool isAcceptedCollaboration(Book book) {
  return book.collaborationStatus == collaborationStatusAccepted &&
      cleanCollaboratorId(book) != null;
}

bool canEditCollaborativeBook(Book book, String userId) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return false;
  if (book.authorId?.trim() == normalizedUserId) return true;
  return isAcceptedCollaboration(book) &&
      (book.authorIds ?? const <String>[]).contains(normalizedUserId);
}

bool canDeleteCollaborativeBook(Book book, String userId) {
  return book.authorId?.trim() == userId.trim() &&
      !isAcceptedCollaboration(book);
}

String primaryAuthorDisplayName(Book book, UserModel? user) {
  return _displayName(user) ??
      (book.authors.isNotEmpty ? book.authors.first.name.trim() : '');
}

String collaboratorDisplayName(Book book, UserModel? user) {
  return _displayName(user) ??
      book.collaboratorName?.trim() ??
      (book.authors.length > 1 ? book.authors[1].name.trim() : '');
}

String collaborativeAuthorLine(
  Book book, {
  UserModel? primary,
  UserModel? collaborator,
}) {
  final primaryName = primaryAuthorDisplayName(book, primary);
  if (!isAcceptedCollaboration(book)) return primaryName;
  final collaboratorName = collaboratorDisplayName(book, collaborator);
  if (primaryName.isEmpty) return collaboratorName;
  if (collaboratorName.isEmpty) return primaryName;
  return '$primaryName with $collaboratorName';
}

List<String> acceptedAuthorIdsFor(Book book) {
  final ids = <String>{};
  final primaryId = book.authorId?.trim();
  final collaboratorId = cleanCollaboratorId(book);
  if (primaryId != null && primaryId.isNotEmpty) ids.add(primaryId);
  if (isAcceptedCollaboration(book) &&
      collaboratorId != null &&
      collaboratorId.isNotEmpty) {
    ids.add(collaboratorId);
  }
  return ids.toList(growable: false);
}

String? _displayName(UserModel? user) {
  final displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  final penName = user?.penName?.trim();
  if (penName != null && penName.isNotEmpty) return penName;
  final username = user?.username.trim();
  if (username != null && username.isNotEmpty) return username;
  return null;
}
