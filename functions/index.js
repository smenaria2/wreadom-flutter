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
const AUTHOR_READ_MILESTONES = [
  100,
  500,
  1000,
  5000,
  10000,
  25000,
  50000,
  100000,
  500000,
  1000000,
  5000000,
  10000000,
];
const SYSTEM_ACTOR_ID = "wreadom";
const SYSTEM_ACTOR_NAME = "Wreadom";
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

function isAdminContext(context) {
  const token = context.auth?.token || {};
  return token.admin === true || normalizeString(token.email) === "smenaria2@gmail.com";
}

function requireAdminContext(context) {
  if (!context.auth?.uid) {
    throw new functionsV1.https.HttpsError("unauthenticated", "User must be logged in.");
  }
  if (!isAdminContext(context)) {
    throw new functionsV1.https.HttpsError("permission-denied", "Administrator privileges required.");
  }
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

function contentRecommendationLink(bookId) {
  return `https://wreadom.in/?book=${encodeURIComponent(bookId)}`;
}

async function validateAdminContentNotificationRequest(data = {}) {
  const bookId = normalizeString(data.bookId);
  const title = normalizeString(data.title);
  const message = normalizeString(data.message);
  const userIds = Array.isArray(data.userIds) ?
    Array.from(new Set(data.userIds.map((value) => normalizeString(value)).filter(Boolean))) :
    [];

  if (!bookId) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Missing bookId.");
  }
  if (!title || title.length > 80) {
    throw new functionsV1.https.HttpsError(
        "invalid-argument",
        "Title must be between 1 and 80 characters.",
    );
  }
  if (!message || message.length > 500) {
    throw new functionsV1.https.HttpsError(
        "invalid-argument",
        "Message must be between 1 and 500 characters.",
    );
  }
  if (userIds.length === 0) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Select at least one recipient.");
  }
  if (userIds.length > 1000) {
    throw new functionsV1.https.HttpsError(
        "invalid-argument",
        "Select 1000 recipients or fewer per send.",
    );
  }

  const bookSnapshot = await db.collection("books").doc(bookId).get();
  if (!bookSnapshot.exists) {
    throw new functionsV1.https.HttpsError("not-found", "Selected content was not found.");
  }
  const book = bookSnapshot.data() || {};
  if (normalizeString(book.status).toLowerCase() !== "published") {
    throw new functionsV1.https.HttpsError(
        "failed-precondition",
        "Only published content can be recommended.",
    );
  }

  return {
    bookId,
    title,
    message,
    link: contentRecommendationLink(bookId),
    userIds,
  };
}

async function createAdminContentRecommendationNotifications({
  bookId,
  title,
  message,
  link,
  createdBy,
  userIds,
}) {
  let created = 0;
  let skipped = 0;

  const results = await Promise.all(
    userIds.map(async (userId) => {
      try {
        const userDoc = await db.collection("users").doc(userId).get();
        const user = userDoc.exists ? userDoc.data() || {} : null;
        if (!user || user.isDeactivated === true) {
          return "skipped";
        }

        const notificationId = db.collection("notifications").doc().id;
        const notificationData = buildNotification({
          userId,
          actorId: "system",
          actorName: title,
          actorPhotoURL: null,
          type: "new_creation",
          text: message,
          link,
          targetId: bookId,
          metadata: {
            source: "admin_content_recommendation",
            bookId,
            contentId: bookId,
            targetType: "book",
            createdBy,
            selectedRecipient: true,
          },
        });

        await sendPushNotificationToUser(userId, notificationData, notificationId);
        return "created";
      } catch (err) {
        logger.error(`Failed to send recommendation push notification to user ${userId}:`, err);
        return "skipped";
      }
    })
  );

  for (const r of results) {
    if (r === "created") {
      created += 1;
    } else {
      skipped += 1;
    }
  }

  return {created, skipped};
}

function notificationValue(...values) {
  for (const value of values) {
    const normalized = normalizeString(value);
    if (normalized) return normalized;
  }
  return "";
}

function textLooksLikeBookComment(text) {
  const normalized = text.toLowerCase();
  return normalized === "commented on your content" ||
    normalized.startsWith("commented on your book:") ||
    normalized.includes(" has commented on ");
}

function isSupersededBookCommentNotification(
    docId,
    data,
    ownerId,
    actorId,
    bookId,
    commentId,
    keepDocId,
) {
  if (docId === keepDocId) return false;
  if (notificationValue(data.userId) !== ownerId) return false;
  if (notificationValue(data.actorId) !== actorId) return false;

  const type = notificationValue(data.type).toLowerCase();
  const text = notificationValue(data.text);
  if (type !== "book_comment" && type !== "comment" && !textLooksLikeBookComment(text)) {
    return false;
  }

  const metadata = data.metadata || {};
  const targetId = notificationValue(data.targetId);
  const link = notificationValue(data.link);
  const metadataBookId = notificationValue(metadata.bookId, data.bookId);
  const metadataCommentId = notificationValue(metadata.commentId, data.commentId);

  const bookMatches = metadataBookId === bookId ||
    targetId === bookId ||
    (bookId && link.includes(bookId));
  const commentMatches = metadataCommentId === commentId ||
    targetId === commentId ||
    (commentId && (link.includes(commentId) || docId.includes(commentId)));

  return bookMatches && commentMatches;
}

async function deleteSupersededBookCommentNotifications(
    ownerId,
    actorId,
    bookId,
    commentId,
    keepDocId,
) {
  if (!ownerId || !actorId || !bookId || !commentId) return;

  const snapshot = await db.collection("notifications")
      .where("userId", "==", ownerId)
      .limit(200)
      .get()
      .catch(() => null);
  if (!snapshot) return;

  const batch = db.batch();
  let deletes = 0;
  snapshot.docs.forEach((doc) => {
    if (isSupersededBookCommentNotification(
        doc.id,
        doc.data(),
        ownerId,
        actorId,
        bookId,
        commentId,
        keepDocId,
    )) {
      batch.delete(doc.ref);
      deletes += 1;
    }
  });

  if (deletes > 0) {
    await batch.commit();
  }
}

function shouldSendPushNotification(beforeData, afterData) {
  if (!afterData) {
    return false;
  }
  if (afterData.metadata?.suppressPush === true) {
    return false;
  }
  if (!beforeData) {
    return true;
  }
  return beforeData.timestamp !== afterData.timestamp &&
    (
      beforeData.type !== afterData.type ||
      beforeData.text !== afterData.text ||
      beforeData.link !== afterData.link ||
      beforeData.targetId !== afterData.targetId
    );
}

function registryWithoutToken(rawRegistry, token) {
  return Array.isArray(rawRegistry) ?
    rawRegistry.filter((item) => normalizeString(item?.token) !== token) :
    [];
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

function integerValue(value) {
  const number = Number(value);
  return Number.isFinite(number) ? Math.trunc(number) : 0;
}

function bookReadCount(data = {}) {
  return Math.max(
      0,
      integerValue(data.viewCount ?? data.readCount ?? data.reads ?? data.views),
  );
}

function formatMilestoneCount(value) {
  const text = `${Math.max(0, integerValue(value))}`;
  return text.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function authorReadMilestoneNotificationText(milestone) {
  return `Congratulations! Your works reached ${formatMilestoneCount(milestone)} reads.`;
}

function crossedAuthorReadMilestones(previousTotal, nextTotal) {
  const previous = Math.max(0, integerValue(previousTotal));
  const next = Math.max(previous, integerValue(nextTotal));
  return AUTHOR_READ_MILESTONES.filter((milestone) =>
    milestone > previous && milestone <= next,
  );
}

function localizedPushBody(data = {}, userData = {}) {
  const language = normalizeString(userData.preferredLanguage).toLowerCase();
  if (language !== "hi" && language !== "hindi") {
    return data.text || "";
  }

  const type = normalizeString(data.type).toLowerCase();
  const text = normalizeString(data.text).toLowerCase();
  if (type === "follow" || text === "started following you") {
    return "ने आपको फ़ॉलो करना शुरू किया।";
  }
  if (type === "post_like" || text === "liked your post") {
    return "ने आपकी पोस्ट को पसंद किया।";
  }
  if (type === "feed_comment" || text === "commented on your post") {
    return "ने आपकी पोस्ट पर टिप्पणी की।";
  }
  if (type === "feed_reply" || text === "replied to your comment") {
    return "ने आपकी टिप्पणी का जवाब दिया।";
  }
  if (type === "book_reply" || text === "replied to your discussion") {
    const detailed = localizedHindiBookReplyPushBody(data);
    if (detailed) return detailed;
    return "ने आपकी रचना वाली टिप्पणी का जवाब दिया।";
  }
  if (type === "book_comment" || text === "commented on your content") {
    const detailed = localizedHindiBookCommentPushBody(data);
    if (detailed) return detailed;
    return "ने आपकी रचना पर टिप्पणी की।";
  }
  if (type === "book_review" ||
      text === "left a review on your content" ||
      text === "submitted an audio review on your content") {
    const detailed = localizedHindiBookReviewPushBody(data);
    if (detailed) return detailed;
    return "ने आपकी रचना की समीक्षा की।";
  }
  if (type === "new_creation" || type === "published") {
    const detailed = localizedHindiPublishedPushBody(data);
    if (detailed) return detailed;
  }
  if (type === "chapter_update") {
    const detailed = localizedHindiChapterUpdatePushBody(data);
    if (detailed) return detailed;
  }
  if (type === "message") {
    return text === "sent you a book" ?
      "ने आपको रचना भेजी।" :
      "ने आपको संदेश भेजा।";
  }
  if (type === "collaboration_request") {
    return "आपके साथ सहलेखन करना चाहते हैं।";
  }
  if (type === "collaboration_removed") {
    return text.includes("removed themselves") ?
      "ने खुद को सहलेखक से हटाया।" :
      "ने आपको सहलेखक से हटाया।";
  }
  return data.text || "";
}

function localizedHindiBookReplyPushBody(data = {}) {
  const title = firstQuotedValueAfter(data.text, "has replied to your review on");
  return title ? `ने "${title}" पर आपकी समीक्षा का जवाब दिया।` : null;
}

function localizedHindiBookCommentPushBody(data = {}) {
  const title = firstQuotedValueAfter(data.text, "has commented on");
  return title ? `ने "${title}" पर टिप्पणी की।` : null;
}

function localizedHindiBookReviewPushBody(data = {}) {
  const sourceText = normalizeString(data.text);
  const chapterMatch = sourceText.match(/^.+?\s+has left a review on\s+(?:chapter\s+)?['"]([^'"]+)['"]\s+of\s+[^'"]+['"]([^'"]+)['"]\.?$/i);
  if (chapterMatch) {
    return `ने "${chapterMatch[2].trim()}" के अध्याय "${chapterMatch[1].trim()}" की समीक्षा की।`;
  }
  const title = firstQuotedValueAfter(sourceText, "has left a review on");
  return title ? `ने "${title}" की समीक्षा की।` : null;
}

function localizedHindiPublishedPushBody(data = {}) {
  const title = firstQuotedValueAfter(data.text, "has published");
  return title ? `ने "${title}" प्रकाशित की।` : null;
}

function localizedHindiChapterUpdatePushBody(data = {}) {
  const match = normalizeString(data.text).match(/^.+?\s+has published a new chapter\s+['"]([^'"]+)['"]\s+to\s+[^'"]+['"]([^'"]+)['"]\.?$/i);
  if (!match) return null;
  return `ने "${match[2].trim()}" में अध्याय "${match[1].trim()}" प्रकाशित किया।`;
}

function firstQuotedValueAfter(text, marker) {
  const match = normalizeString(text).match(
      new RegExp(`${escapeRegExp(marker)}[^'"]*['"]([^'"]+)['"]`, "i"),
  );
  return match ? match[1].trim() : null;
}

function escapeRegExp(value) {
  return `${value}`.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function pushDataFromNotification(data = {}, notificationId = "") {
  const metadata = data.metadata && typeof data.metadata === "object" ?
    data.metadata :
    {};
  const navigationUrl = pushNavigationUrl(data, metadata);
  const pushData = {
    notificationId,
    url: navigationUrl,
    link: normalizeString(data.link) || "",
    type: normalizeString(data.type),
    text: normalizeString(data.text),
    userId: normalizeString(data.userId),
    actorId: normalizeString(data.actorId),
    actorName: normalizeString(data.actorName),
    targetId: normalizeString(data.targetId),
  };

  for (const key of [
    "bookId",
    "book",
    "contentId",
    "postId",
    "feedPostId",
    "feedId",
    "commentId",
    "parentCommentId",
    "targetCommentId",
    "replyId",
    "targetReplyId",
    "conversationId",
    "targetType",
  ]) {
    const value = normalizeString(metadata[key]);
    if (value) {
      pushData[key] = value;
    }
  }

  return Object.fromEntries(
      Object.entries(pushData).filter(([, value]) => normalizeString(value)),
  );
}

function firstPushValue(data = {}, metadata = {}, keys = []) {
  for (const key of keys) {
    const value = normalizeString(metadata[key]) || normalizeString(data[key]);
    if (value) return value;
  }
  return "";
}

function pushNavigationUrl(data = {}, metadata = {}) {
  const type = normalizeString(data.type).toLowerCase();
  const targetId = normalizeString(data.targetId);
  const bookId = firstPushValue(data, metadata, ["bookId", "book", "contentId"]);
  const postId = firstPushValue(data, metadata, ["postId", "feedPostId", "feedId"]);
  const commentId = firstPushValue(data, metadata, ["commentId", "parentCommentId", "targetCommentId"]);
  const replyId = firstPushValue(data, metadata, ["replyId", "targetReplyId"]);
  const conversationId = firstPushValue(data, metadata, ["conversationId"]);
  const query = new URLSearchParams();

  if ((type === "message" || type === "groupmessage") && (conversationId || targetId)) {
    return `/messages/${encodeURIComponent(conversationId || targetId)}`;
  }
  if ((type.includes("feed") || type.includes("post")) && (postId || targetId)) {
    query.set("page", "feed");
    query.set("post", postId || targetId);
    if (commentId) query.set("comment", commentId);
    if (replyId) query.set("reply", replyId);
    return `/?${query.toString()}`;
  }
  if (
    (
      type.includes("book") ||
      type === "published" ||
      type === "chapter_update" ||
      type === "new_creation" ||
      type === "comment" ||
      type === "reply" ||
      type === "mention"
    ) &&
    (bookId || targetId)
  ) {
    query.set("book", bookId || targetId);
    if (commentId) query.set("comment", commentId);
    if (replyId) query.set("reply", replyId);
    return `/?${query.toString()}`;
  }

  return normalizeString(data.link) || "/";
}

async function notifyBookOwnersForBookActivity(commentId, data = {}) {
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
  const rating = Number(data.rating || 0);
  const isReview = rating > 0;
  const isAudioReview = isReview &&
    (normalizeString(data.audioObjectKey) || normalizeString(data.audioUrl));
  const notificationType = isReview ? "book_review" : "book_comment";
  const ownerIds = acceptedBookAuthorIds(book);
  const actorName = userDisplayName(data);
  for (const ownerId of ownerIds) {
    const notificationDocId = `book_comment_${commentId}_${ownerId}`;
    await createNotificationDoc(
        notificationDocId,
        buildNotification({
          userId: ownerId,
          actorId,
          actorName,
          actorPhotoURL: normalizeString(data.userPhotoURL) || null,
          type: notificationType,
          text: isAudioReview ?
            reviewNotificationText(actorName, book, data) :
            isReview ? reviewNotificationText(actorName, book, data) :
              `${actorName} has commented on ${contentTypeLabel(book)} "${contentTitle(book)}".`,
          link: `/book?id=${bookId}`,
          targetId: bookId,
          metadata: {
            bookId,
            commentId,
            hasAudio: Boolean(isAudioReview),
            contentType: contentTypeLabel(book),
            contentTitle: contentTitle(book),
            chapterId: normalizeString(data.chapterId) || null,
            chapterTitle: normalizeString(data.chapterTitle) || null,
          },
        }),
    );
    await deleteNotificationDoc(`book_audio_review_${commentId}_${ownerId}`);
    if (isReview) {
      await deleteSupersededBookCommentNotifications(
          ownerId,
          actorId,
          bookId,
          commentId,
          notificationDocId,
      );
    }
  }
}

async function sendPushNotificationToUser(userId, data, notificationId = "") {
  const userDocRef = admin.firestore().doc(`users/${userId}`);
  const userDoc = await userDocRef.get();
  if (!userDoc.exists) {
    logger.info(`User document not found for ID: ${userId}`);
    return;
  }

  const userData = userDoc.data() || {};
  const notifSettings = userData.notificationSettings;
  const typeToSettingKey = {
    message: "messages",
    groupMessage: "groupMessages",
    comment: "comments",
    reply: "replies",
    follower: "followers",
    testimonial: "testimonials",
    like: "likes",
    feedPost: "followedAuthorPosts",
    new_creation: "newCreations",
    published: "newCreations",
    chapter_update: "newCreations",
    mention: "comments",
    feed_comment: "comments",
    book_comment: "comments",
    book_review: "comments",
    feed_reply: "replies",
    book_reply: "replies",
  };
  const settingKey = typeToSettingKey[data.type];

  const legacyTokens = Array.isArray(userData.fcmTokens) ?
    userData.fcmTokens.map((token) => normalizeString(token)).filter(Boolean) :
    [];
  const registryEntries = Array.isArray(userData.fcmTokenRegistry) ?
    userData.fcmTokenRegistry
        .map((entry) => ({
          token: normalizeString(entry?.token),
          platform: normalizeString(entry?.platform).toLowerCase() || "web",
        }))
        .filter((entry) => entry.token) :
    [];
  const registeredTokens = new Set(registryEntries.map((entry) => entry.token));
  const candidateEntries = [
    ...registryEntries,
    ...legacyTokens
        .filter((token) => !registeredTokens.has(token))
        .map((token) => ({token, platform: "web"})),
  ];

  const allowedTokens = candidateEntries
      .filter((entry) => {
        const isNative = ["android", "ios"].includes(entry.platform);
        const preference = settingKey ? notifSettings?.[settingKey] : null;
        if (isNative) {
          return preference?.app !== false;
        }
        if (notifSettings?.browserNotifications === false) {
          return false;
        }
        return !settingKey || preference?.browser !== false;
      })
      .map((entry) => entry.token);
  const uniqueTokens = Array.from(new Set(allowedTokens));
  if (uniqueTokens.length === 0) {
    logger.info("No FCM tokens found for user:", userId);
    return;
  }

  const notificationTitle = normalizeString(data.actorName) || "Wreadom";
  const notificationBody = localizedPushBody(data, userData);

  const message = {
    tokens: uniqueTokens,
    notification: {
      title: notificationTitle,
      body: notificationBody,
    },
    webpush: {
      fcmOptions: {
        link: data.link || "/",
      },
      notification: {
        icon: "https://wreadom.in/logo%20192x192.png",
        badge: "https://wreadom.in/logo-32x32.png",
        tag: notificationId,
      },
    },
    data: pushDataFromNotification(data, notificationId),
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(
        `FCM: ${response.successCount} sent, ${response.failureCount} failed out of ${uniqueTokens.length} token(s).`,
    );

    const staleTokens = [];
    response.responses.forEach((resp, idx) => {
      if (
        !resp.success &&
        resp.error &&
        (
          resp.error.code === "messaging/registration-token-not-registered" ||
          resp.error.code === "messaging/invalid-registration-token"
        )
      ) {
        staleTokens.push(uniqueTokens[idx]);
      }
    });

    if (staleTokens.length > 0) {
      logger.info("FCM: Removing stale tokens:", staleTokens);
      const updates = {
        fcmTokens: FieldValue.arrayRemove(...staleTokens),
      };
      if (Array.isArray(userData.fcmTokenRegistry)) {
        updates.fcmTokenRegistry = userData.fcmTokenRegistry.filter((entry) => {
          return !staleTokens.includes(normalizeString(entry?.token));
        });
      }
      await userDocRef.update(updates);
    }
  } catch (error) {
    logger.error("Error sending FCM push notification:", error);
  }
}

exports.sendPushNotification = functionsV1.firestore.document("notifications/{notificationId}").onWrite(async (change, context) => {
  const beforeData = change.before.exists ? change.before.data() : undefined;
  const data = change.after.exists ? change.after.data() : undefined;
  if (!shouldSendPushNotification(beforeData, data)) {
    return;
  }
  if (!data) {
    return;
  }

  await sendPushNotificationToUser(data.userId, data, context.params.notificationId);
});

exports.claimFcmToken = functionsV1.https.onCall(async (data, context) => {
  const uid = normalizeString(context.auth?.uid);
  const token = normalizeString(data?.token);
  const platform = normalizeString(data?.platform) || "unknown";
  if (!uid) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Authentication required.");
  }
  if (!token) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Missing FCM token.");
  }

  const existing = await db.collection("users").where("fcmTokens", "array-contains", token).get();
  const batch = db.batch();
  for (const doc of existing.docs) {
    if (doc.id === uid) continue;
    batch.set(doc.ref, {
      fcmTokens: FieldValue.arrayRemove(token),
      fcmTokenRegistry: registryWithoutToken(doc.data()?.fcmTokenRegistry, token),
    }, {merge: true});
  }

  const userRef = db.collection("users").doc(uid);
  const userSnapshot = await userRef.get();
  const registry = registryWithoutToken(userSnapshot.data()?.fcmTokenRegistry, token);
  registry.unshift({
    token,
    platform,
    updatedAt: Date.now(),
  });
  batch.set(userRef, {
    fcmTokens: FieldValue.arrayUnion(token),
    fcmTokenRegistry: registry.slice(0, 10),
  }, {merge: true});
  await batch.commit();
  return {ok: true};
});

exports.removeFcmToken = functionsV1.https.onCall(async (data, context) => {
  const uid = normalizeString(context.auth?.uid);
  const token = normalizeString(data?.token);
  if (!uid) {
    throw new functionsV1.https.HttpsError("unauthenticated", "Authentication required.");
  }
  if (!token) {
    throw new functionsV1.https.HttpsError("invalid-argument", "Missing FCM token.");
  }

  const userRef = db.collection("users").doc(uid);
  const snapshot = await userRef.get();
  await userRef.set({
    fcmTokens: FieldValue.arrayRemove(token),
    fcmTokenRegistry: registryWithoutToken(snapshot.data()?.fcmTokenRegistry, token),
  }, {merge: true});
  return {ok: true};
});

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

function acceptedBookAuthorIds(book = {}) {
  const ids = new Set();
  const primaryId = normalizeString(book.authorId);
  if (primaryId) {
    ids.add(primaryId);
  }
  const status = normalizeString(book.collaborationStatus).toLowerCase();
  const collaboratorId = normalizeString(book.collaboratorId);
  if (status === "accepted") {
    if (Array.isArray(book.authorIds)) {
      for (const id of book.authorIds.map((value) => normalizeString(`${value}`))) {
        if (id) ids.add(id);
      }
    }
    if (collaboratorId) {
      ids.add(collaboratorId);
    }
  }
  return Array.from(ids);
}

async function authorReadTotal(authorId) {
  const normalizedAuthorId = normalizeString(authorId);
  if (!normalizedAuthorId) {
    return 0;
  }

  const books = new Map();
  const [primarySnapshot, collaborativeSnapshot] = await Promise.all([
    db.collection("books").where("authorId", "==", normalizedAuthorId).get(),
    db.collection("books").where("authorIds", "array-contains", normalizedAuthorId).get(),
  ]);

  for (const doc of primarySnapshot.docs) {
    books.set(doc.id, doc.data());
  }
  for (const doc of collaborativeSnapshot.docs) {
    books.set(doc.id, doc.data());
  }

  let total = 0;
  for (const data of books.values()) {
    total += bookReadCount(data);
  }
  return total;
}

async function createAuthorReadMilestones(authorId, totalAfterRead) {
  const normalizedAuthorId = normalizeString(authorId);
  if (!normalizedAuthorId) {
    return [];
  }

  const statsRef = db.collection("author_read_stats").doc(normalizedAuthorId);
  const createdMilestones = [];
  await db.runTransaction(async (transaction) => {
    const statsSnapshot = await transaction.get(statsRef);
    const existingTotal = statsSnapshot.exists ?
      bookReadCount({viewCount: statsSnapshot.data()?.totalReads}) :
      null;
    const nextTotal = Math.max(existingTotal ?? 0, integerValue(totalAfterRead));
    const previousTotal = existingTotal ?? Math.max(0, nextTotal - 1);
    const milestones = crossedAuthorReadMilestones(previousTotal, nextTotal);

    transaction.set(statsRef, {
      totalReads: nextTotal,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    for (const milestone of milestones) {
      const notificationRef = db
          .collection("notifications")
          .doc(`author_read_milestone_${normalizedAuthorId}_${milestone}`);
      transaction.set(notificationRef, buildNotification({
        userId: normalizedAuthorId,
        actorId: SYSTEM_ACTOR_ID,
        actorName: SYSTEM_ACTOR_NAME,
        type: "author_read_milestone",
        text: authorReadMilestoneNotificationText(milestone),
        targetId: normalizedAuthorId,
        metadata: {
          milestone,
          totalReads: nextTotal,
          targetType: "author_read_milestone",
          suppressPush: true,
        },
      }), {merge: true});
      createdMilestones.push(milestone);
    }
  });
  return createdMilestones;
}

async function createAuthorReadMilestonesForBookView(bookId) {
  const normalizedBookId = normalizeString(bookId);
  if (!normalizedBookId) {
    return [];
  }

  const bookSnapshot = await db.collection("books").doc(normalizedBookId).get();
  if (!bookSnapshot.exists) {
    return [];
  }

  const authorIds = acceptedBookAuthorIds(bookSnapshot.data());
  const results = [];
  for (const authorId of authorIds) {
    const totalAfterRead = await authorReadTotal(authorId);
    const milestones = await createAuthorReadMilestones(authorId, totalAfterRead);
    if (milestones.length > 0) {
      results.push({authorId, milestones});
    }
  }
  return results;
}

function contentTypeLabel(data = {}) {
  return normalizeString(data.contentType).toLowerCase() || "content";
}

function contentTitle(data = {}) {
  return normalizeString(data.title) || normalizeString(data.bookTitle) || "Untitled";
}

function chapterTitle(chapter = {}, fallbackIndex = 0) {
  return normalizeString(chapter.title) || `Chapter ${fallbackIndex + 1}`;
}

function isBookPublished(data = {}) {
  return normalizeString(data.status).toLowerCase() === "published";
}

function isChapterPublished(chapter = {}, parentIsPublished = false) {
  const status = normalizeString(chapter?.status).toLowerCase();
  if (!status) {
    return parentIsPublished;
  }
  return status === "published";
}

function publishedChapters(data = {}) {
  const parentIsPublished = isBookPublished(data);
  return Array.isArray(data.chapters) ?
    data.chapters.filter((chapter) => isChapterPublished(chapter, parentIsPublished)) :
    [];
}

function chapterKey(chapter = {}, index = 0) {
  return normalizeString(chapter.id) ||
    `legacy_${chapterTitle(chapter, index).toLowerCase()}_${index}`;
}

function notificationDocSegment(value) {
  return normalizeString(value)
      .replace(/[/.#[\]]+/g, "_")
      .replace(/\s+/g, "_") ||
    "chapter";
}

function diffAddedPublishedChapters(beforeData = {}, afterData = {}) {
  const before = publishedChapters(beforeData);
  const after = publishedChapters(afterData);
  if (after.length <= before.length) {
    return [];
  }
  const beforeKeys = new Set(before.map(chapterKey));
  return after.filter((chapter, index) => !beforeKeys.has(chapterKey(chapter, index)));
}

function chapterForComment(book = {}, data = {}) {
  const chapters = publishedChapters(book);
  const chapterId = normalizeString(data.chapterId);
  if (chapterId) {
    const byId = chapters.find((chapter) => normalizeString(chapter?.id) === chapterId);
    if (byId) return byId;
  }
  const chapterIndex = Number.parseInt(`${data.chapterIndex ?? ""}`, 10);
  if (!Number.isNaN(chapterIndex) && chapters[chapterIndex]) {
    return chapters[chapterIndex];
  }
  if (normalizeString(data.chapterTitle)) {
    return {title: normalizeString(data.chapterTitle)};
  }
  return chapters[0] || {};
}

function reviewNotificationText(actorName, book, data = {}) {
  const type = contentTypeLabel(book);
  const title = contentTitle(book);
  if (publishedChapters(book).length > 1) {
    const chapter = chapterForComment(book, data);
    return `${actorName} has left a review on '${chapterTitle(chapter, Number(data.chapterIndex || 0))}' of ${type} '${title}'.`;
  }
  return `${actorName} has left a review on ${type} '${title}'.`;
}

function publishedBookNotificationText(actorName, book = {}) {
  return `${actorName} has published a ${contentTypeLabel(book)} '${contentTitle(book)}'.`;
}

function newChapterNotificationText(actorName, book = {}, chapter = {}, fallbackIndex = 0) {
  return `${actorName} has published a new chapter '${chapterTitle(chapter, fallbackIndex)}' to ${contentTypeLabel(book)} '${contentTitle(book)}'.`;
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
  const type = contentTypeLabel(afterData);

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
          text: publishedBookNotificationText(actorName, afterData),
          link: `/book?id=${bookId}`,
          targetId: bookId,
          metadata: {bookId, contentType: type},
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

async function notifyFollowersForNewChapter(bookId, beforeData, afterData) {
  const authorId = normalizeString(afterData.authorId);
  if (!authorId) {
    return;
  }
  const addedChapters = diffAddedPublishedChapters(beforeData, afterData);
  if (addedChapters.length === 0) {
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
  const type = contentTypeLabel(afterData);
  const afterPublishedChapters = publishedChapters(afterData);

  const writes = followersSnapshot.docs
      .map((doc) => normalizeString(doc.data().followerId))
      .filter((userId) => userId && userId !== authorId)
      .flatMap((userId) => addedChapters.map((chapter) => {
        const chapterIndex = afterPublishedChapters.indexOf(chapter);
        const chapterName = chapterTitle(chapter, chapterIndex);
        return {
          ref: db.collection("notifications").doc(
              `chapter_update_${bookId}_${notificationDocSegment(chapterKey(chapter, chapterIndex))}_${userId}`,
          ),
          data: buildNotification({
            userId,
            actorId: authorId,
            actorName,
            actorPhotoURL,
            type: "chapter_update",
            text: newChapterNotificationText(actorName, afterData, chapter, chapterIndex),
            link: `/book?id=${bookId}`,
            targetId: bookId,
            metadata: {bookId, contentType: type, chapterId: normalizeString(chapter.id) || null, chapterTitle: chapterName},
          }),
        };
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

exports.onRecommendationWrite = functionsV1.firestore.document("recommendations/{recommendationId}").onWrite(async (change, context) => {
  const beforeData = change.before.exists ? change.before.data() : null;
  const afterData = change.after.exists ? change.after.data() : null;
  const bookId = normalizeString(afterData?.bookId || beforeData?.bookId);
  if (!bookId) {
    logger.warn("No bookId found in recommendation change:", context.params.recommendationId);
    return null;
  }

  let upDelta = 0;
  let downDelta = 0;
  const oldType = normalizeString(beforeData?.type).toLowerCase();
  const newType = normalizeString(afterData?.type).toLowerCase();

  if (oldType === "up") upDelta -= 1;
  if (oldType === "down") downDelta -= 1;
  if (newType === "up") upDelta += 1;
  if (newType === "down") downDelta += 1;
  if (upDelta === 0 && downDelta === 0) {
    return null;
  }

  const recommendationDelta = upDelta - downDelta;
  const statsRef = db.collection("book_stats").doc(bookId);
  const metadataRef = db.collection("settings").doc("homepage_metadata");

  await db.runTransaction(async (transaction) => {
    const [statsSnapshot, metadataSnapshot] = await Promise.all([
      transaction.get(statsRef),
      transaction.get(metadataRef),
    ]);
    const currentStats = statsSnapshot.exists ? statsSnapshot.data() || {} : {};
    const upvotes = Math.max(0, Number(currentStats.upvotes || 0) + upDelta);
    const downvotes = Math.max(0, Number(currentStats.downvotes || 0) + downDelta);
    const recommendationCount = upvotes - downvotes;
    const viewCount = Number(currentStats.viewCount || 0);
    const nextStats = {
      upvotes,
      downvotes,
      recommendationCount,
      viewCount,
    };

    transaction.set(statsRef, nextStats, {merge: true});
    if (upvotes > 0) {
      transaction.set(metadataRef, {
        recommendationStats: {
          [bookId]: nextStats,
        },
      }, {merge: true});
    } else if (metadataSnapshot.exists) {
      transaction.update(
          metadataRef,
          new admin.firestore.FieldPath("recommendationStats", bookId),
          FieldValue.delete(),
      );
    }
  });
  logger.info("Updated book_stats recommendation counters", {
    bookId,
    upDelta,
    downDelta,
    recommendationDelta,
  });
  return null;
});

exports.onBookViewCreate = functionsV1.firestore.document("books/{bookId}/views/{viewId}").onCreate(async (snapshot, context) => {
  const bookId = normalizeString(context.params.bookId);
  if (!bookId) {
    return null;
  }

  await db.collection("book_stats").doc(bookId).set({
    viewCount: FieldValue.increment(1),
  }, {merge: true});
  logger.info("Incremented book_stats viewCount", {bookId});
  const milestoneResults = await createAuthorReadMilestonesForBookView(bookId);
  if (milestoneResults.length > 0) {
    logger.info("Created author read milestone notifications", {
      bookId,
      milestoneResults,
    });
  }
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
              metadata: {postId: feedPostId, commentId},
            }),
        );
      }
    }

    const bookId = normalizeString(`${afterData.bookId ?? ""}`);
    if (bookId) {
      await notifyBookOwnersForBookActivity(commentId, afterData);
    }
  }

  if (beforeData && afterData) {
    const beforeRating = Number(beforeData.rating || 0);
    const afterRating = Number(afterData.rating || 0);
    if (beforeRating <= 0 && afterRating > 0) {
      await notifyBookOwnersForBookActivity(commentId, afterData);
    }

    const beforeReplies = Array.isArray(beforeData.replies) ? beforeData.replies : [];
    const afterReplies = Array.isArray(afterData.replies) ? afterData.replies : [];
    for (const reply of diffAddedReplies(beforeReplies, afterReplies)) {
      const actorId = normalizeString(reply.userId);
      const targetBookId = normalizeString(`${afterData.bookId ?? ""}`);
      let book = null;
      if (targetBookId) {
        const bookSnapshot = await db.collection("books").doc(targetBookId).get();
        book = bookSnapshot.exists ? bookSnapshot.data() || {} : null;
      }
      const actorName = userDisplayName(reply);
      await createNotificationDoc(
          `reply_${commentId}_${replyIdentifier(reply)}`,
          buildNotification({
            userId: normalizeString(afterData.userId),
            actorId,
            actorName,
            actorPhotoURL: normalizeString(reply.userPhotoURL) || null,
            type: normalizeString(afterData.feedPostId) ? "feed_reply" : "book_reply",
            text: normalizeString(afterData.feedPostId) ?
              `${actorName} has replied to your comment.` :
              `${actorName} has replied to your review on "${contentTitle(book || afterData)}".`,
            link: normalizeString(afterData.feedPostId) ? `/post?id=${normalizeString(afterData.feedPostId)}` : `/book?id=${targetBookId}`,
            targetId: normalizeString(afterData.feedPostId) || targetBookId || null,
            metadata: {
              commentId,
              replyId: replyIdentifier(reply) || null,
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
  await notifyBookOwnersForBookActivity(commentId, data);
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
  if (wasPublished && isPublished) {
    await notifyFollowersForNewChapter(context.params.bookId, beforeData || {}, afterData);
  }
  const beforeCollaboratorId = normalizeString(beforeData?.collaboratorId);
  const afterCollaboratorId = normalizeString(afterData.collaboratorId);
  const beforeCollabStatus = normalizeString(beforeData?.collaborationStatus).toLowerCase();
  const afterCollabStatus = normalizeString(afterData.collaborationStatus).toLowerCase();
  if (
    beforeCollaboratorId &&
    beforeCollabStatus === "pending" &&
    (afterCollaboratorId !== beforeCollaboratorId || afterCollabStatus !== "pending")
  ) {
    await deleteNotificationDoc(`collaboration_request_${context.params.bookId}_${beforeCollaboratorId}`);
  }
  if (
    beforeCollaboratorId &&
    beforeCollabStatus === "accepted" &&
    (!afterCollaboratorId || afterCollabStatus !== "accepted")
  ) {
    const authorId = normalizeString(beforeData?.authorId);
    const removedBy = normalizeString(afterData.collaborationRemovedBy);
    const actorId = removedBy || authorId;
    const recipientId = actorId === beforeCollaboratorId ? authorId : beforeCollaboratorId;
    if (actorId && recipientId && actorId !== recipientId) {
      const actorData = await getUserDoc(actorId);
      const actorName = userDisplayName(actorData || {});
      await createNotificationDoc(
          `collaboration_removed_${context.params.bookId}_${recipientId}_${normalizeString(afterData.collaborationRemovedAt) || Date.now()}`,
          buildNotification({
            userId: recipientId,
            actorId,
            actorName,
            actorPhotoURL: normalizeString(actorData?.photoURL) || null,
            type: "collaboration_removed",
            text: actorId === authorId ?
              `${actorName} removed you as co-author.` :
              `${actorName} removed themselves as co-author.`,
            link: `/book?id=${context.params.bookId}`,
            targetId: context.params.bookId,
            metadata: {
              bookId: context.params.bookId,
              removedCollaboratorId: beforeCollaboratorId,
              removedBy: actorId,
            },
          }),
      );
    }
  }
  if (
    afterCollaboratorId &&
    afterCollabStatus === "pending" &&
    (beforeCollaboratorId !== afterCollaboratorId || beforeCollabStatus !== "pending")
  ) {
    const authorId = normalizeString(afterData.authorId);
    const authorData = await getUserDoc(authorId);
    const actorName = userDisplayName(authorData || afterData);
    await createNotificationDoc(
        `collaboration_request_${context.params.bookId}_${afterCollaboratorId}`,
        buildNotification({
          userId: afterCollaboratorId,
          actorId: authorId,
          actorName,
          actorPhotoURL: normalizeString(authorData?.photoURL) || null,
          type: "collaboration_request",
          text: `${actorName} wants to collaborate with you.`,
          link: `/collaboration?book=${context.params.bookId}`,
          targetId: context.params.bookId,
          metadata: {
            bookId: context.params.bookId,
            collaboratorId: afterCollaboratorId,
          },
        }),
    );
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

exports.sendAdminContentNotification = functionsV1
    .runWith({timeoutSeconds: 540, memory: "512MB"})
    .https.onCall(async (data, context) => {
      requireAdminContext(context);
      const request = await validateAdminContentNotificationRequest(data);
      const result = await createAdminContentRecommendationNotifications({
        ...request,
        createdBy: context.auth?.uid || "",
      });
      return {success: true, ...result};
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
  const [booksSnapshot, authorsSnapshot, topicsSnapshot, bannersSnapshot, statsSnapshot] = await Promise.all([
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
    db.collection("book_stats")
        .orderBy("upvotes", "desc")
        .limit(200)
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
  for (const doc of statsSnapshot?.docs || []) {
    const data = doc.data() || {};
    const upvotes = Number(data.upvotes || 0);
    const downvotes = Number(data.downvotes || 0);
    const recommendationCount = Number(
        data.recommendationCount ?? (upvotes - downvotes),
    );
    if (upvotes <= 0 && recommendationCount <= 0) {
      continue;
    }
    recommendationStats[doc.id] = {
      recommendationCount,
      upvotes,
      downvotes,
      viewCount: Number(data.viewCount || 0),
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
  requireAdminContext(context);
  await refreshHomepageMetadataInternal();
  return {success: true, message: "Homepage metadata refreshed successfully."};
});

exports.dailyRecommendationScheduler = functionsV1.pubsub.schedule("0 21 * * *").timeZone("Asia/Kolkata").onRun(async (context) => {
  const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);

  try {
    // 1. Query the books collection for books with status === "published" and updatedAt >= [7 days ago]
    const booksSnap = await db.collection("books")
      .where("status", "==", "published")
      .where("updatedAt", ">=", oneWeekAgo)
      .orderBy("updatedAt", "desc")
      .limit(25)
      .get();

    if (booksSnap.empty) {
      logger.info("No books published or updated in the last 7 days. Skipping daily recommendation push.");
      return null;
    }

    // 2. Select one book randomly from the returned list of books
    const docs = booksSnap.docs;
    const randomIndex = Math.floor(Math.random() * docs.length);
    const selectedDoc = docs[randomIndex];
    const bookData = selectedDoc.data();
    const bookId = selectedDoc.id;

    logger.info(`Selected book "${bookData.title}" (${bookId}) for automated recommendation.`);

    // 3. Paginate through all active users in batches of 500
    let lastDoc = null;
    let hasMore = true;
    const batchSize = 500;
    let totalPushesSent = 0;
    const link = `https://wreadom.in/?book=${encodeURIComponent(bookId)}`;

    while (hasMore) {
      let usersQuery = db.collection("users")
        .where("isDeactivated", "==", false)
        .limit(batchSize);

      if (lastDoc) {
        usersQuery = usersQuery.startAfter(lastDoc);
      }

      const usersSnap = await usersQuery.get();
      if (usersSnap.empty) {
        hasMore = false;
        break;
      }

      const promises = usersSnap.docs.map(async (userDoc) => {
        const userId = userDoc.id;
        const notificationId = db.collection("notifications").doc().id;
        const notificationData = buildNotification({
          userId,
          actorId: "system",
          actorName: "Wreadom Recommendation",
          actorPhotoURL: null,
          type: "new_creation",
          text: `Recommended for you: "${bookData.title}" - Check out this story!`,
          link,
          targetId: bookId,
          metadata: {
            source: "scheduled_daily_recommendation",
            bookId,
            contentId: bookId,
            targetType: "book"
          }
        });

        await sendPushNotificationToUser(userId, notificationData, notificationId);
      });

      await Promise.all(promises);

      totalPushesSent += usersSnap.docs.length;
      lastDoc = usersSnap.docs[usersSnap.docs.length - 1];

      if (usersSnap.docs.length < batchSize) {
        hasMore = false;
      }
    }

    logger.info(`Completed automated daily recommendation. Push notifications processed for ${totalPushesSent} users.`);
  } catch (error) {
    logger.error("Failed to run dailyRecommendationScheduler:", error);
  }

  return null;
});

if (process.env.LIBREBOOK_FUNCTIONS_TEST_HELPERS === "true") {
  exports.__test = {
    contentTypeLabel,
    contentTitle,
    publishedChapters,
    diffAddedPublishedChapters,
    reviewNotificationText,
    publishedBookNotificationText,
    newChapterNotificationText,
    localizedPushBody,
    chapterKey,
    isSupersededBookCommentNotification,
    shouldSendPushNotification,
    isAdminContext,
    formatMilestoneCount,
    authorReadMilestoneNotificationText,
    crossedAuthorReadMilestones,
  };
}
