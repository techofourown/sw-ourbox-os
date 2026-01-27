const path = require("path");
const {
  loadDatasetSnapshot,
  validateDatasetSnapshot,
} = require("@graphmd/dataset");

const datasetRoot = path.resolve(__dirname, "..");

function loadSnapshot() {
  return loadDatasetSnapshot({
    datasetRoot,
    typesPath: path.join(datasetRoot, "types"),
    recordsPath: path.join(datasetRoot, "records"),
    blocksPath: path.join(datasetRoot, "blocks"),
    pluginsPath: path.join(datasetRoot, "plugins"),
  });
}

const snapshot = loadSnapshot();
const result = validateDatasetSnapshot(snapshot);

const isValid =
  result === true ||
  result?.ok === true ||
  result?.valid === true ||
  result?.isValid === true;

if (!isValid) {
  console.error("GraphMD dataset validation failed.");
  if (Array.isArray(result)) {
    console.error(result);
  } else if (result?.errors) {
    console.error(result.errors);
  } else if (result?.issues) {
    console.error(result.issues);
  } else if (result) {
    console.error(result);
  }
  process.exit(1);
}
