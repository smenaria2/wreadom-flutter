import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_post_upload_service.dart';

final audioPostUploadServiceProvider = Provider<AudioPostUploadService>((ref) {
  return AudioPostUploadService();
});

class LockScroll extends Notifier<bool> {
  @override
  bool build() => false;

  void setLock(bool lock) {
    state = lock;
  }
}

final lockScrollProvider = NotifierProvider<LockScroll, bool>(LockScroll.new);
