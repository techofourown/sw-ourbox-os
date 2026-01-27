const fs = require("node:fs");
const path = require("node:path");
const { discoverGraphMDObjects } = require("@graphmd/dataset");

const CANONICAL_DIRS = ["types", "records", "blocks", "plugins"];

function toPosix(relativePath) {
  return relativePath.split(path.sep).join("/");
}

function collectDatasetFiles(rootDir, includeDirs = CANONICAL_DIRS) {
  const files = new Map();

  for (const relDir of includeDirs) {
    const dirPath = path.join(rootDir, relDir);
    if (!fs.existsSync(dirPath)) {
      continue;
    }

    const stack = [dirPath];
    while (stack.length) {
      const current = stack.pop();
      for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
        const absPath = path.join(current, entry.name);
        if (entry.isDirectory()) {
          stack.push(absPath);
          continue;
        }
        if (!entry.isFile()) {
          continue;
        }
        const relPath = path.relative(rootDir, absPath);
        files.set(toPosix(relPath), fs.readFileSync(absPath));
      }
    }
  }

  return files;
}

function loadGraphmdSnapshot(rootDir = path.resolve(__dirname, ".."), includeDirs = CANONICAL_DIRS) {
  const files = collectDatasetFiles(rootDir, includeDirs);
  const snapshot = { files };
  const parsed = discoverGraphMDObjects(snapshot);

  snapshot.records = parsed.recordObjects;
  snapshot.types = parsed.typeObjects;
  snapshot._ignored = parsed.ignored;
  snapshot._parseErrors = parsed.errors;

  return snapshot;
}

module.exports = {
  CANONICAL_DIRS,
  collectDatasetFiles,
  loadGraphmdSnapshot,
};
