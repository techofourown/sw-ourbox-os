const path = require("path");
const graphmd = require("@graphmd/dataset");

const { validateDatasetSnapshot } = graphmd;

function resolveLoader() {
  return (
    graphmd.loadDatasetSnapshot ||
    graphmd.loadDatasetSnapshotFromDir ||
    graphmd.createDatasetSnapshot ||
    graphmd.createDatasetSnapshotFromDir
  );
}

async function loadSnapshot() {
  const loader = resolveLoader();
  if (!loader) {
    throw new Error("@graphmd/dataset loader function not found.");
  }

  const datasetDir = process.cwd();
  const options = {
    datasetDir,
    typesDir: path.join(datasetDir, "types"),
    recordsDir: path.join(datasetDir, "records"),
    blocksDir: path.join(datasetDir, "blocks"),
    pluginsDir: path.join(datasetDir, "plugins"),
  };

  if (loader.length === 1) {
    try {
      return await loader(datasetDir);
    } catch (error) {
      return loader(options);
    }
  }

  try {
    return await loader(options);
  } catch (error) {
    return loader(datasetDir);
  }
}

async function main() {
  const snapshot = await loadSnapshot();
  const result = validateDatasetSnapshot(snapshot);

  if (Array.isArray(result) && result.length > 0) {
    console.error("GraphMD dataset validation failed:");
    for (const issue of result) {
      console.error(issue);
    }
    process.exit(1);
  }

  if (result && result.isValid === false) {
    console.error("GraphMD dataset validation failed.");
    if (Array.isArray(result.errors)) {
      for (const issue of result.errors) {
        console.error(issue);
      }
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
