const fs = require("fs");
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

const records = Array.isArray(snapshot.records)
  ? snapshot.records
  : Object.values(snapshot.records || {});

const recordKey = (record) => {
  const typeId = record.typeId || record.type;
  const recordId = record.recordId || record.id || record.record_id;
  return `${typeId}:${recordId}`;
};

const getParentKey = (record) => {
  const parent = record.parent;
  if (!parent) {
    return null;
  }
  if (typeof parent === "string") {
    return parent;
  }
  const typeId = parent.typeId || parent.type;
  const recordId = parent.recordId || parent.id || parent.record_id;
  if (typeId && recordId) {
    return `${typeId}:${recordId}`;
  }
  return null;
};

const getRecordId = (record) =>
  record.recordId || record.id || record.record_id || "";

const getRecordBody = (record) =>
  (record.body || record.markdown || record.content || "").trim();

const recordMap = new Map();
for (const record of records) {
  recordMap.set(recordKey(record), record);
}

const specRecords = records.filter((record) => record.typeId === "spec");
const specRecord = recordMap.get("spec:ourbox-os-spec");
if (!specRecord || specRecords.length !== 1) {
  console.error(
    "Expected exactly one spec record with id spec:ourbox-os-spec.",
  );
  process.exit(1);
}

const childrenByParent = new Map();
for (const record of records) {
  const parentKey = getParentKey(record);
  if (!parentKey) {
    continue;
  }
  if (!childrenByParent.has(parentKey)) {
    childrenByParent.set(parentKey, []);
  }
  childrenByParent.get(parentKey).push(record);
}

const sortByOrder = (a, b) => {
  const orderA = Number(a.fields?.order ?? Number.POSITIVE_INFINITY);
  const orderB = Number(b.fields?.order ?? Number.POSITIVE_INFINITY);
  if (orderA !== orderB) {
    return orderA - orderB;
  }
  return getRecordId(a).localeCompare(getRecordId(b));
};

const renderSection = (section) => {
  const level = Number(section.fields?.level ?? 2);
  const heading = "#".repeat(Math.max(2, level));
  const title = section.fields?.title || getRecordId(section);
  const lines = [`${heading} ${title}`];
  const body = getRecordBody(section);
  if (body) {
    lines.push("", body);
  }
  const reqs = (childrenByParent.get(recordKey(section)) || []).filter(
    (record) => record.typeId === "req",
  );
  reqs.sort(sortByOrder);
  for (const req of reqs) {
    const reqTitle = req.fields?.title || getRecordId(req);
    lines.push("", `### ${getRecordId(req)} — ${reqTitle}`);
    const reqBody = getRecordBody(req);
    if (reqBody) {
      lines.push("", reqBody);
    }
  }
  return lines.join("\n");
};

const specTitle = specRecord.fields?.title || "OurBox OS Specification";
const specLines = [`# ${specTitle}`];
if (specRecord.fields?.version) {
  specLines.push(`*Version:* ${specRecord.fields.version}`);
}
if (specRecord.fields?.status) {
  specLines.push(`*Status:* ${specRecord.fields.status}`);
}
if (specRecord.fields?.lastUpdated) {
  specLines.push(`*Last Updated:* ${specRecord.fields.lastUpdated}`);
}
const specBody = getRecordBody(specRecord);
if (specBody) {
  specLines.push("", specBody);
}

const sections = (childrenByParent.get(recordKey(specRecord)) || []).filter(
  (record) => record.typeId === "section",
);
sections.sort(sortByOrder);
for (const section of sections) {
  specLines.push("", renderSection(section));
}

const output = `${specLines.join("\n")}\n`;
fs.writeFileSync(path.join(datasetRoot, "SPEC.md"), output, "utf8");
console.log("Wrote SPEC.md");
