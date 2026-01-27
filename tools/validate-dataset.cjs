const path = require("path");

const { loadDatasetSnapshot, validateDatasetSnapshot } = require("@graphmd/dataset");

const datasetRoot = process.cwd();
const snapshot = loadDatasetSnapshot({
  rootDir: datasetRoot,
  typesDir: path.join(datasetRoot, "types"),
  recordsDir: path.join(datasetRoot, "records"),
  blocksDir: path.join(datasetRoot, "blocks"),
  pluginsDir: path.join(datasetRoot, "plugins"),
});

const validation = validateDatasetSnapshot(snapshot);

const isOk =
  validation === true ||
  validation?.ok === true ||
  validation?.valid === true;

if (!isOk) {
  console.error("GraphMD dataset validation failed.");
  if (validation?.errors) {
    console.error(JSON.stringify(validation.errors, null, 2));
  } else {
    console.error(JSON.stringify(validation, null, 2));
  }
  process.exit(1);
}

console.log("GraphMD dataset validation passed.");
