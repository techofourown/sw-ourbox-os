const fs = require("fs");
const path = require("path");

const dataset = require("@graphmd/dataset");

const loadDatasetSnapshot =
  dataset.loadDatasetSnapshot ||
  dataset.loadDatasetSnapshotFromDirs ||
  dataset.loadDatasetSnapshotFromDir ||
  dataset.loadDatasetSnapshotFromPaths;
const validateDatasetSnapshot =
  dataset.validateDatasetSnapshot || dataset.validateDatasetSnapshotStrict;

if (!loadDatasetSnapshot || !validateDatasetSnapshot) {
  throw new Error(
    "@graphmd/dataset does not expose the expected snapshot loader/validator functions."
  );
}

const CANONICAL_DIRS = ["types", "records", "blocks", "plugins"];
const DATASET_ROOT = path.resolve(__dirname, "..");

const tryLoadSnapshot = () => {
  const attempts = [
    () => loadDatasetSnapshot({ datasetPath: DATASET_ROOT, dirNames: CANONICAL_DIRS }),
    () => loadDatasetSnapshot({ datasetPath: DATASET_ROOT, directories: CANONICAL_DIRS }),
    () => loadDatasetSnapshot({ datasetPath: DATASET_ROOT, include: CANONICAL_DIRS }),
    () => loadDatasetSnapshot(DATASET_ROOT, CANONICAL_DIRS),
    () => loadDatasetSnapshot(DATASET_ROOT, { dirNames: CANONICAL_DIRS }),
    () => loadDatasetSnapshot({ datasetRoot: DATASET_ROOT, dirNames: CANONICAL_DIRS }),
  ];

  let lastError;
  for (const attempt of attempts) {
    try {
      return attempt();
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError;
};

const snapshot = tryLoadSnapshot();

let validation;
try {
  validation = validateDatasetSnapshot(snapshot);
} catch (error) {
  console.error("Dataset validation threw an error:");
  console.error(error);
  process.exit(1);
}

if (!(validation === true || validation?.ok === true || validation?.valid === true)) {
  console.error("Dataset validation failed.");
  if (validation?.errors) {
    console.error(JSON.stringify(validation.errors, null, 2));
  }
  process.exit(1);
}

const parseFrontMatter = (content) => {
  const parts = content.split("---");
  if (parts.length < 3) {
    throw new Error("Missing front matter block.");
  }
  const frontMatter = parts[1];
  const body = parts.slice(2).join("---").replace(/^\n+/, "");

  const lines = frontMatter.split(/\r?\n/);
  const root = {};
  const stack = [{ indent: -1, obj: root }];

  for (const rawLine of lines) {
    const line = rawLine.replace(/\t/g, "  ");
    if (!line.trim() || line.trim().startsWith("#")) {
      continue;
    }
    const indent = line.match(/^\s*/)[0].length;
    while (stack.length && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }
    const current = stack[stack.length - 1].obj;
    const match = line.match(/^\s*([^:]+):(.*)$/);
    if (!match) {
      continue;
    }
    const key = match[1].trim();
    let value = match[2].trim();
    if (!value) {
      const nested = {};
      current[key] = nested;
      stack.push({ indent, obj: nested });
      continue;
    }
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    } else if (value === "true" || value === "false") {
      value = value === "true";
    } else if (!Number.isNaN(Number(value))) {
      value = Number(value);
    }
    current[key] = value;
  }

  return { frontMatter: root, body: body.trim() };
};

const collectMarkdownFiles = (dir) => {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectMarkdownFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(fullPath);
    }
  }
  return files;
};

const recordsDir = path.join(DATASET_ROOT, "records");
const recordFiles = collectMarkdownFiles(recordsDir);
const records = recordFiles.map((file) => {
  const content = fs.readFileSync(file, "utf8");
  const { frontMatter, body } = parseFrontMatter(content);
  return {
    ...frontMatter,
    body,
    file,
  };
});

const recordKey = (record) => `${record.typeId}:${record.recordId}`;
const recordMap = new Map(records.map((record) => [recordKey(record), record]));

const specRecord = recordMap.get("spec:ourbox-os-spec");
if (!specRecord) {
  console.error("spec:ourbox-os-spec record not found.");
  process.exit(1);
}

const getChildren = (parentKey) =>
  records.filter((record) => record.parent === parentKey);

const sortRecords = (list) =>
  [...list].sort((a, b) => {
    const orderA = a.fields?.order ?? 0;
    const orderB = b.fields?.order ?? 0;
    if (orderA !== orderB) {
      return orderA - orderB;
    }
    return (a.recordId || "").localeCompare(b.recordId || "");
  });

const sections = sortRecords(getChildren("spec:ourbox-os-spec"));

const lines = [];
lines.push(`# ${specRecord.fields?.title || "OurBox OS Specification"}`);
lines.push("");
lines.push(`**Version:** ${specRecord.fields?.version || ""}`.trim());
lines.push(`**Last Updated:** ${specRecord.fields?.lastUpdated || ""}`.trim());
lines.push(`**Status:** ${specRecord.fields?.status || ""}`.trim());
lines.push("");
if (specRecord.body) {
  lines.push(specRecord.body);
  lines.push("");
}

for (const section of sections) {
  const level = Number(section.fields?.level ?? 1);
  const headingLevel = Math.min(6, 1 + level);
  const heading = "#".repeat(headingLevel);
  lines.push(`${heading} ${section.fields?.title || section.recordId}`);
  lines.push("");
  if (section.body) {
    lines.push(section.body);
    lines.push("");
  }

  const requirements = sortRecords(getChildren(`section:${section.recordId}`));
  for (const req of requirements) {
    const reqHeadingLevel = Math.min(6, headingLevel + 1);
    const reqHeading = "#".repeat(reqHeadingLevel);
    lines.push(`${reqHeading} ${req.recordId}: ${req.fields?.title || "Requirement"}`);
    lines.push("");
    lines.push(`**Requirement ID:** ${req.recordId}`);
    lines.push(`**Status:** ${req.fields?.status || ""}`.trim());
    lines.push(`**Area:** ${req.fields?.area || ""}`.trim());
    if (req.fields?.rationale) {
      lines.push(`**Rationale:** ${req.fields.rationale}`);
    }
    lines.push("");
    if (req.body) {
      lines.push(req.body);
      lines.push("");
    }
  }
}

const outputPath = path.join(DATASET_ROOT, "SPEC.md");
fs.writeFileSync(outputPath, lines.join("\n").replace(/\n{3,}/g, "\n\n"));
