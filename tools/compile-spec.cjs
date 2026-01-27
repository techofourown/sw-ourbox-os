const fs = require("node:fs");
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
      // Fall back to filesystem loader below.
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

function normalizeRecords(snapshot) {
  if (Array.isArray(snapshot.records)) {
    return snapshot.records;
  }
  if (snapshot.recordsById && typeof snapshot.recordsById === "object") {
    return Object.values(snapshot.recordsById);
  }
  if (snapshot.recordsMap && typeof snapshot.recordsMap === "object") {
    return Object.values(snapshot.recordsMap);
  }
  if (snapshot.recordsIndex && typeof snapshot.recordsIndex === "object") {
    return Object.values(snapshot.recordsIndex);
  }
  throw new Error("Unable to locate records in dataset snapshot.");
}

function sortByOrderThenId(a, b) {
  const orderA = Number(a.fields?.order ?? 0);
  const orderB = Number(b.fields?.order ?? 0);
  if (orderA !== orderB) {
    return orderA - orderB;
  }
  return String(a.recordId).localeCompare(String(b.recordId));
}

function heading(level, text) {
  const depth = Math.max(1, level);
  return `${"#".repeat(depth)} ${text}`;
}

function renderSpec(snapshot) {
  const records = normalizeRecords(snapshot);
  const recordKey = (record) => `${record.typeId}:${record.recordId}`;
  const byKey = new Map(records.map((record) => [recordKey(record), record]));
  const byParent = new Map();

  for (const record of records) {
    if (!record.parent) {
      continue;
    }
    const list = byParent.get(record.parent) || [];
    list.push(record);
    byParent.set(record.parent, list);
  }

  const specRecord = records.find(
    (record) => record.typeId === "spec" && record.recordId === "ourbox-os-spec"
  );

  if (!specRecord) {
    throw new Error("Missing spec record: spec:ourbox-os-spec");
  }

  const lines = [];
  lines.push(heading(1, specRecord.fields?.title || "OurBox OS Specification"));
  lines.push("");
  if (specRecord.fields?.version) {
    lines.push(`**Version:** ${specRecord.fields.version}`);
  }
  if (specRecord.fields?.lastUpdated) {
    lines.push(`**Last Updated:** ${specRecord.fields.lastUpdated}`);
  }
  if (specRecord.fields?.status) {
    lines.push(`**Status:** ${specRecord.fields.status}`);
  }
  lines.push("");
  if (specRecord.body) {
    lines.push(specRecord.body.trim());
    lines.push("");
  }

  const sections = (byParent.get(recordKey(specRecord)) || []).sort(sortByOrderThenId);

  for (const section of sections) {
    const level = Number(section.fields?.level ?? 1) + 1;
    lines.push(heading(level, section.fields?.title || section.recordId));
    lines.push("");
    if (section.body) {
      lines.push(section.body.trim());
      lines.push("");
    }

    const requirements = (byParent.get(recordKey(section)) || []).sort(sortByOrderThenId);
    for (const req of requirements) {
      lines.push(heading(level + 1, `${req.recordId}: ${req.fields?.title || "Requirement"}`));
      lines.push("");
      const metadata = [];
      if (req.fields?.status) {
        metadata.push(`**Status:** ${req.fields.status}`);
      }
      if (req.fields?.testable !== undefined) {
        metadata.push(`**Testable:** ${req.fields.testable}`);
      }
      if (req.fields?.area) {
        metadata.push(`**Area:** ${req.fields.area}`);
      }
      if (req.fields?.rationale) {
        metadata.push(`**Rationale:** ${req.fields.rationale}`);
      }
      if (metadata.length) {
        lines.push(metadata.join("  \n"));
        lines.push("");
      }
      if (req.body) {
        lines.push(req.body.trim());
        lines.push("");
      }
    }
  }

  return lines.join("\n").trimEnd() + "\n";
}

try {
  const snapshot = loadSnapshot();
  validateSnapshot(snapshot);
  const output = renderSpec(snapshot);
  const outputPath = path.resolve(__dirname, "..", "SPEC.md");
  fs.writeFileSync(outputPath, output, "utf8");
  console.log(`Wrote ${outputPath}`);
} catch (error) {
  console.error(error?.stack || error?.message || error);
  process.exit(1);
}
