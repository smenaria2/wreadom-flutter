import '../domain/models/user_model.dart';

class UserNameFormatter {
  static String formatUserDisplayName(
    UserModel? user, {
    String? fallback = 'Reader',
  }) {
    if (user == null) return fallback ?? 'Reader';
    final penName = user.penName?.trim();
    if (penName != null && penName.isNotEmpty) return penName;

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final username = user.username.trim();
    if (username.isNotEmpty) return username;

    return fallback ?? 'Reader';
  }

  static String formatAuthorName({
    UserModel? user,
    String? penName,
    String? displayName,
    String? username,
    String? fallback,
  }) {
    if (user != null) {
      return formatUserDisplayName(user, fallback: fallback ?? 'Author');
    }

    final pName = penName?.trim();
    if (pName != null && pName.isNotEmpty) return pName;

    final dName = displayName?.trim();
    if (dName != null && dName.isNotEmpty) return dName;

    final uName = username?.trim();
    if (uName != null && uName.isNotEmpty) return uName;

    return fallback?.trim().isNotEmpty == true ? fallback!.trim() : 'Author';
  }
}
