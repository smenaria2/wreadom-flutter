const functionsV1 = require("firebase-functions/v1");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {DeleteObjectCommand, GetObjectCommand, PutObjectCommand, S3Client} = require("@aws-sdk/client-s3");
const {getSignedUrl} = require("@aws-sdk/s3-request-presigner");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const MAX_BATCH_WRITES = 450;
const MAX_AUDIO_REVIEW_DURATION_MS = 120000;
const MAX_AUDIO_REVIEW_BYTES = 2 * 1024 * 1024;
const AUDIO_REVIEW_MIME_TYPES = new Set(["audio/mp4", "audio/m4a", "audio/aac"]);
const B2_SECRET_NAMES = [
  "B2_KEY_ID",
  "B2_APPLICATION_KEY",
  "B2_AUDIO_BUCKET_NAME",
  "B2_AUDIO_BUCKET_ID",
  "B2_AUDIO_S3_ENDPOINT",
  "B2_AUDIO_DOWNLOAD_BASE_URL",
];

function normalizeString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function configValue(envName, configName = envName.toLowerCase()) {
  const envValue = normalizeString(process.env[envName]);
  if (envValue) return envValue;
  try {
    const b2Config = functionsV1.config().b2 || {};
    return normalizeString(b2Config[configName]);
  } catch (_) {
    return "";
  }
}

function requireB2Config() {
  const config = {
    keyId: configValue("B2_KEY_ID", "key_id"),
    applicationKey: configValue("B2_APPLICATION_KEY", "application_key"),
    bucketName: configValue("B2_AUDIO_BUCKET_NAME", "audio_bucket_name"),
    bucketId: configValue("B2_AUDIO_BUCKET_ID", "audio_bucket_id"),
    endpoint: configValue("B2_AUDIO_S3_ENDPOINT", "audio_s3_endpoint"),
    downloadBaseUrl: configValue("B2_AUDIO_DOWNLOAD_BASE_URL", "audio_download_base_url"),
  };
  const missing = Object.entries(config)
      .filter(([, value]) => !normalizeString(value))
      .map(([key]) => key);
  if (missing.length > 0) {
    throw new functionsV1.https.HttpsError(
        "failed-precondition",
        `Backblaze audio storage is missing config: ${missing.join(", ")}.`,
    );
  }
  return config;
}

function audioReviewS3Client(config) {
  const regionMatch = config.endpoint.match(/s3[.-]([a-z0-9-]+)\.backblazeb2\.com/i);
  return new S3Client({
    region: regionMatch?.[1] || "us-west-004",
    endpoint: config.endpoint,
    forcePathStyle: true,
    credentials: {
      accessKeyId: config.keyId,
      secretAccessKey: config.applicationKey,
    },
  });
}

function safeObjectSegment(value, fallback) {
  const normalized = normalizeString(`${value || ""}`)
      .toLowerCase()
      .replace(/[^a-z0-9_-]+/g, "-")
      .replace(/^-+|-+$/g, "");
  return normalized || fallback;
}

function encodedObjectPath(objectKey) {
  return objectKey.split("/").map((segment) => encodeURIComponent(segment)).join("/");
}

function audioReviewObjectKey({userId, bookId, chapterId}) {
  return [
    "audio-reviews",
    safeObjectSegment(userId, "user"),
    safeObjectSegment(bookId, "book"),
    safeObjectSegment(chapterId, "book"),
    `${Date.now()}.m4a`,
  ].join("/");
}

function validateAudioReviewRequest(data = {}) {
  const bookId = normalizeString(data.bookId);
  const chapterId = normalizeString(data.chapterId);
  const durationMs = Number.parseInt(`${data.durationMs || 0}`, 10) || 0;
  const sizeBytes = Number.parseInt(`${data.sizeBytes || 0}`, 10) || 0;
  const mimeType = normalizeString(data.mimeType).toLowerCase();
  if (!bookId) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Missing bookId.");
  }
  if (durationMs <= 0 || durationMs > MAX_AUDIO_REVIEW_DURATION_MS) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Audio review must be 2 minutes or shorter.");
  }
  if (sizeBytes <= 0 || sizeBytes > MAX_AUDIO_REVIEW_BYTES) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Audio review is too large.");
  }
  if (!AUDIO_REVIEW_MIME_TYPES.has(mimeType)) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Unsupported audio type.");
  }
  return {bookId, chapterId, durationMs, sizeBytes, mimeType};
}

function userDisplayName(data = {}) {
  return normalizeString(data.displayName) ||
    normalizeString(data.penName) ||
    normalizeString(data.username) ||
    "Reader";
}

function participantDetailsFromUser(data = {}) {
  return {
    username: normalizeString(data.username),
    displayName: normalizeString(data.displayName) || null,
    penName: normalizeString(data.penName) || null,
    photoURL: normalizeString(data.photoURL) || null,
  };
}

async function commitInChunks(references, buildUpdate) {
  for (let i = 0; i < references.length; i += MAX_BATCH_WRITES) {
    const batch = db.batch();
    for (const ref of references.slice(i, i + MAX_BATCH_WRITES)) {
      batch.update(ref, buildUpdate(ref));
    }
    await batch.commit();
  }
}

async function getUserDoc(userId) {
  if (!normalizeString(userId)) {
    return null;
  }
  const snapshot = await db.collection("users").doc(userId).get();
  return snapshot.exists ? snapshot.data() : null;
}

async function createNotificationDoc(docId, notification) {
  if (!notification || notification.userId === notification.actorId) {
    return;
  }
  const targetRef = db.collection("notifications").doc(docId);
  await targetRef.set(notification, {merge: true});
}

async function deleteNotificationDoc(docId) {
  await db.collection("notifications").doc(docId).delete().catch(() => undefined);
}

function buildNotification({
  userId,
  actorId,
  actorName,
  actorPhotoURL,
  type,
  text,
  link = "",
  targetId = null,
  metadata = {},
}) {
  return {
    userId,
    actorId,
    actorName,
    actorPhotoURL: actorPhotoURL || null,
    type,
    text,
    link,
    targetId,
    timestamp: Date.now(),
    isRead: false,
    metadata,
  };
}

function diffAddedStrings(before = [], after = []) {
  const beforeSet = new Set(before.map((value) => `${value}`));
  return after.filter((value) => !beforeSet.has(`${value}`));
}

function replyIdentifier(reply = {}) {
  return normalizeString(reply.id) || normalizeString(reply.timestamp);
}

function diffAddedReplies(before = [], after = []) {
  const beforeSet = new Set(before.map(replyIdentifier).filter(Boolean));
  return after.filter((reply) => {
    const id = replyIdentifier(reply);
    return id && !beforeSet.has(id);
  });
}

async function updateBookReviewAggregates(bookId) {
  const normalizedBookId = normalizeString(bookId);
  if (!normalizedBookId) {
    return;
  }

  const idAsNumber = Number.parseInt(normalizedBookId, 10);
  const queryValues = Number.isNaN(idAsNumber) ? [normalizedBookId] : [normalizedBookId, idAsNumber];
  const snapshot = await db.collection("comments").where("bookId", "in", queryValues).get().catch(() => null);
  if (!snapshot) {
    return;
  }

  let ratingsCount = 0;
  let ratingsTotal = 0;
  for (const doc of snapshot.docs) {
    const rating = Number(doc.data().rating || 0);
    if (rating > 0) {
      ratingsCount += 1;
      ratingsTotal += rating;
    }
  }

  const averageRating = ratingsCount > 0 ? Number((ratingsTotal / ratingsCount).toFixed(2)) : 0;
  await db.collection("books").doc(normalizedBookId).set({
    ratingsCount,
    averageRating,
    updatedAt: Date.now(),
  }, {merge: true});
}

async function runReviewHighlightToggle({
  commentId,
  bookId,
  authorId,
  maxHighlighted = 3,
}) {
  const normalizedCommentId = normalizeString(commentId);
  const normalizedBookId = normalizeString(bookId);
  const normalizedAuthorId = normalizeString(authorId);
  if (!normalizedCommentId || !normalizedBookId || !normalizedAuthorId) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Missing highlight identifiers.");
  }

  const bookSnapshot = await db.collection("books").doc(normalizedBookId).get();
  if (!bookSnapshot.exists) {
    throw new functionsV1.https.HttpsError("not-found", "Book not found.");
  }
  const book = bookSnapshot.data() || {};
  if (normalizeString(book.authorId) !== normalizedAuthorId) {
    throw new functionsV1.https.HttpsError("permission-denied", "Only the author can pin reviews.");
  }

  const commentRef = db.collection("comments").doc(normalizedCommentId);
  const snap = await commentRef.get();
  if (!snap.exists) {
    throw new functionsV1.https.HttpsError("not-found", "Comment not found.");
  }

  const data = snap.data() || {};
  const rating = Number.parseInt(`${data.rating || 0}`, 10) || 0;
  if (rating <= 0) {
    return {updated: false, highlighted: false};
  }

  const idAsInt = Number.parseInt(normalizedBookId, 10);
  const ids = Number.isNaN(idAsInt) ? [normalizedBookId] : [normalizedBookId, idAsInt];
  const highlighted = await db.collection("comments")
      .where("bookId", "in", ids)
      .where("isHighlighted", "==", true)
      .get();

  const highlightedReviews = highlighted.docs.filter((doc) => {
    const value = doc.data() || {};
    return (Number.parseInt(`${value.rating || 0}`, 10) || 0) > 0;
  });

  const isHighlighted = data.isHighlighted === true;
  if (isHighlighted) {
    await commentRef.update({
      isHighlighted: false,
      highlightedAt: FieldValue.delete(),
      highlightedByUserId: FieldValue.delete(),
    });
    return {updated: true, highlighted: false};
  }

  if (highlightedReviews.length >= maxHighlighted) {
    throw new functionsV1.https.HttpsError(
        "failed-precondition",
        `You can highlight up to ${maxHighlighted} reviews.`,
    );
  }

  await commentRef.update({
    isHighlighted: true,
    highlightedAt: Date.now(),
    highlightedByUserId: normalizedAuthorId,
  });
  return {updated: true, highlighted: true};
}

async function notifyFollowersForPublishedBook(bookId, afterData) {
  const authorId = normalizeString(afterData.authorId);
  if (!authorId) {
    return;
  }
  const authorData = await getUserDoc(authorId);
  if (!authorData) {
    return;
  }

  const followersSnapshot = await db.collection("follows")
      .where("followingId", "==", authorId)
      .get();

  const actorName = userDisplayName(authorData);
  const actorPhotoURL = normalizeString(authorData.photoURL) || null;
  const title = normalizeString(afterData.title) || "a new book";

  const writes = followersSnapshot.docs
      .map((doc) => normalizeString(doc.data().followerId))
      .filter((userId) => userId && userId !== authorId)
      .map((userId) => ({
        ref: db.collection("notifications").doc(`new_creation_${bookId}_${userId}`),
        data: buildNotification({
          userId,
          actorId: authorId,
          actorName,
          actorPhotoURL,
          type: "new_creation",
          text: `${actorName} published ${title}`,
          link: `/book?id=${bookId}`,
          targetId: bookId,
          metadata: {bookId},
        }),
      }));

  for (let i = 0; i < writes.length; i += MAX_BATCH_WRITES) {
    const batch = db.batch();
    for (const write of writes.slice(i, i + MAX_BATCH_WRITES)) {
      batch.set(write.ref, write.data, {merge: true});
    }
    await batch.commit();
  }
}

exports.onFollowCreated = functionsV1.firestore.document("follows/{followId}").onCreate(async (snapshot, context) => {
  const data = snapshot.data();
  if (!data) {
    return;
  }

  const followerId = normalizeString(data.followerId);
  const followingId = normalizeString(data.followingId);
  if (!followerId || !followingId || followerId === followingId) {
    return;
  }

  await db.runTransaction(async (transaction) => {
    transaction.set(db.collection("users").doc(followerId), {
      followingCount: FieldValue.increment(1),
    }, {merge: true});
    transaction.set(db.collection("users").doc(followingId), {
      followersCount: FieldValue.increment(1),
    }, {merge: true});
  });

  const followerData = await getUserDoc(followerId);
  if (!followerData) {
    return;
  }

  await createNotificationDoc(
      `follow_${context.params.followId}`,
      buildNotification({
        userId: followingId,
        actorId: followerId,
        actorName: userDisplayName(followerData),
        actorPhotoURL: normalizeString(followerData.photoURL) || null,
        type: "follow",
        text: "started following you",
        targetId: followerId,
        metadata: {userId: followerId},
      }),
  );
  return null;
});

exports.onFollowDeleted = functionsV1.firestore.document("follows/{followId}").onDelete(async (snapshot, context) => {
  const data = snapshot.data();
  if (!data) {
    return;
  }

  const followerId = normalizeString(data.followerId);
  const followingId = normalizeString(data.followingId);
  if (!followerId || !followingId || followerId === followingId) {
    return;
  }

  await db.runTransaction(async (transaction) => {
    transaction.set(db.collection("users").doc(followerId), {
      followingCount: FieldValue.increment(-1),
    }, {merge: true});
    transaction.set(db.collection("users").doc(followingId), {
      followersCount: FieldValue.increment(-1),
    }, {merge: true});
  });

  await deleteNotificationDoc(`follow_${context.params.followId}`);
  return null;
});

exports.onCommentWritten = functionsV1.firestore.document("comments/{commentId}").onWrite(async (change, context) => {
  const beforeData = change.before.exists ? change.before.data() : null;
  const afterData = change.after.exists ? change.after.data() : null;
  const commentId = context.params.commentId;

  const feedPostId = normalizeString(afterData?.feedPostId || beforeData?.feedPostId);
  if (feedPostId) {
    const delta = beforeData && !afterData ? -1 : !beforeData && afterData ? 1 : 0;
    if (delta !== 0) {
      await db.collection("feed").doc(feedPostId).set({
        commentCount: FieldValue.increment(delta),
      }, {merge: true});
    }
  }

  const bookIdRaw = afterData?.bookId ?? beforeData?.bookId;
  if (bookIdRaw != null) {
    await updateBookReviewAggregates(`${bookIdRaw}`);
  }

  if (!beforeData && afterData) {
    const actorId = normalizeString(afterData.userId);
    const actorName = userDisplayName(afterData);
    const actorPhotoURL = normalizeString(afterData.userPhotoURL) || null;

    if (feedPostId) {
      const postSnapshot = await db.collection("feed").doc(feedPostId).get();
      if (postSnapshot.exists) {
        const post = postSnapshot.data() || {};
        const ownerId = normalizeString(post.userId);
        await createNotificationDoc(
            `feed_comment_${commentId}`,
            buildNotification({
              userId: ownerId,
              actorId,
              actorName,
              actorPhotoURL,
              type: "feed_comment",
              text: "commented on your post",
              link: `/post?id=${feedPostId}`,
              targetId: feedPostId,
              metadata: {postId: feedPostId},
            }),
        );
      }
    }

    const bookId = normalizeString(`${afterData.bookId ?? ""}`);
    if (bookId) {
      const bookSnapshot = await db.collection("books").doc(bookId).get();
      if (bookSnapshot.exists) {
        const book = bookSnapshot.data() || {};
        const ownerId = normalizeString(book.authorId);
        const notificationType = Number(afterData.rating || 0) > 0 ? "book_review" : "book_comment";
        const isAudioReview = notificationType === "book_review" &&
          (normalizeString(afterData.audioObjectKey) || normalizeString(afterData.audioUrl));
        await createNotificationDoc(
            `book_comment_${commentId}`,
            buildNotification({
              userId: ownerId,
              actorId,
              actorName,
              actorPhotoURL,
              type: notificationType,
              text: isAudioReview ?
                "submitted an audio review on your content" :
                Number(afterData.rating || 0) > 0 ? "left a review on your content" : "commented on your content",
              link: `/book?id=${bookId}`,
              targetId: bookId,
              metadata: {bookId, commentId, hasAudio: Boolean(isAudioReview)},
            }),
        );
      }
    }
  }

  if (beforeData && afterData) {
    const hadAudio = Boolean(normalizeString(beforeData.audioObjectKey) || normalizeString(beforeData.audioUrl));
    const hasAudio = Boolean(normalizeString(afterData.audioObjectKey) || normalizeString(afterData.audioUrl));
    if (!hadAudio && hasAudio && Number(afterData.rating || 0) > 0) {
      await notifyBookOwnerForAudioReview(commentId, afterData);
    }

    const beforeReplies = Array.isArray(beforeData.replies) ? beforeData.replies : [];
    const afterReplies = Array.isArray(afterData.replies) ? afterData.replies : [];
    for (const reply of diffAddedReplies(beforeReplies, afterReplies)) {
      const actorId = normalizeString(reply.userId);
      await createNotificationDoc(
          `reply_${commentId}_${replyIdentifier(reply)}`,
          buildNotification({
            userId: normalizeString(afterData.userId),
            actorId,
            actorName: userDisplayName(reply),
            actorPhotoURL: normalizeString(reply.userPhotoURL) || null,
            type: normalizeString(afterData.feedPostId) ? "feed_reply" : "book_reply",
            text: normalizeString(afterData.feedPostId) ? "replied to your comment" : "replied to your discussion",
            link: normalizeString(afterData.feedPostId) ? `/post?id=${normalizeString(afterData.feedPostId)}` : `/book?id=${normalizeString(`${afterData.bookId ?? ""}`)}`,
            targetId: normalizeString(afterData.feedPostId) || normalizeString(`${afterData.bookId ?? ""}`) || null,
            metadata: {
              commentId,
              postId: normalizeString(afterData.feedPostId) || null,
              bookId: afterData.bookId ?? null,
            },
          }),
      );
    }
  }
  return null;
});

exports.onFeedPostUpdated = functionsV1.firestore.document("feed/{postId}").onUpdate(async (change, context) => {
  const beforeData = change.before.data() || {};
  const afterData = change.after.data() || {};
  const postId = context.params.postId;
  const ownerId = normalizeString(afterData.userId);
  const addedLikes = diffAddedStrings(beforeData.likes || [], afterData.likes || []);
  if (!ownerId || addedLikes.length === 0) {
    return;
  }

  for (const likerId of addedLikes) {
    const liker = await getUserDoc(likerId);
    if (!liker) {
      continue;
    }
    await createNotificationDoc(
        `post_like_${postId}_${likerId}`,
        buildNotification({
          userId: ownerId,
          actorId: likerId,
          actorName: userDisplayName(liker),
          actorPhotoURL: normalizeString(liker.photoURL) || null,
          type: "post_like",
          text: "liked your post",
          link: `/post?id=${postId}`,
          targetId: postId,
          metadata: {postId},
        }),
    );
  }
  return null;
});

exports.onUserProfileUpdated = functionsV1.firestore.document("users/{userId}").onUpdate(async (change, context) => {
  const beforeData = change.before.data() || {};
  const afterData = change.after.data() || {};
  const userId = context.params.userId;

  const watchedFields = ["username", "displayName", "penName", "photoURL"];
  const changed = watchedFields.some((field) => beforeData[field] !== afterData[field]);
  if (!changed) {
    return;
  }

  const feedSnapshot = await db.collection("feed").where("userId", "==", userId).get();
  const commentSnapshot = await db.collection("comments").where("userId", "==", userId).get();
  const conversationSnapshot = await db.collection("conversations")
      .where("participants", "array-contains", userId)
      .get();

  const details = participantDetailsFromUser(afterData);
  const display = userDisplayName(afterData);
  const photoURL = normalizeString(afterData.photoURL) || null;

  await commitInChunks(feedSnapshot.docs.map((doc) => doc.ref), () => ({
    username: normalizeString(afterData.username),
    displayName: normalizeString(afterData.displayName) || null,
    penName: normalizeString(afterData.penName) || null,
    userPhotoURL: photoURL,
  }));

  await commitInChunks(commentSnapshot.docs.map((doc) => doc.ref), () => ({
    username: normalizeString(afterData.username),
    displayName: normalizeString(afterData.displayName) || null,
    penName: normalizeString(afterData.penName) || null,
    userPhotoURL: photoURL,
  }));

  await commitInChunks(conversationSnapshot.docs.map((doc) => doc.ref), () => ({
    [`participantDetails.${userId}`]: details,
  }));

  const messageCollectionSnapshots = await Promise.all(
      conversationSnapshot.docs.map((doc) => doc.ref.collection("messages")
          .where("senderId", "==", userId)
          .get()),
  );
  const messageRefs = messageCollectionSnapshots.flatMap((snapshot) => snapshot.docs.map((doc) => doc.ref));
  await commitInChunks(messageRefs, () => ({
    senderName: display,
    senderPhotoURL: photoURL,
  }));
  return null;
});

async function notifyBookOwnerForAudioReview(commentId, data = {}) {
  const bookId = normalizeString(`${data.bookId ?? ""}`);
  const actorId = normalizeString(data.userId);
  if (!bookId || !actorId) {
    return;
  }
  const bookSnapshot = await db.collection("books").doc(bookId).get();
  if (!bookSnapshot.exists) {
    return;
  }
  const book = bookSnapshot.data() || {};
  const ownerId = normalizeString(book.authorId);
  await createNotificationDoc(
      `book_audio_review_${commentId}`,
      buildNotification({
        userId: ownerId,
        actorId,
        actorName: userDisplayName(data),
        actorPhotoURL: normalizeString(data.userPhotoURL) || null,
        type: "book_review",
        text: "submitted an audio review on your content",
        link: `/book?id=${bookId}`,
        targetId: bookId,
        metadata: {
          bookId,
          commentId,
          hasAudio: true,
        },
      }),
  );
}

exports.onMessageCreated = functionsV1.firestore.document("conversations/{conversationId}/messages/{messageId}").onCreate(async (snapshot, context) => {
  const message = snapshot.data();
  if (!message) {
    return;
  }

  const conversationId = context.params.conversationId;
  const conversationRef = db.collection("conversations").doc(conversationId);
  const conversationSnapshot = await conversationRef.get();
  if (!conversationSnapshot.exists) {
    return;
  }
  const conversation = conversationSnapshot.data() || {};
  const participants = Array.isArray(conversation.participants) ? conversation.participants.map((value) => `${value}`) : [];
  const senderId = normalizeString(message.senderId);
  const otherParticipants = participants.filter((value) => value && value !== senderId);

  await conversationRef.set({
    updatedAt: Number(message.timestamp || Date.now()),
    lastMessage: {
      text: normalizeString(message.text),
      senderId,
      timestamp: Number(message.timestamp || Date.now()),
      readBy: Array.isArray(message.readBy) ? message.readBy : [senderId],
    },
  }, {merge: true});

  for (const userId of otherParticipants) {
    await createNotificationDoc(
        `message_${conversationId}_${context.params.messageId}_${userId}`,
        buildNotification({
          userId,
          actorId: senderId,
          actorName: normalizeString(message.senderName) || "Reader",
          actorPhotoURL: normalizeString(message.senderPhotoURL) || null,
          type: "message",
          text: message.type === "story" ? "sent you a book" : "sent you a message",
          targetId: conversationId,
          metadata: {
            conversationId,
            id: conversationId,
            messageId: context.params.messageId,
            ...(message.storyData ? {bookId: message.storyData.id || null} : {}),
          },
        }),
    );
  }
  return null;
});

exports.onBookWritten = functionsV1.firestore.document("books/{bookId}").onWrite(async (change, context) => {
  const beforeData = change.before.exists ? change.before.data() : null;
  const afterData = change.after.exists ? change.after.data() : null;
  if (!afterData) {
    return;
  }

  const wasPublished = normalizeString(beforeData?.status).toLowerCase() === "published";
  const isPublished = normalizeString(afterData.status).toLowerCase() === "published";
  if (!wasPublished && isPublished) {
    await notifyFollowersForPublishedBook(context.params.bookId, afterData);
  }
  return null;
});

exports.toggleReviewHighlight = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Authentication required.");
  }

  return runReviewHighlightToggle({
    commentId: data?.commentId,
    bookId: data?.bookId,
    authorId: context.auth.uid,
    maxHighlighted: Number.parseInt(`${data?.maxHighlighted ?? 3}`, 10) || 3,
  });
});

exports.createAudioReviewUploadTarget = functionsV1
    .runWith({secrets: B2_SECRET_NAMES})
    .https.onCall(async (data, context) => {
      if (!context.auth?.uid) {
        throw new functionsV1.https.HttpsError("unauthenticated", "Authentication required.");
      }

      const {bookId, chapterId, mimeType} = validateAudioReviewRequest(data);
      const config = requireB2Config();
      const objectKey = audioReviewObjectKey({
        userId: context.auth.uid,
        bookId,
        chapterId,
      });
      const command = new PutObjectCommand({
        Bucket: config.bucketName,
        Key: objectKey,
        ContentType: mimeType,
      });
      const uploadUrl = await getSignedUrl(audioReviewS3Client(config), command, {
        expiresIn: 10 * 60,
      });
      const baseUrl = config.downloadBaseUrl.replace(/\/+$/, "");

      return {
        uploadUrl,
        headers: {"content-type": mimeType},
        objectKey,
        audioUrl: `${baseUrl}/${encodedObjectPath(objectKey)}`,
      };
    });

exports.deleteAudioReviewObject = functionsV1
    .runWith({secrets: B2_SECRET_NAMES})
    .https.onCall(async (data, context) => {
      if (!context.auth?.uid) {
        throw new functionsV1.https.HttpsError("unauthenticated", "Authentication required.");
      }

      const objectKey = normalizeString(data?.objectKey);
      const prefix = `audio-reviews/${safeObjectSegment(context.auth.uid, "user")}/`;
      if (!objectKey || !objectKey.startsWith(prefix)) {
        throw new functionsV1.https.HttpsError("permission-denied", "Audio object does not belong to this user.");
      }

      const config = requireB2Config();
      await audioReviewS3Client(config).send(new DeleteObjectCommand({
        Bucket: config.bucketName,
        Key: objectKey,
      }));
      return {deleted: true};
    });

exports.createAudioReviewDownloadUrl = functionsV1
    .runWith({secrets: B2_SECRET_NAMES})
    .https.onCall(async (data) => {
      const objectKey = normalizeString(data?.objectKey);
      if (!objectKey || !objectKey.startsWith("audio-reviews/")) {
        throw new functionsV1.https.HttpsError("invalid-argument", "Missing audio object key.");
      }

      const config = requireB2Config();
      const command = new GetObjectCommand({
        Bucket: config.bucketName,
        Key: objectKey,
      });
      const downloadUrl = await getSignedUrl(audioReviewS3Client(config), command, {
        expiresIn: 15 * 60,
      });
      return {downloadUrl};
    });

async function refreshHomepageMetadataInternal() {
  const [booksSnapshot, authorsSnapshot, topicsSnapshot, bannersSnapshot] = await Promise.all([
    db.collection("books")
        .where("status", "==", "published")
        .where("isOriginal", "==", true)
        .orderBy("updatedAt", "desc")
        .limit(60)
        .get()
        .catch(() => null),
    db.collection("users")
        .orderBy("followersCount", "desc")
        .limit(20)
        .get()
        .catch(() => null),
    db.collection("daily-topics")
        .where("isEnabled", "==", true)
        .orderBy("timestamp", "desc")
        .limit(10)
        .get()
        .catch(() => null),
    db.collection("home-banners")
        .where("isEnabled", "==", true)
        .orderBy("timestamp", "desc")
        .limit(10)
        .get()
        .catch(() => null),
  ]);

  const authors = (authorsSnapshot?.docs || []).map((doc) => {
    const data = doc.data() || {};
    return {
      id: doc.id,
      username: normalizeString(data.username),
      displayName: normalizeString(data.displayName) || null,
      penName: normalizeString(data.penName) || null,
      photoURL: normalizeString(data.photoURL) || null,
      followersCount: Number(data.followersCount || 0),
    };
  });

  const recommendationStats = {};
  for (const doc of booksSnapshot?.docs || []) {
    const data = doc.data() || {};
    recommendationStats[doc.id] = {
      recommendationCount: 0,
      upvotes: Number(data.viewCount || 0),
      downvotes: 0,
    };
  }

  const dailyTopics = (topicsSnapshot?.docs || []).map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
  const homeBanners = (bannersSnapshot?.docs || []).map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  await db.collection("settings").doc("homepage_metadata").set({
    authors,
    dailyTopics,
    homeBanners,
    recommendationStats,
    lastRefreshedAt: Date.now(),
  }, {merge: true});

  logger.info("Homepage metadata refreshed", {
    authorCount: authors.length,
    bookCount: Object.keys(recommendationStats).length,
    topicCount: dailyTopics.length,
    bannerCount: homeBanners.length,
  });
}

exports.refreshHomepageMetadata = functionsV1.pubsub.schedule("every 24 hours").onRun(async () => {
  await refreshHomepageMetadataInternal();
  return null;
});

exports.onDailyTopicWrite = functionsV1.firestore
    .document("daily-topics/{topicId}")
    .onWrite(async () => {
      await refreshHomepageMetadataInternal();
      return null;
    });

exports.onHomeBannerWrite = functionsV1.firestore
    .document("home-banners/{bannerId}")
    .onWrite(async () => {
      await refreshHomepageMetadataInternal();
      return null;
    });

exports.manualRefreshHomepage = functionsV1.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functionsV1.https.HttpsError("unauthenticated", "User must be logged in.");
  }
  await refreshHomepageMetadataInternal();
  return {success: true, message: "Homepage metadata refreshed successfully."};
});
