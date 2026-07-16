"use strict";

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const shouldApply = process.argv.includes("--apply");
const pageSize = 400;

function cleanTopic(value) {
  return typeof value === "string" ?
    value
      .replace(/_+/g, " ")
      .replace(/[#"]/g, "")
      .trim()
      .replace(/\s+/g, " ") :
    "";
}

function cleanTopics(values) {
  if (!Array.isArray(values)) return [];
  const cleaned = [];
  const seen = new Set();
  for (const value of values) {
    const displayName = cleanTopic(value);
    const normalizedName = displayName.toLowerCase();
    if (!normalizedName || seen.has(normalizedName)) continue;
    seen.add(normalizedName);
    cleaned.push(displayName);
  }
  return cleaned;
}

async function collectChanges() {
  const changes = [];
  const transformations = new Map();
  let scannedBooks = 0;
  let scannedTopicValues = 0;
  let cleanedTopicValues = 0;
  let removedDuplicates = 0;
  let lastDocument = null;

  while (true) {
    let query = db.collection("books")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (lastDocument) query = query.startAfter(lastDocument);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const document of snapshot.docs) {
      scannedBooks++;
      const original = Array.isArray(document.data().topics) ?
        document.data().topics :
        [];
      const cleaned = cleanTopics(original);
      scannedTopicValues += original.length;
      cleanedTopicValues += cleaned.length;
      removedDuplicates += Math.max(0, original.length - cleaned.length);

      for (const rawValue of original) {
        const raw = typeof rawValue === "string" ? rawValue : String(rawValue ?? "");
        const next = cleanTopic(rawValue);
        if (raw !== next) {
          const key = `${raw} -> ${next || "(removed)"}`;
          transformations.set(key, (transformations.get(key) || 0) + 1);
        }
      }

      if (JSON.stringify(original) !== JSON.stringify(cleaned)) {
        changes.push({ref: document.ref, before: original, after: cleaned});
      }
    }

    lastDocument = snapshot.docs[snapshot.docs.length - 1];
  }

  return {
    changes,
    transformations,
    scannedBooks,
    scannedTopicValues,
    cleanedTopicValues,
    removedDuplicates,
  };
}

async function applyChanges(changes) {
  for (let offset = 0; offset < changes.length; offset += pageSize) {
    const batch = db.batch();
    for (const change of changes.slice(offset, offset + pageSize)) {
      batch.update(change.ref, {topics: change.after});
    }
    await batch.commit();
  }
}

async function inspectCatalogue() {
  const snapshot = await db.collection("topic-tags").get();
  const names = snapshot.docs.map((document) =>
    String(document.data().displayName || ""));
  const invalidNames = names.filter((name) => /[_#"]/.test(name));
  const normalizedNames = names.map((name) =>
    name.trim().replace(/\s+/g, " ").toLowerCase());
  const duplicateNormalizedNames = [...new Set(
    normalizedNames.filter((name, index) =>
      normalizedNames.indexOf(name) !== index),
  )];
  return {
    count: names.length,
    invalidNames,
    duplicateNormalizedNames,
  };
}

async function main() {
  const report = await collectChanges();
  const catalogue = await inspectCatalogue();
  console.log(`Scanned ${report.scannedBooks} books and ${report.scannedTopicValues} topic values.`);
  console.log(`${report.changes.length} books require changes.`);
  console.log(`${report.removedDuplicates} empty or duplicate topic values will be removed.`);
  console.log(`${report.cleanedTopicValues} topic values will remain.`);
  console.log(`${catalogue.count} catalogue entries found.`);
  console.log(`Invalid catalogue entries: ${JSON.stringify(catalogue.invalidNames)}`);
  console.log(`Duplicate normalized entries: ${JSON.stringify(catalogue.duplicateNormalizedNames)}`);

  const transformations = [...report.transformations.entries()]
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  console.log("Transformations:");
  for (const [transformation, count] of transformations) {
    console.log(`  ${count}x ${transformation}`);
  }

  if (!shouldApply) {
    console.log("Dry run only. Re-run with --apply to update books.");
    return;
  }

  await applyChanges(report.changes);
  console.log(`Updated ${report.changes.length} books.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
