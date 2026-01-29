#!/usr/bin/env node

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
        if (snapshot) return snapshot;
      } catch (_error) {
        // Try the next signature.
      }
    }

    try {
      return loadDatasetSnapshot(datasetRootDir);
    } catch (_error) {
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
        for (const error of errors) console.error(error);
      }
      process.exit(1);
    }
    return;
  }

  if (Array.isArray(result) && result.length > 0) {
    console.error("Dataset validation failed:");
    for (const error of result) console.error(error);
    process.exit(1);
  }
}

function normalizeRecords(snapshot) {
  if (Array.isArray(snapshot.records)) return snapshot.records;
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
  if (orderA !== orderB) return orderA - orderB;
  return String(a.recordId).localeCompare(String(b.recordId));
}

function heading(level, text) {
  const depth = Math.max(1, level);
  return `${"#".repeat(depth)} ${text}`;
}

function escapeRegExp(input) {
  return String(input).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function slugify(input) {
  const s = String(input || "").trim().toLowerCase();
  return s
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-+/g, "-");
}

function computeSpecFileName(specId, title) {
  const prefixRe = new RegExp(`^${escapeRegExp(specId)}:\\s*`, "i");
  const titleWithoutId = String(title || specId).replace(prefixRe, "").trim();
  const suffix = slugify(titleWithoutId) || slugify(specId);
  return `${specId}-${suffix}.md`;
}

function renderSpec(snapshot, specId) {
  const records = normalizeRecords(snapshot);
  const recordKey = (record) => `${record.typeId}:${record.recordId}`;
  const byParent = new Map();

  for (const record of records) {
    if (!record.parent) continue;
    const list = byParent.get(record.parent) || [];
    list.push(record);
    byParent.set(record.parent, list);
  }

  const specRecord = records.find(
    (record) => record.typeId === "spec" && record.recordId === specId
  );

  if (!specRecord) {
    throw new Error(`Missing spec record: spec:${specId}`);
  }

  const lines = [];
  lines.push(heading(1, specRecord.fields?.title || specId));
  lines.push("");

  if (specRecord.fields?.version) lines.push(`**Version:** ${specRecord.fields.version}`);
  if (specRecord.fields?.lastUpdated) lines.push(`**Last Updated:** ${specRecord.fields.lastUpdated}`);
  if (specRecord.fields?.status) lines.push(`**Status:** ${specRecord.fields.status}`);
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
      if (req.fields?.status) metadata.push(`**Status:** ${req.fields.status}`);
      if (req.fields?.testable !== undefined) metadata.push(`**Testable:** ${req.fields.testable}`);
      if (req.fields?.area) metadata.push(`**Area:** ${req.fields.area}`);
      if (req.fields?.rationale) metadata.push(`**Rationale:** ${req.fields.rationale}`);

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

function specSortKey(specId) {
  // Deterministic, opinionated ordering:
  // 1) SyRS first
  // 2) then SRS
  // 3) then anything else
  if (specId.startsWith("SyRS-")) return `0-${specId}`;
  if (specId.startsWith("SRS-")) return `1-${specId}`;
  return `9-${specId}`;
}

function main() {
  const repoRoot = path.resolve(__dirname, "..");
  const snapshot = loadSnapshot();
  validateSnapshot(snapshot);

  const records = normalizeRecords(snapshot);
  const specRecords = records.filter((r) => r.typeId === "spec");
  const specIds = specRecords.map((r) => r.recordId).sort((a, b) => {
    return specSortKey(a).localeCompare(specSortKey(b));
  });

  if (!specIds.length) {
    console.error("FATAL: No spec records found to compile.");
    process.exit(1);
  }

  const outputs = [];

  // Compile each spec to its standard filename at repo root
  for (const specId of specIds) {
    const specRecord = specRecords.find((r) => r.recordId === specId);
    const title = specRecord?.fields?.title || specId;
    const fileName = computeSpecFileName(specId, title);
    const outPath = path.resolve(repoRoot, fileName);

    const rendered = renderSpec(snapshot, specId);
    fs.writeFileSync(outPath, rendered, "utf8");
    outputs.push({ specId, fileName, outPath });
    console.log(`Wrote ${outPath}`);
  }

  // Build omnibus: Terms-and-Definitions + architecture docs + all compiled specs
  const termsPath = path.resolve(repoRoot, "docs", "00-Glossary", "Terms-and-Definitions.md");
  if (!fs.existsSync(termsPath)) {
    console.error(`FATAL: Missing Terms-and-Definitions file at ${termsPath}`);
    process.exit(1);
  }
  const terms = fs.readFileSync(termsPath, "utf8").trimEnd();

  const archGlossaryPath = path.resolve(repoRoot, "docs", "architecture", "Glossary.md");
  if (!fs.existsSync(archGlossaryPath)) {
    console.error(`FATAL: Missing architecture Glossary file at ${archGlossaryPath}`);
    process.exit(1);
  }
  const archGlossary = fs.readFileSync(archGlossaryPath, "utf8").trimEnd();

  const archDescPath = path.resolve(repoRoot, "docs", "architecture", "AD-0001-ourbox-os-architecture-description.md");
  if (!fs.existsSync(archDescPath)) {
    console.error(`FATAL: Missing architecture description file at ${archDescPath}`);
    process.exit(1);
  }
  const archDesc = fs.readFileSync(archDescPath, "utf8").trimEnd();

  const omnibusName = "OurBox-OS-Requirements-Omnibus.md";
  const omnibusPath = path.resolve(repoRoot, omnibusName);

  const sha = process.env.GITHUB_SHA ? process.env.GITHUB_SHA.slice(0, 12) : null;

  const lines = [];
  lines.push("# OurBox OS Requirements Omnibus");
  lines.push("");
  if (sha) lines.push(`**Source:** ${sha}`);
  lines.push("");
  lines.push("## Included Specifications");
  for (const o of outputs) {
    lines.push(`- ${o.fileName} (source: spec:${o.specId})`);
  }
  lines.push("");
  lines.push("---");
  lines.push("");
  lines.push(terms);
  lines.push("");
  lines.push("---");
  lines.push("");
  lines.push(archGlossary);
  lines.push("");
  lines.push("---");
  lines.push("");
  lines.push(archDesc);
  lines.push("");
  lines.push("---");
  lines.push("");

  for (const o of outputs) {
    const content = fs.readFileSync(o.outPath, "utf8").trimEnd();
    lines.push(content);
    lines.push("");
    lines.push("---");
    lines.push("");
  }

  fs.writeFileSync(omnibusPath, lines.join("\n").trimEnd() + "\n", "utf8");
  console.log(`Wrote ${omnibusPath}`);
}

try {
  main();
} catch (error) {
  console.error(error?.stack || error?.message || error);
  process.exit(1);
}
