import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_post_upload_service.dart';

final audioPostUploadServiceProvider = Provider<AudioPostUploadService>((ref) {
  return AudioPostUploadService();
});
