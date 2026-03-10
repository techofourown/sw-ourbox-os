#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    args[key] = argv[i + 1];
    i += 1;
  }
  return args;
}

function parseJsonMap(value, name) {
  const parsed = JSON.parse(value || '{}');
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error(`${name} must be a JSON object`);
  }
  const out = {};
  for (const [k, v] of Object.entries(parsed)) out[k] = String(v);
  return out;
}

function main() {
  const args = parseArgs(process.argv);
  const required = [
    'output', 'artifact-family', 'artifact-type', 'artifact-repo', 'artifact-ref',
    'artifact-pinned-ref', 'artifact-digest', 'source-repo', 'source-commit',
    'source-version', 'created', 'artifact-metadata-json', 'input-metadata-json', 'dist-files-json',
  ];
  for (const key of required) {
    if (!args[key]) throw new Error(`Missing --${key}`);
  }

  const record = {
    schema: 1,
    artifact_family: args['artifact-family'],
    artifact_type: args['artifact-type'],
    artifact_repo: args['artifact-repo'],
    artifact_ref: args['artifact-ref'],
    artifact_pinned_ref: args['artifact-pinned-ref'],
    artifact_digest: args['artifact-digest'],
    source_repo: args['source-repo'],
    source_commit: args['source-commit'],
    source_version: args['source-version'],
    created: args.created,
    artifact_metadata: parseJsonMap(args['artifact-metadata-json'], 'artifact-metadata-json'),
    input_metadata: parseJsonMap(args['input-metadata-json'], 'input-metadata-json'),
    dist_files: parseJsonMap(args['dist-files-json'], 'dist-files-json'),
  };

  const repoRoot = path.resolve(__dirname, '..', '..');
  const { validatePublishRecord } = require(path.resolve(repoRoot, 'tools/policy/schema-validators.cjs'));
  const errors = validatePublishRecord(record);
  if (errors.length) {
    throw new Error(`Publish record failed schema validation: ${errors.join('; ')}`);
  }

  const outputPath = path.resolve(repoRoot, args.output);
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(record, null, 2)}\n`, 'utf8');
  console.log(`Wrote publish record: ${outputPath}`);
}

main();
