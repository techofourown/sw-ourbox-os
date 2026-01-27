const path = require("node:path");

function loadSnapshot() {
  const dataset = require("@graphmd/dataset");
  const loadDatasetSnapshot =
    dataset.loadDatasetSnapshot ||
    dataset.loadDatasetSnapshotFromDir ||
    dataset.createDatasetSnapshot ||
    dataset.loadDatasetSnapshotFromDir;

  if (typeof loadDatasetSnapshot !== "function") {
    throw new Error("@graphmd/dataset does not expose a loadDatasetSnapshot function.");
  }

  const datasetRootDir = path.resolve(__dirname, "..");
  const canonicalDirs = ["types", "records", "blocks", "plugins"];

  const optionCandidates = [
    { datasetRootDir, includeDirs: canonicalDirs },
    { datasetRootDir, datasetDirs: canonicalDirs },
    { rootDir: datasetRootDir, includeDirs: canonicalDirs },
    { rootDir: datasetRootDir, datasetDirs: canonicalDirs },
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

  return loadDatasetSnapshot(datasetRootDir);
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
