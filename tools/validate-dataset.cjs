const path = require("path");
const {
  loadDatasetSnapshot,
  validateDatasetSnapshot,
} = require("@graphmd/dataset");

const datasetRoot = path.resolve(__dirname, "..");
const snapshot = loadDatasetSnapshot({
  rootDir: datasetRoot,
  dirNames: {
    types: "types",
    records: "records",
    blocks: "blocks",
    plugins: "plugins",
  },
});

const validation = validateDatasetSnapshot(snapshot);

if (validation && typeof validation === "object" && "valid" in validation) {
  if (!validation.valid) {
    console.error("GraphMD dataset validation failed.");
    if (validation.errors) {
      console.error(JSON.stringify(validation.errors, null, 2));
    }
    process.exit(1);
  }
} else if (validation === false) {
  console.error("GraphMD dataset validation failed.");
  process.exit(1);
}

console.log("GraphMD dataset validation passed.");
