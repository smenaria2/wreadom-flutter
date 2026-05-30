const admin = require('firebase-admin');

// Initialize Firebase Admin
// If running locally, make sure to set the GOOGLE_APPLICATION_CREDENTIALS env var,
// or run the Firebase emulator.
try {
  admin.initializeApp({
    projectId: 'studio-8109133561-1eb90'
  });
  console.log('Firebase Admin initialized successfully.');
} catch (error) {
  console.error('Error initializing Firebase Admin:', error);
  process.exit(1);
}

const db = admin.firestore();

async function migrateCovers() {
  console.log('Starting migration to change book covers from crop (c_fill) to pad (c_pad,b_auto)...');
  const booksRef = db.collection('books');
  const snapshot = await booksRef.get();
  
  if (snapshot.empty) {
    console.log('No books found.');
    return;
  }

  let updatedCount = 0;
  let currentBatch = db.batch();
  let operationsInBatch = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const coverUrl = data.coverUrl;

    if (coverUrl && typeof coverUrl === 'string' && coverUrl.includes('c_fill')) {
      const newCoverUrl = coverUrl.replace('c_fill', 'c_pad,b_auto');
      console.log(`Updating book [${doc.id}]: "${data.title || 'Untitled'}"`);
      console.log(`  Old Cover: ${coverUrl}`);
      console.log(`  New Cover: ${newCoverUrl}`);
      
      currentBatch.update(doc.ref, { coverUrl: newCoverUrl });
      operationsInBatch++;
      updatedCount++;

      // Commit in chunks of 400 to stay well under the Firestore batch limit of 500
      if (operationsInBatch === 400) {
        console.log('Committing batch of 400 updates...');
        await currentBatch.commit();
        currentBatch = db.batch();
        operationsInBatch = 0;
      }
    }
  }

  if (operationsInBatch > 0) {
    console.log(`Committing final batch of ${operationsInBatch} updates...`);
    await currentBatch.commit();
  }

  console.log(`Migration complete. Updated ${updatedCount} out of ${snapshot.size} books.`);
}

migrateCovers().catch(err => {
  console.error('Migration failed:', err);
});
