const fs = require("fs");
const path = require("path");
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

const recordList = Array.isArray(snapshot.records)
  ? snapshot.records
  : snapshot.records?.values
    ? Array.from(snapshot.records.values())
    : Object.values(snapshot.records || {});

const recordKey = (record) => record.id || `${record.typeId}:${record.recordId}`;

const getRecord = (key) => recordList.find((record) => recordKey(record) === key);

const specRecord = recordList.find(
  (record) => record.typeId === "spec" && record.recordId === "ourbox-os-spec"
);

if (!specRecord) {
  console.error("Expected exactly one spec record: spec:ourbox-os-spec");
  process.exit(1);
}

const getChildren = (parentKey) =>
  recordList.filter((record) => record.parent === parentKey);

const sortRecords = (records) =>
  [...records].sort((a, b) => {
    const orderA = Number(a.fields?.order);
    const orderB = Number(b.fields?.order);
    const hasOrderA = Number.isFinite(orderA);
    const hasOrderB = Number.isFinite(orderB);
    if (hasOrderA && hasOrderB && orderA !== orderB) {
      return orderA - orderB;
    }
    if (hasOrderA !== hasOrderB) {
      return hasOrderA ? -1 : 1;
    }
    return a.recordId.localeCompare(b.recordId);
  });

const getBody = (record) =>
  record.body || record.markdown || record.content || record.text || "";

const renderHeading = (level, text) => `${"#".repeat(level)} ${text}`;

const lines = [];

const specTitle = specRecord.fields?.title || "OurBox OS Specification";
lines.push(`# ${specTitle}`);

const specMeta = [];
if (specRecord.fields?.version) {
  specMeta.push(`- Version: ${specRecord.fields.version}`);
}
if (specRecord.fields?.lastUpdated) {
  specMeta.push(`- Last Updated: ${specRecord.fields.lastUpdated}`);
}
if (specRecord.fields?.status) {
  specMeta.push(`- Status: ${specRecord.fields.status}`);
}

if (specMeta.length) {
  lines.push("");
  lines.push(...specMeta);
}

const specBody = getBody(specRecord).trim();
if (specBody) {
  lines.push("");
  lines.push(specBody);
}

const sectionRecords = sortRecords(getChildren(recordKey(specRecord))).filter(
  (record) => record.typeId === "section"
);

sectionRecords.forEach((section) => {
  const level = Number(section.fields?.level) || 2;
  lines.push("");
  lines.push(renderHeading(level, section.fields?.title || section.recordId));

  const sectionBody = getBody(section).trim();
  if (sectionBody) {
    lines.push("");
    lines.push(sectionBody);
  }

  const reqs = sortRecords(getChildren(recordKey(section))).filter(
    (record) => record.typeId === "req"
  );

  reqs.forEach((req) => {
    lines.push("");
    lines.push(`### ${req.recordId} — ${req.fields?.title || "Requirement"}`);
    const reqBody = getBody(req).trim();
    if (reqBody) {
      lines.push("");
      lines.push(reqBody);
    }
  });
});

const outputPath = path.join(rootDir, "SPEC.md");
fs.writeFileSync(outputPath, `${lines.join("\n")}\n`);

console.log(`Wrote ${outputPath}`);
