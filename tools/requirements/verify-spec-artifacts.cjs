#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');
const { loadGraphmdSnapshot, CANONICAL_DIRS } = require('./load-graphmd-snapshot.cjs');

function loadSnapshot() {
  const dataset = require('@graphmd/dataset');
  const datasetRootDir = path.resolve(__dirname, '..', '..');
  const loadDatasetSnapshot =
    dataset.loadDatasetSnapshot ||
    dataset.loadDatasetSnapshotFromDir ||
    dataset.createDatasetSnapshot;

  if (typeof loadDatasetSnapshot === 'function') {
    const optionCandidates = [
      { datasetRootDir, includeDirs: CANONICAL_DIRS },
      { datasetRootDir, datasetDirs: CANONICAL_DIRS },
      { rootDir: datasetRootDir, includeDirs: CANONICAL_DIRS },
      { rootDir: datasetRootDir, datasetDirs: CANONICAL_DIRS },
    ];

    for (const options of optionCandidates) {
      try {
        const snapshot = loadDatasetSnapshot(options);
        if (snapshot) return snapshot;
      } catch (_error) {
        // try next signature
      }
    }

    try {
      return loadDatasetSnapshot(datasetRootDir);
    } catch (_error) {
      // fallback below
    }
  }

  return loadGraphmdSnapshot(datasetRootDir, CANONICAL_DIRS);
}

function normalizeRecords(snapshot) {
  if (Array.isArray(snapshot.records)) return snapshot.records;
  if (snapshot.recordsById && typeof snapshot.recordsById === 'object') {
    return Object.values(snapshot.recordsById);
  }
  if (snapshot.recordsMap && typeof snapshot.recordsMap === 'object') {
    return Object.values(snapshot.recordsMap);
  }
  if (snapshot.recordsIndex && typeof snapshot.recordsIndex === 'object') {
    return Object.values(snapshot.recordsIndex);
  }
  throw new Error('Unable to locate records in dataset snapshot.');
}

function escapeRegExp(input) {
  return String(input).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function slugify(input) {
  const s = String(input || '').trim().toLowerCase();
  return s
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-+/g, '-');
}

function computeSpecFileName(specId, title) {
  const prefixRe = new RegExp(`^${escapeRegExp(specId)}:\\s*`, 'i');
  const titleWithoutId = String(title || specId).replace(prefixRe, '').trim();
  const suffix = slugify(titleWithoutId) || slugify(specId);
  return `${specId}-${suffix}.md`;
}

function main() {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const snapshot = loadSnapshot();
  const records = normalizeRecords(snapshot);
  const specRecords = records.filter((record) => record.typeId === 'spec');

  if (specRecords.length === 0) {
    throw new Error('No spec records found while verifying compiled artifacts.');
  }

  const outputDir = path.resolve(repoRoot, 'generated', 'requirements');
  const omnibusPath = path.resolve(outputDir, 'OurBox-OS-Requirements-Omnibus.md');
  if (!fs.existsSync(omnibusPath)) {
    throw new Error(`Missing omnibus output: ${omnibusPath}`);
  }
  const omnibus = fs.readFileSync(omnibusPath, 'utf8');

  const missingFiles = [];
  const missingFromOmnibus = [];

  for (const specRecord of specRecords) {
    const specId = specRecord.recordId;
    const title = specRecord.fields?.title || specId;
    const fileName = computeSpecFileName(specId, title);
    const outPath = path.resolve(outputDir, fileName);

    if (!fs.existsSync(outPath)) {
      missingFiles.push(fileName);
      continue;
    }

    if (!omnibus.includes(fileName) || !omnibus.includes(`source: spec:${specId}`)) {
      missingFromOmnibus.push(`${fileName} (spec:${specId})`);
    }
  }

  if (missingFiles.length > 0 || missingFromOmnibus.length > 0) {
    if (missingFiles.length > 0) {
      console.error('Missing compiled spec files under generated/requirements/:');
      for (const fileName of missingFiles) console.error(`- ${fileName}`);
    }

    if (missingFromOmnibus.length > 0) {
      console.error('Compiled specs not listed in omnibus include index:');
      for (const entry of missingFromOmnibus) console.error(`- ${entry}`);
    }

    process.exit(1);
  }

  console.log(`Verified ${specRecords.length} compiled spec files and omnibus index coverage.`);
}

main();
