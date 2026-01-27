const fs = require("fs");
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

const records = Array.isArray(snapshot.records)
  ? snapshot.records
  : snapshot.records && typeof snapshot.records === "object"
    ? Object.values(snapshot.records)
    : [];

const recordKey = (record) => `${record.typeId}:${record.recordId}`;

const getBody = (record) =>
  record.body ?? record.markdown ?? record.content ?? record.text ?? "";

const specRecord = records.find(
  (record) => record.typeId === "spec" && record.recordId === "ourbox-os-spec"
);

if (!specRecord) {
  console.error("Missing spec:ourbox-os-spec record.");
  process.exit(1);
}

const childrenByParent = new Map();
for (const record of records) {
  if (!record.parent) continue;
  const parentKey = record.parent;
  if (!childrenByParent.has(parentKey)) {
    childrenByParent.set(parentKey, []);
  }
  childrenByParent.get(parentKey).push(record);
}

const sortByOrder = (a, b) => {
  const orderA = a.fields?.order ?? 0;
  const orderB = b.fields?.order ?? 0;
  if (orderA !== orderB) return orderA - orderB;
  return a.recordId.localeCompare(b.recordId);
};

const lines = [];
const specTitle = specRecord.fields?.title ?? "OurBox OS Specification";
lines.push(`# ${specTitle}`);
lines.push("");
lines.push(`- Version: ${specRecord.fields?.version ?? ""}`.trim());
lines.push(`- Last Updated: ${specRecord.fields?.lastUpdated ?? ""}`.trim());
lines.push(`- Status: ${specRecord.fields?.status ?? ""}`.trim());
lines.push("");

const specBody = getBody(specRecord).trim();
if (specBody) {
  lines.push(specBody);
  lines.push("");
}

const sections = (childrenByParent.get(recordKey(specRecord)) ?? []).sort(sortByOrder);

for (const section of sections) {
  const sectionTitle = section.fields?.title ?? section.recordId;
  lines.push(`## ${sectionTitle}`);
  lines.push("");
  const sectionBody = getBody(section).trim();
  if (sectionBody) {
    lines.push(sectionBody);
    lines.push("");
  }

  const reqs = (childrenByParent.get(recordKey(section)) ?? []).sort(sortByOrder);
  for (const req of reqs) {
    const reqTitle = req.fields?.title ?? req.recordId;
    lines.push(`### ${req.recordId}: ${reqTitle}`);
    lines.push("");
    const reqBody = getBody(req).trim();
    if (reqBody) {
      lines.push(reqBody);
      lines.push("");
    }
    if (req.fields) {
      lines.push(`- Testable: ${req.fields.testable ?? ""}`.trim());
      lines.push(`- Status: ${req.fields.status ?? ""}`.trim());
      lines.push(`- Rationale: ${req.fields.rationale ?? ""}`.trim());
      lines.push("");
    }
  }
}

const outputPath = path.join(datasetRoot, "SPEC.md");
fs.writeFileSync(outputPath, `${lines.join("\n").trim()}\n`);
console.log(`Wrote ${outputPath}`);
