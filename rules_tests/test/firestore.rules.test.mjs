import { after, before, beforeEach, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'librebook-rules-test';
let testEnv;

const baseUser = (id, overrides = {}) => ({
  id,
  username: id,
  email: `${id}@example.com`,
  displayName: id,
  privacyLevel: 'public',
  isDeactivated: false,
  totalPoints: 0,
  tier: 1,
  readingHistory: [],
  savedBooks: [],
  bookmarks: [],
  createdAt: 1,
  lastLogin: 1,
  ...overrides,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), baseUser('alice'));
    await setDoc(doc(db, 'users/bob'), baseUser('bob'));
    await setDoc(doc(db, 'books/book1'), {
      authorId: 'alice',
      authorIds: ['alice'],
      status: 'published',
      title: 'Published Book',
      viewCount: 0,
    });
    await setDoc(doc(db, 'notifications/n1'), {
      userId: 'alice',
      actorId: 'bob',
      type: 'message',
      isRead: false,
      timestamp: 1,
    });
    await setDoc(doc(db, 'conversations/c1'), {
      participants: ['alice', 'bob'],
      type: 'direct',
      updatedAt: 1,
    });
  });
});

after(async () => {
  await testEnv?.cleanup();
});

describe('users rules', () => {
  it('allows safe owner profile updates', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(updateDoc(doc(aliceDb, 'users/alice'), {
      bio: 'Reader and writer',
      preferredLanguage: 'hi',
    }));
  });

  it('blocks owner updates to protected account and moderation fields', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    await assertFails(updateDoc(doc(aliceDb, 'users/alice'), { totalPoints: 9999 }));
    await assertFails(updateDoc(doc(aliceDb, 'users/alice'), { tier: 9 }));
    await assertFails(updateDoc(doc(aliceDb, 'users/alice'), { isDeactivated: true }));
    await assertFails(updateDoc(doc(aliceDb, 'users/alice'), { email: 'new@example.com' }));
    await assertFails(updateDoc(doc(aliceDb, 'users/alice'), { fcmTokens: ['token'] }));
    await assertFails(updateDoc(doc(aliceDb, 'users/alice'), {
      fcmTokenRegistry: [{ token: 'token', platform: 'web' }],
    }));
  });

  it('allows custom-claim admins to update protected user fields', async () => {
    const adminDb = testEnv.authenticatedContext('admin', { admin: true }).firestore();
    await assertSucceeds(updateDoc(doc(adminDb, 'users/alice'), { isDeactivated: true }));
  });

  it('blocks non-admins from updating other user documents', async () => {
    const bobDb = testEnv.authenticatedContext('bob').firestore();
    await assertFails(updateDoc(doc(bobDb, 'users/alice'), { bio: 'owned' }));
  });
});

describe('admin-only collections', () => {
  it('allows admin claims and legacy admin email for settings writes', async () => {
    const claimAdminDb = testEnv.authenticatedContext('claim-admin', { admin: true }).firestore();
    const emailAdminDb = testEnv.authenticatedContext('email-admin', {
      email: 'smenaria2@gmail.com',
    }).firestore();

    await assertSucceeds(setDoc(doc(claimAdminDb, 'settings/app_update'), { latestVersion: '1.2.3' }));
    await assertSucceeds(setDoc(doc(emailAdminDb, 'home-banners/banner1'), { title: 'Banner' }));
  });

  it('blocks regular users from admin-only writes', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(aliceDb, 'settings/app_update'), { latestVersion: '9.9.9' }));
    await assertFails(setDoc(doc(aliceDb, 'home-banners/banner1'), { title: 'Banner' }));
  });
});

describe('notifications and conversations', () => {
  it('keeps notifications private to their recipient', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    const bobDb = testEnv.authenticatedContext('bob').firestore();

    await assertSucceeds(getDoc(doc(aliceDb, 'notifications/n1')));
    await assertFails(getDoc(doc(bobDb, 'notifications/n1')));
    await assertSucceeds(updateDoc(doc(aliceDb, 'notifications/n1'), { isRead: true }));
    await assertFails(updateDoc(doc(aliceDb, 'notifications/n1'), { type: 'follow' }));
  });

  it('keeps conversations private to participants', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    const eveDb = testEnv.authenticatedContext('eve').firestore();

    await assertSucceeds(getDoc(doc(aliceDb, 'conversations/c1')));
    await assertFails(getDoc(doc(eveDb, 'conversations/c1')));
  });
});

describe('books and recommendations', () => {
  it('allows a signed-in user to record one book view and blocks anonymous views', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();
    const guestDb = testEnv.unauthenticatedContext().firestore();

    await assertSucceeds(setDoc(doc(aliceDb, 'books/book1/views/user:alice'), {
      viewerId: 'user:alice',
      bookId: 'book1',
      timestamp: 1,
    }));
    await assertFails(setDoc(doc(guestDb, 'books/book1/views/anon:guest'), {
      viewerId: 'anon:guest',
      bookId: 'book1',
      timestamp: 1,
    }));
  });

  it('constrains recommendation document ids to the signed-in user and book', async () => {
    const aliceDb = testEnv.authenticatedContext('alice').firestore();

    await assertSucceeds(setDoc(doc(aliceDb, 'recommendations/alice_book1'), {
      userId: 'alice',
      bookId: 'book1',
      type: 'up',
    }));
    await assertFails(setDoc(doc(aliceDb, 'recommendations/bob_book1'), {
      userId: 'alice',
      bookId: 'book1',
      type: 'up',
    }));
    await assertFails(setDoc(doc(aliceDb, 'recommendations/alice_book2'), {
      userId: 'alice',
      bookId: 'book2',
      type: 'favorite',
    }));
  });

  it('prevents regular users from deleting someone else content', async () => {
    const bobDb = testEnv.authenticatedContext('bob').firestore();
    await assertFails(deleteDoc(doc(bobDb, 'books/book1')));
  });
});
