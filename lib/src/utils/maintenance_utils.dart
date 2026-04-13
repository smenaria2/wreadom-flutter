import 'package:cloud_firestore/cloud_firestore.dart';

/// One-off script to migrate embedded feed comments to the separate collection.
Future<void> migrateComments() async {
  print('--- Starting Migration: Feed Comments ---');
  final firestore = FirebaseFirestore.instance;
  
  final feedSnapshot = await firestore.collection('feed').get();
  print('Found ${feedSnapshot.docs.length} feed posts.');

  int totalMigrated = 0;

  for (final postDoc in feedSnapshot.docs) {
    final data = postDoc.data();
    final List<dynamic>? embeddedComments = data['comments'];

    if (embeddedComments == null || embeddedComments.isEmpty) continue;

    print('Processing post ${postDoc.id} (${embeddedComments.length} comments)...');

    for (final commentData in embeddedComments) {
      if (commentData is! Map<String, dynamic>) continue;

      // Map to new Comment structure if needed
      final newComment = {
        ...commentData,
        'feedPostId': postDoc.id,
        // Ensure book fields are null for these
        'bookId': null,
        'bookTitle': null,
      };

      await firestore.collection('comments').add(newComment);
      totalMigrated++;
    }

    // Clear the array and set the count
    await postDoc.reference.update({
      'comments': FieldValue.delete(),
      'commentCount': embeddedComments.length,
    });
  }

  print('--- Migration Finished: $totalMigrated comments moved ---');
}
