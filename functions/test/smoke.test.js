const test = require("node:test");
const assert = require("node:assert/strict");

process.env.LIBREBOOK_FUNCTIONS_TEST_HELPERS = "true";
const exported = require("../index.js");

test("functions module loads", () => {
  assert.ok(exported);
  assert.ok(typeof exported.onFollowCreated === "function");
  assert.ok(typeof exported.sendPushNotification === "function");
  assert.ok(typeof exported.onMessageCreated === "function");
  assert.ok(typeof exported.createAudioReviewUploadTarget === "function");
  assert.ok(typeof exported.deleteAudioReviewObject === "function");
  assert.ok(typeof exported.createAudioReviewDownloadUrl === "function");
  assert.ok(exported.__test);
});

test("publication notifications use canonical single-quote wording", () => {
  assert.equal(
      exported.__test.publishedBookNotificationText("Sumit", {
        contentType: "Poem",
        title: "New Life",
      }),
      "Sumit has published a poem 'New Life'.",
  );
});

test("published book edits without added chapters do not create chapter diffs", () => {
  const before = {
    status: "published",
    chapters: [
      {id: "chapter-1", title: "Opening", status: "published", content: "Old"},
    ],
  };
  const after = {
    status: "published",
    chapters: [
      {id: "chapter-1", title: "Opening Revised", status: "published", content: "New"},
    ],
  };

  assert.deepEqual(exported.__test.diffAddedPublishedChapters(before, after), []);
});

test("published chapter deletion does not create chapter diffs", () => {
  const before = {
    status: "published",
    chapters: [
      {id: "chapter-1", title: "Opening", status: "published"},
      {id: "chapter-2", title: "Meeting Her", status: "published"},
    ],
  };
  const after = {
    status: "published",
    chapters: [
      {id: "chapter-1", title: "Opening", status: "published"},
    ],
  };

  assert.deepEqual(exported.__test.diffAddedPublishedChapters(before, after), []);
});

test("new chapter notifications use canonical to-content wording", () => {
  const before = {
    status: "published",
    chapters: [{id: "chapter-1", title: "Opening"}],
  };
  const after = {
    status: "published",
    contentType: "Poem",
    title: "New Life",
    chapters: [
      {id: "chapter-1", title: "Opening"},
      {id: "chapter-2", title: "Meeting Her"},
    ],
  };

  const added = exported.__test.diffAddedPublishedChapters(before, after);

  assert.equal(added.length, 1);
  assert.equal(added[0].title, "Meeting Her");
  assert.equal(
      exported.__test.newChapterNotificationText("Sumit", after, added[0], 1),
      "Sumit has published a new chapter 'Meeting Her' to poem 'New Life'.",
  );
});

test("multiple new chapters are all detected", () => {
  const before = {
    status: "published",
    chapters: [{id: "chapter-1", title: "Opening", status: "published"}],
  };
  const after = {
    status: "published",
    contentType: "Story",
    title: "Blue Door",
    chapters: [
      {id: "chapter-1", title: "Opening", status: "published"},
      {id: "chapter-2", title: "Knock", status: "published"},
      {id: "chapter-3", title: "Inside", status: "published"},
    ],
  };

  const added = exported.__test.diffAddedPublishedChapters(before, after);
  const texts = added.map((chapter, index) =>
    exported.__test.newChapterNotificationText("Maya", after, chapter, index + 1),
  );

  assert.deepEqual(added.map((chapter) => chapter.title), ["Knock", "Inside"]);
  assert.deepEqual(texts, [
    "Maya has published a new chapter 'Knock' to story 'Blue Door'.",
    "Maya has published a new chapter 'Inside' to story 'Blue Door'.",
  ]);
});

test("single-chapter review omits chapter name", () => {
  assert.equal(
      exported.__test.reviewNotificationText("Asha", {
        status: "published",
        contentType: "Poem",
        title: "New Life",
        chapters: [{id: "chapter-1", title: "Only Chapter", status: "published"}],
      }),
      "Asha has left a review on poem 'New Life'.",
  );
});

test("multi-chapter review uses selected chapter title without extra chapter label", () => {
  assert.equal(
      exported.__test.reviewNotificationText(
          "Asha",
          {
            status: "published",
            contentType: "Poem",
            title: "New Life",
            chapters: [
              {id: "chapter-1", title: "First", status: "published"},
              {id: "chapter-2", title: "Meeting Her", status: "published"},
            ],
          },
          {chapterId: "chapter-2"},
      ),
      "Asha has left a review on 'Meeting Her' of poem 'New Life'.",
  );
});
