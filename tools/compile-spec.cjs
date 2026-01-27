const fs = require("fs");
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

function getRecords(snapshot) {
  if (!snapshot) {
    return [];
  }
  if (Array.isArray(snapshot.records)) {
    return snapshot.records;
  }
  if (snapshot.records && typeof snapshot.records === "object") {
    return Object.values(snapshot.records);
  }
  if (snapshot.recordsById && typeof snapshot.recordsById === "object") {
    return Object.values(snapshot.recordsById);
  }
  return [];
}

function getRecordId(record) {
  return record.recordId || record.id || record.record_id || "";
}

function getTypeId(record) {
  return record.typeId || record.type || record.type_id || "";
}

function getRecordKey(record) {
  const typeId = getTypeId(record);
  const recordId = getRecordId(record);
  return typeId && recordId ? `${typeId}:${recordId}` : "";
}

function getRecordBody(record) {
  return record.body || record.content || record.markdown || "";
}

function getRecordFields(record) {
  return record.fields || {};
}

function byOrderThenId(a, b) {
  const aFields = getRecordFields(a);
  const bFields = getRecordFields(b);
  const aOrder = Number.isFinite(Number(aFields.order))
    ? Number(aFields.order)
    : Number.POSITIVE_INFINITY;
  const bOrder = Number.isFinite(Number(bFields.order))
    ? Number(bFields.order)
    : Number.POSITIVE_INFINITY;

  if (aOrder !== bOrder) {
    return aOrder - bOrder;
  }

  return getRecordId(a).localeCompare(getRecordId(b));
}

function renderHeading(level, text) {
  const clamped = Math.min(Math.max(level, 1), 6);
  return `${"#".repeat(clamped)} ${text}`;
}

async function main() {
  const snapshot = await loadSnapshot();
  const validation = validateDatasetSnapshot(snapshot);
  if (Array.isArray(validation) && validation.length > 0) {
    throw new Error("GraphMD dataset validation failed before spec compilation.");
  }
  if (validation && validation.isValid === false) {
    throw new Error("GraphMD dataset validation failed before spec compilation.");
  }

  const records = getRecords(snapshot);
  const specRecord = records.find(
    (record) => getRecordKey(record) === "spec:ourbox-os-spec"
  );

  if (!specRecord) {
    throw new Error("Expected spec:ourbox-os-spec record was not found.");
  }

  const specFields = getRecordFields(specRecord);
  const specBody = getRecordBody(specRecord).trim();
  const specTitle = specFields.title || "OurBox OS Specification";

  const sections = records
    .filter((record) => record.parent === "spec:ourbox-os-spec")
    .sort(byOrderThenId);

  const recordByKey = new Map(records.map((record) => [getRecordKey(record), record]));

  const lines = [];
  lines.push(renderHeading(1, specTitle));
  if (specFields.version) {
    lines.push(`**Version:** ${specFields.version}`);
  }
  if (specFields.lastUpdated) {
    lines.push(`**Last Updated:** ${specFields.lastUpdated}`);
  }
  if (specFields.status) {
    lines.push(`**Status:** ${specFields.status}`);
  }
  if (specBody) {
    lines.push("");
    lines.push(specBody);
  }

  for (const section of sections) {
    const sectionFields = getRecordFields(section);
    const sectionTitle = sectionFields.title || getRecordId(section);
    const level = Number(sectionFields.level) || 2;
    lines.push("");
    lines.push(renderHeading(level, sectionTitle));

    const sectionBody = getRecordBody(section).trim();
    if (sectionBody) {
      lines.push("");
      lines.push(sectionBody);
    }

    const sectionKey = getRecordKey(section);
    const reqs = records
      .filter((record) => record.parent === sectionKey)
      .sort(byOrderThenId);

    for (const req of reqs) {
      const reqFields = getRecordFields(req);
      const reqTitle = reqFields.title || getRecordId(req);
      const reqId = getRecordId(req);
      lines.push("");
      lines.push(renderHeading(Math.min(level + 1, 6), `${reqId}: ${reqTitle}`));
      lines.push("");
      lines.push(`**Status:** ${reqFields.status || "Draft"}`);
      if (reqFields.testable !== undefined) {
        lines.push(`**Testable:** ${reqFields.testable}`);
      }
      if (reqFields.area) {
        lines.push(`**Area:** ${reqFields.area}`);
      }
      if (reqFields.rationale) {
        lines.push(`**Rationale:** ${reqFields.rationale}`);
      }
      const reqBody = getRecordBody(req).trim();
      if (reqBody) {
        lines.push("");
        lines.push(reqBody);
      }
    }
  }

  const output = `${lines.join("\n")}\n`;
  fs.writeFileSync(path.join(process.cwd(), "SPEC.md"), output);

  if (!recordByKey.size) {
    throw new Error("GraphMD dataset did not produce any records.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
