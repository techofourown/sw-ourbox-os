/* eslint-disable no-console */
const fs = require("node:fs");
const path = require("node:path");

const { validateDatasetSnapshot } = require("@graphmd/dataset");

const ROOT = path.resolve(__dirname, "..");
const DATASET_DIRS = ["types", "records", "blocks", "plugins"];
const SKIP_DIRS = new Set([".git", "node_modules"]);

function walk(absDir, relDir, files) {
  const entries = fs.readdirSync(absDir, { withFileTypes: true });
  for (const e of entries) {
    if (SKIP_DIRS.has(e.name)) continue;

    const abs = path.join(absDir, e.name);
    const rel = path.posix.join(relDir, e.name);

    if (e.isDirectory()) {
      walk(abs, rel, files);
    } else if (e.isFile()) {
      files.set(rel, fs.readFileSync(abs));
    }
  }
}

function loadSnapshot(root) {
  const files = new Map();
  for (const dir of DATASET_DIRS) {
    const abs = path.join(root, dir);
    if (!fs.existsSync(abs)) continue;
    walk(abs, dir, files);
  }
  return { files };
}

function main() {
  const snapshot = loadSnapshot(ROOT);
  console.log(
    `GraphMD dataset validation: loaded ${snapshot.files.size} files from ${DATASET_DIRS.join(", ")}`
  );

  const result = validateDatasetSnapshot(snapshot);
  if (!result || result.ok !== true) {
    console.error("❌ DATASET INVALID (GraphMD validator)");
    console.error(JSON.stringify(result, null, 2));
    process.exit(1);
  }

  console.log("✅ DATASET VALID (GraphMD validator)");
}

main();
