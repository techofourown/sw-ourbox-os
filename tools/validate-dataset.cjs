const dataset = require("@graphmd/dataset");

const loadDatasetSnapshot =
  dataset.loadDatasetSnapshot ||
  dataset.loadDatasetSnapshotSync ||
  dataset.loadDataset ||
  dataset.loadDatasetSnapshotFromDir;
const validateDatasetSnapshot =
  dataset.validateDatasetSnapshot ||
  dataset.validateDataset ||
  dataset.validateSnapshot;

if (!loadDatasetSnapshot || !validateDatasetSnapshot) {
  throw new Error("@graphmd/dataset API mismatch: missing loader/validator.");
}

const datasetDirs = ["types", "records", "blocks", "plugins"];

const loadSnapshot = async () => {
  const rootDir = process.cwd();
  const optionCandidates = [
    { rootDir, directories: datasetDirs },
    { rootDir, dirs: datasetDirs },
    { rootDir, includeDirs: datasetDirs },
    { rootDir, include: datasetDirs },
  ];

  for (const options of optionCandidates) {
    try {
      const snapshot = loadDatasetSnapshot(options);
      return snapshot?.then ? await snapshot : snapshot;
    } catch (error) {
      // Try next signature.
    }
  }

  try {
    const snapshot = loadDatasetSnapshot(rootDir, datasetDirs);
    return snapshot?.then ? await snapshot : snapshot;
  } catch (error) {
    const snapshot = loadDatasetSnapshot(rootDir);
    return snapshot?.then ? await snapshot : snapshot;
  }
};

const validateSnapshot = async () => {
  const snapshot = await loadSnapshot();
  const result = await Promise.resolve(validateDatasetSnapshot(snapshot));

  if (
    result === true ||
    result?.ok === true ||
    result?.valid === true ||
    (Array.isArray(result?.errors) && result.errors.length === 0)
  ) {
    return;
  }

  const errors = result?.errors || result;
  throw new Error(
    `GraphMD dataset validation failed. ${JSON.stringify(errors, null, 2)}`
  );
};

validateSnapshot().catch((error) => {
  console.error(error);
  process.exit(1);
});
