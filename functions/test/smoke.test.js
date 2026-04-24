const test = require("node:test");
const assert = require("node:assert/strict");

test("functions module loads", () => {
  const exported = require("../index.js");
  assert.ok(exported);
  assert.ok(typeof exported.onFollowCreated === "function");
  assert.ok(typeof exported.onMessageCreated === "function");
  assert.ok(typeof exported.createAudioReviewUploadTarget === "function");
  assert.ok(typeof exported.deleteAudioReviewObject === "function");
  assert.ok(typeof exported.createAudioReviewDownloadUrl === "function");
});
