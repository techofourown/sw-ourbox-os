#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

const repoRoot = path.resolve(__dirname, '..', '..');

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}
function assert(cond, msg) { if (!cond) throw new Error(msg); }
function isDigest(v){ return /^sha256:[0-9a-f]{64}$/.test(v); }
function isIso(v){ return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(v); }
function isSha(v){ return /^[0-9a-f]{40}$/.test(v); }

function validateApproved(doc, file) {
  assert(doc && typeof doc === 'object' && !Array.isArray(doc), `${file}: must be object`);
  for (const key of ['schema','source_repo','approved_release_tag','platform_contract','airgap_platform']) assert(key in doc, `${file}: missing ${key}`);
  assert(doc.schema === 1, `${file}: schema must equal 1`);
  assert(/^v.+$/.test(doc.approved_release_tag), `${file}: approved_release_tag must start with v`);
  const pc = doc.platform_contract || {};
  for (const key of ['versioned_ref','pinned_ref','digest','required_route_marker']) assert(key in pc, `${file}: platform_contract missing ${key}`);
  assert(isDigest(pc.digest), `${file}: platform_contract.digest invalid`);
  const ap = doc.airgap_platform || {};
  for (const arch of ['arm64','amd64']) {
    assert(ap[arch] && typeof ap[arch] === 'object', `${file}: airgap_platform.${arch} missing`);
    for (const key of ['versioned_ref','pinned_ref','digest']) assert(key in ap[arch], `${file}: airgap_platform.${arch} missing ${key}`);
    assert(isDigest(ap[arch].digest), `${file}: airgap_platform.${arch}.digest invalid`);
  }
}

function validatePublish(doc, file) {
  for (const key of ['schema','artifact_family','artifact_type','artifact_repo','artifact_ref','artifact_pinned_ref','artifact_digest','source_repo','source_commit','source_version','created','artifact_metadata','input_metadata','dist_files']) assert(key in doc, `${file}: missing ${key}`);
  assert(doc.schema === 1, `${file}: schema must equal 1`);
  assert(['platform-contract','airgap-platform','install-defaults'].includes(doc.artifact_family), `${file}: invalid artifact_family`);
  assert(isDigest(doc.artifact_digest), `${file}: invalid artifact_digest`);
  assert(isSha(doc.source_commit), `${file}: invalid source_commit`);
  assert(isIso(doc.created), `${file}: invalid created`);
  for (const m of ['artifact_metadata','input_metadata','dist_files']) assert(doc[m] && typeof doc[m]==='object' && !Array.isArray(doc[m]), `${file}: ${m} must be object`);
}

const approved = path.join(repoRoot, 'release', 'approved-upstream-inputs.json');
validateApproved(readJson(approved), approved);

const files = [];
for (const dir of [path.join(repoRoot,'tools','publish-records','fixtures'), path.join(repoRoot,'dist')]) {
  if (!fs.existsSync(dir)) continue;
  for (const entry of fs.readdirSync(dir)) if (entry.endsWith('.publish-record.json')) files.push(path.join(dir,entry));
}
for (const f of files) validatePublish(readJson(f), f);
console.log(`Validated approved snapshot and ${files.length} publish record file(s).`);
