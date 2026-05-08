const test = require("node:test");
const assert = require("node:assert/strict");
const {readFileSync} = require("node:fs");
const {join} = require("node:path");

test("functions module loads", () => {
  const exported = require("../index.js");
  assert.ok(exported);
  assert.ok(typeof exported.onFollowCreated === "function");
  assert.ok(typeof exported.sendPushNotification === "function");
  assert.ok(typeof exported.onMessageCreated === "function");
  assert.ok(typeof exported.createAudioReviewUploadTarget === "function");
  assert.ok(typeof exported.deleteAudioReviewObject === "function");
  assert.ok(typeof exported.createAudioReviewDownloadUrl === "function");
});

test("book comment and review notifications share one canonical document", () => {
  const source = readFileSync(join(__dirname, "..", "index.js"), "utf8");
  assert.match(source, /async function notifyBookOwnersForBookActivity/);
  assert.match(source, /exports\.sendPushNotification/);
  assert.match(source, /function shouldSendPushNotification/);
  assert.match(source, /`book_comment_\$\{commentId\}_\$\{ownerId\}`/);
  assert.match(source, /reviewNotificationText\(actorName, book, data\)/);
  assert.match(source, /has left a review on chapter/);
  assert.match(source, /has left a review on \$\{type\}/);
  assert.match(source, /deleteNotificationDoc\(`book_audio_review_/);
  assert.doesNotMatch(
      source,
      /createNotificationDoc\(\s*`book_audio_review_/,
  );
});

test("publication notifications use canonical content wording", () => {
  const source = readFileSync(join(__dirname, "..", "index.js"), "utf8");
  assert.match(source, /function contentTypeLabel/);
  assert.match(source, /function diffAddedPublishedChapters/);
  assert.match(source, /async function notifyFollowersForNewChapter/);
  assert.match(source, /has published a \$\{type\} "\$\{title\}"/);
  assert.match(source, /has published a new chapter "\$\{chapterName\}" in \$\{type\} "\$\{title\}"/);
  assert.match(source, /if \(wasPublished && isPublished\)/);
});

test("review replies use review terminology", () => {
  const source = readFileSync(join(__dirname, "..", "index.js"), "utf8");
  assert.match(source, /has replied to your review on/);
  assert.doesNotMatch(source, /text: normalizeString\(afterData\.feedPostId\) \? "replied to your comment" : "replied to your discussion"/);
});

test("push payload carries navigation ids and localized bodies", () => {
  const source = readFileSync(join(__dirname, "..", "index.js"), "utf8");
  assert.match(source, /function localizedPushBody/);
  assert.match(source, /preferredLanguage/);
  assert.match(source, /function pushDataFromNotification/);
  assert.match(source, /function pushNavigationUrl/);
  assert.match(source, /"commentId"/);
  assert.match(source, /"replyId"/);
  assert.match(source, /"bookId"/);
  assert.match(source, /data: pushDataFromNotification\(data, context\.params\.notificationId\)/);
});
