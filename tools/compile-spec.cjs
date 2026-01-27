const fs = require("fs");
const path = require("path");
const {
  loadDatasetSnapshot,
  validateDatasetSnapshot,
} = require("@graphmd/dataset");

const datasetRoot = path.resolve(__dirname, "..");

function loadSnapshot() {
  return loadDatasetSnapshot({
    datasetRoot,
    typesPath: path.join(datasetRoot, "types"),
    recordsPath: path.join(datasetRoot, "records"),
    blocksPath: path.join(datasetRoot, "blocks"),
    pluginsPath: path.join(datasetRoot, "plugins"),
  });
}

function parseValue(value) {
  if (
    (value.startsWith("\"") && value.endsWith("\"")) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  if (/^-?\d+(\.\d+)?$/.test(value)) {
    return Number(value);
  }
  if (value === "true") return true;
  if (value === "false") return false;
  return value;
}

function parseFrontMatter(content, filePath) {
  if (!content.startsWith("---")) {
    throw new Error(`Missing front matter in ${filePath}`);
  }
  const lines = content.split(/\r?\n/);
  let endIndex = -1;
  for (let i = 1; i < lines.length; i += 1) {
    if (lines[i].trim() === "---") {
      endIndex = i;
      break;
    }
  }
  if (endIndex === -1) {
    throw new Error(`Unterminated front matter in ${filePath}`);
  }
  const yamlLines = lines.slice(1, endIndex);
  const body = lines.slice(endIndex + 1).join("\n").trim();

  const root = {};
  const stack = [{ indent: -1, obj: root }];

  for (const line of yamlLines) {
    if (!line.trim()) continue;
    const match = /^(\s*)([^:]+):\s*(.*)$/.exec(line);
    if (!match) continue;
    const indent = match[1].length;
    const key = match[2].trim();
    const rawValue = match[3].trim();

    while (stack.length > 1 && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }

    const parent = stack[stack.length - 1].obj;
    if (!rawValue) {
      parent[key] = {};
      stack.push({ indent, obj: parent[key] });
    } else {
      parent[key] = parseValue(rawValue);
    }
  }

  return { frontMatter: root, body };
}

function readRecords(recordsRoot) {
  const records = [];
  const entries = fs.readdirSync(recordsRoot, { withFileTypes: true });
  for (const entry of entries) {
    const entryPath = path.join(recordsRoot, entry.name);
    if (entry.isDirectory()) {
      records.push(...readRecords(entryPath));
      continue;
    }
    if (!entry.isFile() || !entry.name.endsWith(".md")) continue;
    const content = fs.readFileSync(entryPath, "utf8");
    const { frontMatter, body } = parseFrontMatter(content, entryPath);
    records.push({
      filePath: path.relative(datasetRoot, entryPath),
      typeId: frontMatter.typeId,
      recordId: frontMatter.recordId,
      parent: frontMatter.parent,
      fields: frontMatter.fields || {},
      body,
    });
  }
  return records;
}

function orderValue(record) {
  const order = record.fields?.order;
  const num = Number(order);
  return Number.isFinite(num) ? num : Number.POSITIVE_INFINITY;
}

const snapshot = loadSnapshot();
const validation = validateDatasetSnapshot(snapshot);
const isValid =
  validation === true ||
  validation?.ok === true ||
  validation?.valid === true ||
  validation?.isValid === true;

if (!isValid) {
  console.error("GraphMD dataset validation failed; SPEC.md was not generated.");
  if (Array.isArray(validation)) {
    console.error(validation);
  } else if (validation?.errors) {
    console.error(validation.errors);
  } else if (validation?.issues) {
    console.error(validation.issues);
  } else if (validation) {
    console.error(validation);
  }
  process.exit(1);
}

const records = readRecords(path.join(datasetRoot, "records"));
const specRecords = records.filter(
  (record) => record.typeId === "spec" && record.recordId === "ourbox-os-spec"
);

if (specRecords.length !== 1) {
  throw new Error(
    `Expected exactly one spec:ourbox-os-spec record, found ${specRecords.length}.`
  );
}

const spec = specRecords[0];
const sections = records
  .filter((record) => record.typeId === "section" && record.parent === `spec:${spec.recordId}`)
  .sort((a, b) => {
    const orderDiff = orderValue(a) - orderValue(b);
    if (orderDiff !== 0) return orderDiff;
    return a.recordId.localeCompare(b.recordId);
  });

const lines = [];
lines.push(`# ${spec.fields?.title || spec.recordId}`);
lines.push("");
lines.push(`Version: ${spec.fields?.version || "Unspecified"}`);
lines.push(`Status: ${spec.fields?.status || "Unspecified"}`);
lines.push(`Last Updated: ${spec.fields?.lastUpdated || "Unspecified"}`);
lines.push("");
if (spec.body) {
  lines.push(spec.body);
  lines.push("");
}

for (const section of sections) {
  const level = Number(section.fields?.level ?? 2);
  const headingLevel = Math.min(Math.max(level, 2), 6);
  lines.push(`${"#".repeat(headingLevel)} ${section.fields?.title || section.recordId}`);
  lines.push("");
  if (section.body) {
    lines.push(section.body);
    lines.push("");
  }

  const reqs = records
    .filter(
      (record) =>
        record.typeId === "req" && record.parent === `section:${section.recordId}`
    )
    .sort((a, b) => {
      const orderDiff = orderValue(a) - orderValue(b);
      if (orderDiff !== 0) return orderDiff;
      return a.recordId.localeCompare(b.recordId);
    });

  for (const req of reqs) {
    lines.push(`### ${req.recordId} — ${req.fields?.title || ""}`.trim());
    lines.push("");
    if (req.body) {
      lines.push(req.body);
      lines.push("");
    }
  }
}

const output = `${lines.join("\n").trim()}\n`;
fs.writeFileSync(path.join(datasetRoot, "SPEC.md"), output, "utf8");
