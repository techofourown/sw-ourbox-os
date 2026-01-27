const path = require("node:path");
const { loadGraphmdSnapshot, CANONICAL_DIRS } = require("./load-graphmd-snapshot.cjs");

function loadSnapshot() {
  const dataset = require("@graphmd/dataset");
  const datasetRootDir = path.resolve(__dirname, "..");
  const loadDatasetSnapshot =
    dataset.loadDatasetSnapshot ||
    dataset.loadDatasetSnapshotFromDir ||
    dataset.createDatasetSnapshot;

  if (typeof loadDatasetSnapshot === "function") {
    const optionCandidates = [
      { datasetRootDir, includeDirs: CANONICAL_DIRS },
      { datasetRootDir, datasetDirs: CANONICAL_DIRS },
      { rootDir: datasetRootDir, includeDirs: CANONICAL_DIRS },
      { rootDir: datasetRootDir, datasetDirs: CANONICAL_DIRS },
    ];

    for (const options of optionCandidates) {
      try {
        const snapshot = loadDatasetSnapshot(options);
        if (snapshot) {
          return snapshot;
        }
      } catch (error) {
        // Try the next signature.
      }
    }

    try {
      return loadDatasetSnapshot(datasetRootDir);
    } catch (error) {
      // Fall back to our filesystem loader.
    }
  }

  return loadGraphmdSnapshot(datasetRootDir, CANONICAL_DIRS);
}

function validateSnapshot(snapshot) {
  const { validateDatasetSnapshot } = require("@graphmd/dataset");

  if (typeof validateDatasetSnapshot !== "function") {
    throw new Error("@graphmd/dataset does not expose validateDatasetSnapshot.");
  }

  const result = validateDatasetSnapshot(snapshot);

  if (result && typeof result === "object" && "isValid" in result) {
    if (!result.isValid) {
      const errors = result.errors || result.messages || [];
      if (errors.length) {
        console.error("Dataset validation failed:");
        for (const error of errors) {
          console.error(error);
        }
      }
      process.exit(1);
    }
    return;
  }

  if (Array.isArray(result) && result.length > 0) {
    console.error("Dataset validation failed:");
    for (const error of result) {
      console.error(error);
    }
    process.exit(1);
  }
}

try {
  const snapshot = loadSnapshot();
  validateSnapshot(snapshot);
  console.log("GraphMD dataset is valid.");
} catch (error) {
  console.error(error?.stack || error?.message || error);
  process.exit(1);
}
