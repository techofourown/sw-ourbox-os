const { loadDatasetSnapshot, validateDatasetSnapshot } = require("@graphmd/dataset");

const rootDir = process.cwd();

const snapshot = loadDatasetSnapshot({
  rootDir,
  includeDirs: ["types", "records", "blocks", "plugins"],
});

const validation = validateDatasetSnapshot(snapshot);

const isValid =
  validation === true ||
  validation?.ok === true ||
  (Array.isArray(validation) && validation.length === 0);

if (!isValid) {
  console.error("GraphMD dataset validation failed.");
  if (validation?.errors) {
    console.error(JSON.stringify(validation.errors, null, 2));
  } else {
    console.error(JSON.stringify(validation, null, 2));
  }
  process.exit(1);
}

console.log("GraphMD dataset validation passed.");
