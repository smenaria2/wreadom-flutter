import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive.dart';
import '../../domain/models/chapter_storage.dart';

String newChapterMutationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Upper bound for one chapter command, including publishing a large book.
const chapterCommandTimeout = Duration(seconds: 60);

class ChapterCommandService {
  ChapterCommandService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions = functions,
      _auth = auth;
  final FirebaseFunctions? _functions;
  final FirebaseAuth? _auth;
  final String editorSessionId = newChapterMutationId();
  final Map<String, String> leaseTokens = {};

  Future<Map<String, dynamic>> send(
    Map<String, dynamic> command, {
    String? mutationId,
  }) async {
    final auth = _auth ?? FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) throw StateError('Sign in to save your writing.');
    final box = await Hive.openBox('chapter_command_outbox');
    final installationId = box.get('installationId') ?? newChapterMutationId();
    await box.put('installationId', installationId);
    final id = mutationId ?? newChapterMutationId();
    final request = <String, dynamic>{
      ...command,
      'protocolVersion': chapterStorageVersion,
      'mutationId': id,
      'editorSessionId': editorSessionId,
      'installationId': installationId,
    };
    final key = '$userId:$id';
    final durable = [
      'saveBook',
      'importSingles',
      'exportChapter',
    ].contains(command['operation']);
    if (durable) {
      await box.put(key, {
        'userId': userId,
        'request': request,
        'savedLocallyAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    // A hung request must end so the writer can say the work is kept on this
    // device, instead of spinning forever.
    final result = await (_functions ?? FirebaseFunctions.instance)
        .httpsCallable(
          'chapterCommand',
          options: HttpsCallableOptions(timeout: chapterCommandTimeout),
        )
        .call<Map<String, dynamic>>(request);
    if (auth.currentUser?.uid != userId) {
      throw StateError(
        'Your account changed. Check the save result before continuing.',
      );
    }
    if (durable) await box.delete(key);
    return Map<String, dynamic>.from(result.data);
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final userId = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
    if (userId == null) return [];
    final box = await Hive.openBox('chapter_command_outbox');
    return box.values
        .whereType<Map>()
        .where((value) => value['userId'] == userId)
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }
}
