#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const { validateApprovedUpstreamInputs, validatePublishRecord } = require('./schema-validators.cjs');

const repoRoot = path.resolve(__dirname, '..', '..');

function load(rel) {
  return JSON.parse(fs.readFileSync(path.resolve(repoRoot, rel), 'utf8'));
}

const approvedData = load('release/approved-upstream-inputs.json');
const approvedErrors = validateApprovedUpstreamInputs(approvedData);
if (approvedErrors.length) {
  console.error(`approved-upstream-inputs schema validation failed: ${approvedErrors.join('; ')}`);
  process.exit(1);
}

const distDir = path.resolve(repoRoot, 'dist');
if (fs.existsSync(distDir)) {
  const records = fs.readdirSync(distDir).filter((n) => n.endsWith('.publish-record.json'));
  for (const file of records) {
    const data = load(path.join('dist', file));
    const errs = validatePublishRecord(data);
    if (errs.length) {
      console.error(`${file} schema validation failed: ${errs.join('; ')}`);
      process.exit(1);
    }
  }
}

const rootFiles = fs.readdirSync(repoRoot);
const rootGenerated = rootFiles.filter((n) => /^SRS-.*\.md$/.test(n) || /^SyRS-.*\.md$/.test(n) || n === 'OurBox-OS-Requirements-Omnibus.md');
if (rootGenerated.length) {
  console.error(`Generated requirements artifacts must not exist at repo root: ${rootGenerated.join(', ')}`);
  process.exit(1);
}

const stalePaths = [];
const docDirs = [path.resolve(repoRoot, 'docs'), path.resolve(repoRoot, 'README.md')];
function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  const stat = fs.statSync(dir);
  if (stat.isFile()) return [dir];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p2 = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p2));
    else if (e.isFile() && p2.endsWith('.md')) out.push(p2);
  }
  return out;
}
for (const md of docDirs.flatMap(walk)) {
  const text = fs.readFileSync(md, 'utf8');
  if (text.includes('tools/compile-all-specs.cjs') || text.includes('tools/validate-dataset.cjs') || text.includes('tools/verify-spec-artifacts.cjs') || text.includes('tools/check-public-sanitization.sh') || text.includes('tools/check-workflow-safety.sh')) {
    stalePaths.push(path.relative(repoRoot, md));
  }
}
if (stalePaths.length) {
  console.error(`Docs reference stale moved tool paths: ${stalePaths.join(', ')}`);
  process.exit(1);
}

console.log('JSON schema and repository policy validation passed.');
