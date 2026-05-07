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
  assert.match(source, /deleteNotificationDoc\(`book_audio_review_/);
  assert.doesNotMatch(
      source,
      /createNotificationDoc\(\s*`book_audio_review_/,
  );
});
