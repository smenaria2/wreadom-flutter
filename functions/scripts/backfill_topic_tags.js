"use strict";

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

function normalizeTopic(value) {
  return typeof value === "string" ?
    value
      .replace(/_+/g, " ")
      .replace(/[#"]/g, "")
      .trim()
      .replace(/\s+/g, " ") :
    "";
}

function documentId(normalizedName) {
  return Buffer.from(normalizedName, "utf8").toString("base64url");
}

async function deleteExistingCatalogue() {
  while (true) {
    const snapshot = await db.collection("topic-tags").limit(400).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

async function collectPublishedTopics() {
  const tags = new Map();
  let lastDocument = null;

  while (true) {
    let query = db.collection("books")
      .where("status", "==", "published")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(400);
    if (lastDocument) query = query.startAfter(lastDocument);

    const snapshot = await query.get();
    if (snapshot.empty) return tags;

    for (const document of snapshot.docs) {
      const topics = Array.isArray(document.data().topics) ?
        document.data().topics :
        [];
      const seenInBook = new Set();
      for (const rawTopic of topics) {
        const displayName = normalizeTopic(rawTopic);
        const normalizedName = displayName.toLowerCase();
        if (!normalizedName || seenInBook.has(normalizedName)) continue;
        seenInBook.add(normalizedName);
        const current = tags.get(normalizedName);
        tags.set(normalizedName, {
          displayName: current?.displayName || displayName,
          usageCount: (current?.usageCount || 0) + 1,
        });
      }
    }

    lastDocument = snapshot.docs[snapshot.docs.length - 1];
  }
}

async function writeCatalogue(tags) {
  const entries = [...tags.entries()];
  for (let offset = 0; offset < entries.length; offset += 400) {
    const batch = db.batch();
    for (const [normalizedName, value] of entries.slice(offset, offset + 400)) {
      batch.set(db.collection("topic-tags").doc(documentId(normalizedName)), {
        normalizedName,
        displayName: value.displayName,
        usageCount: value.usageCount,
        updatedAt: Date.now(),
      });
    }
    await batch.commit();
  }
}

async function main() {
  const tags = await collectPublishedTopics();
  await deleteExistingCatalogue();
  await writeCatalogue(tags);
  console.log(`Backfilled ${tags.size} topic tags.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
