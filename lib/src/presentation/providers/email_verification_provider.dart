import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerifiedNotifier extends Notifier<bool> {
  EmailVerifiedNotifier(this._userId);

  final String _userId;

  @override
  bool build() {
    // Reference the family argument to satisfy compiler/linter check
    final _ = _userId;
    final user = FirebaseAuth.instance.currentUser;
    return user?.emailVerified ?? false;
  }

  void setVerified(bool verified) {
    state = verified;
  }
}

final emailVerifiedProvider = NotifierProvider.family<EmailVerifiedNotifier, bool, String>(
  EmailVerifiedNotifier.new,
);
