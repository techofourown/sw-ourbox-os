const path = require("path");

const dataset = require("@graphmd/dataset");

const loadDatasetSnapshot =
  dataset.loadDatasetSnapshot ||
  dataset.loadDatasetSnapshotFromDirs ||
  dataset.loadDatasetSnapshotFromDir ||
  dataset.loadDatasetSnapshotFromPaths;
const validateDatasetSnapshot =
  dataset.validateDatasetSnapshot || dataset.validateDatasetSnapshotStrict;

if (!loadDatasetSnapshot || !validateDatasetSnapshot) {
  throw new Error(
    "@graphmd/dataset does not expose the expected snapshot loader/validator functions."
  );
}

const CANONICAL_DIRS = ["types", "records", "blocks", "plugins"];

const tryLoadSnapshot = () => {
  const datasetPath = path.resolve(__dirname, "..");
  const attempts = [
    () => loadDatasetSnapshot({ datasetPath, dirNames: CANONICAL_DIRS }),
    () => loadDatasetSnapshot({ datasetPath, directories: CANONICAL_DIRS }),
    () => loadDatasetSnapshot({ datasetPath, include: CANONICAL_DIRS }),
    () => loadDatasetSnapshot(datasetPath, CANONICAL_DIRS),
    () => loadDatasetSnapshot(datasetPath, { dirNames: CANONICAL_DIRS }),
    () => loadDatasetSnapshot({ datasetRoot: datasetPath, dirNames: CANONICAL_DIRS }),
  ];

  let lastError;
  for (const attempt of attempts) {
    try {
      return attempt();
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError;
};

const snapshot = tryLoadSnapshot();

let validation;
try {
  validation = validateDatasetSnapshot(snapshot);
} catch (error) {
  console.error("Dataset validation threw an error:");
  console.error(error);
  process.exit(1);
}

if (validation === true || validation?.ok === true || validation?.valid === true) {
  process.exit(0);
}

console.error("Dataset validation failed.");
if (validation?.errors) {
  console.error(JSON.stringify(validation.errors, null, 2));
}
process.exit(1);
