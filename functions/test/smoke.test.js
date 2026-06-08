const test = require("node:test");
const assert = require("node:assert/strict");

process.env.LIBREBOOK_FUNCTIONS_TEST_HELPERS = "true";
const exported = require("../index.js");

test("functions module loads", () => {
  assert.ok(exported);
  assert.ok(typeof exported.onFollowCreated === "function");
  assert.ok(typeof exported.onRecommendationWrite === "function");
  assert.ok(typeof exported.onBookViewCreate === "function");
  assert.ok(typeof exported.sendPushNotification === "function");
  assert.ok(typeof exported.onMessageCreated === "function");
  assert.ok(typeof exported.createAudioReviewUploadTarget === "function");
  assert.ok(typeof exported.deleteAudioReviewObject === "function");
  assert.ok(typeof exported.createAudioReviewDownloadUrl === "function");
  assert.ok(typeof exported.sendAdminContentNotification === "function");
  assert.ok(exported.__test);
});

test("admin authorization supports custom claims and legacy admin email", () => {
  assert.equal(exported.__test.isAdminContext({auth: {token: {admin: true}}}), true);
  assert.equal(
      exported.__test.isAdminContext({auth: {token: {email: "smenaria2@gmail.com"}}}),
      true,
  );
  assert.equal(
      exported.__test.isAdminContext({auth: {token: {email: "reader@example.com"}}}),
      false,
  );
  assert.equal(exported.__test.isAdminContext({auth: null}), false);
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

test("Hindi push review notifications keep target details", () => {
  assert.equal(
      exported.__test.localizedPushBody(
          {
            type: "book_review",
            text: "Asha has left a review on 'Meeting Her' of poem 'New Life'.",
          },
          {preferredLanguage: "hi"},
      ),
      "ने \"New Life\" के अध्याय \"Meeting Her\" की समीक्षा की।",
  );
});

test("Hindi push content notifications keep title details", () => {
  assert.equal(
      exported.__test.localizedPushBody(
          {
            type: "book_comment",
            text: "Asha has commented on poem \"New Life\".",
          },
          {preferredLanguage: "hi"},
      ),
      "ने \"New Life\" पर टिप्पणी की।",
  );
  assert.equal(
      exported.__test.localizedPushBody(
          {
            type: "chapter_update",
            text: "Asha has published a new chapter 'Meeting Her' to poem 'New Life'.",
          },
          {preferredLanguage: "hi"},
      ),
      "ने \"New Life\" में अध्याय \"Meeting Her\" प्रकाशित किया।",
  );
});

test("review cleanup detects legacy duplicate book comment notifications", () => {
  assert.equal(
      exported.__test.isSupersededBookCommentNotification(
          "legacy_doc",
          {
            userId: "owner",
            actorId: "actor",
            type: "book_comment",
            text: "commented on your book: New Life",
            targetId: "comment1",
            link: "/book/book1?comment=comment1",
            metadata: {bookId: "book1"},
          },
          "owner",
          "actor",
          "book1",
          "comment1",
          "book_comment_comment1_owner",
      ),
      true,
  );

  assert.equal(
      exported.__test.isSupersededBookCommentNotification(
          "book_comment_comment1_owner",
          {
            userId: "owner",
            actorId: "actor",
            type: "book_review",
            targetId: "book1",
            metadata: {bookId: "book1", commentId: "comment1"},
          },
          "owner",
          "actor",
          "book1",
          "comment1",
          "book_comment_comment1_owner",
      ),
      false,
  );
});

test("author read milestones are detected when totals cross thresholds", () => {
  assert.deepEqual(
      exported.__test.crossedAuthorReadMilestones(99, 100),
      [100],
  );
  assert.deepEqual(
      exported.__test.crossedAuthorReadMilestones(100, 101),
      [],
  );
  assert.deepEqual(
      exported.__test.crossedAuthorReadMilestones(90, 501),
      [100, 500],
  );
  assert.deepEqual(
      exported.__test.crossedAuthorReadMilestones(999999, 1000000),
      [1000000],
  );
});

test("author read milestone notification text formats large counts", () => {
  assert.equal(exported.__test.formatMilestoneCount(100000), "100,000");
  assert.equal(exported.__test.formatMilestoneCount(5000000), "5,000,000");
  assert.equal(
      exported.__test.authorReadMilestoneNotificationText(1000000),
      "Congratulations! Your works reached 1,000,000 reads.",
  );
});

test("suppressed milestone notifications do not send push notifications", () => {
  assert.equal(
      exported.__test.shouldSendPushNotification(undefined, {
        type: "author_read_milestone",
        text: "Congratulations! Your works reached 100 reads.",
        timestamp: 1,
        metadata: {suppressPush: true},
      }),
      false,
  );
  assert.equal(
      exported.__test.shouldSendPushNotification(undefined, {
        type: "book_comment",
        text: "commented on your content",
        timestamp: 1,
      }),
      true,
  );
});

test("scheduled discovery pushes use dedicated notification setting keys", () => {
  assert.equal(
      exported.__test.pushNotificationSettingKey({
        type: "new_creation",
        metadata: {source: "scheduled_daily_topic", targetType: "daily_topic"},
      }),
      "dailyTopics",
  );
  assert.equal(
      exported.__test.pushNotificationSettingKey({
        type: "new_creation",
        metadata: {source: "scheduled_daily_recommendation"},
      }),
      "recommendedContent",
  );
  assert.equal(
      exported.__test.pushNotificationSettingKey({
        type: "published",
      }),
      "newCreations",
  );
});
