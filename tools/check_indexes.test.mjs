// Run: node tools/check_indexes.test.mjs
import assert from 'node:assert/strict';
import { findProblems } from './check_indexes.mjs';

const f = (p, o = 'ASCENDING') => ({ fieldPath: p, order: o });

assert.deepEqual(
  findProblems({ indexes: [{ collectionGroup: 'a', queryScope: 'COLLECTION', fields: [f('x'), f('y')] }] }),
  [],
);
assert.equal(
  findProblems({ indexes: [{ collectionGroup: 'a', queryScope: 'COLLECTION', fields: [f('x')] }] }).length,
  1,
);
const dup = { collectionGroup: 'a', queryScope: 'COLLECTION', fields: [f('x'), f('y')] };
assert.equal(findProblems({ indexes: [dup, dup] }).length, 1);
console.log('check_indexes self-test OK');
