// Fails when firebase/firestore.indexes.json contains an invalid composite index.
//
// Firestore creates single-field indexes automatically; a composite entry with
// fewer than two fields is likely rejected by the Firebase CLI, so it must never
// be committed.  Single-field exemptions belong in `fieldOverrides`.
// No dependencies: `node tools/check_indexes.mjs`.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

export function findProblems(config) {
  const problems = [];
  const seen = new Set();
  (config.indexes ?? []).forEach((index, i) => {
    const label = `indexes[${i}] (${index.collectionGroup})`;
    const fields = index.fields ?? [];
    if (fields.length < 2) {
      problems.push(`${label}: composite index needs at least 2 fields, has ${fields.length}`);
    }
    const key = JSON.stringify([index.collectionGroup, index.queryScope, fields]);
    if (seen.has(key)) problems.push(`${label}: duplicate of an earlier index`);
    seen.add(key);
  });
  return problems;
}

const here = dirname(fileURLToPath(import.meta.url));
const isMain = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];
if (isMain) {
  const path = join(here, '..', 'firebase', 'firestore.indexes.json');
  const problems = findProblems(JSON.parse(readFileSync(path, 'utf8')));
  if (problems.length > 0) {
    console.error('firestore.indexes.json is invalid:\n - ' + problems.join('\n - '));
    process.exit(1);
  }
  console.log('firestore.indexes.json OK');
}
