const fs = require("node:fs");
const path = require("node:path");

const dataset = require("@graphmd/dataset");

const loadDatasetSnapshot =
  dataset.loadDatasetSnapshot ||
  dataset.loadDatasetSnapshotSync ||
  dataset.loadDataset ||
  dataset.loadDatasetSnapshotFromDir;
const validateDatasetSnapshot =
  dataset.validateDatasetSnapshot ||
  dataset.validateDataset ||
  dataset.validateSnapshot;

if (!loadDatasetSnapshot || !validateDatasetSnapshot) {
  throw new Error("@graphmd/dataset API mismatch: missing loader/validator.");
}

const datasetDirs = ["types", "records", "blocks", "plugins"];

const loadSnapshot = async () => {
  const rootDir = process.cwd();
  const optionCandidates = [
    { rootDir, directories: datasetDirs },
    { rootDir, dirs: datasetDirs },
    { rootDir, includeDirs: datasetDirs },
    { rootDir, include: datasetDirs },
  ];

  for (const options of optionCandidates) {
    try {
      const snapshot = loadDatasetSnapshot(options);
      return snapshot?.then ? await snapshot : snapshot;
    } catch (error) {
      // Try next signature.
    }
  }

  try {
    const snapshot = loadDatasetSnapshot(rootDir, datasetDirs);
    return snapshot?.then ? await snapshot : snapshot;
  } catch (error) {
    const snapshot = loadDatasetSnapshot(rootDir);
    return snapshot?.then ? await snapshot : snapshot;
  }
};

const ensureValidSnapshot = async (snapshot) => {
  const result = await Promise.resolve(validateDatasetSnapshot(snapshot));

  if (
    result === true ||
    result?.ok === true ||
    result?.valid === true ||
    (Array.isArray(result?.errors) && result.errors.length === 0)
  ) {
    return;
  }

  const errors = result?.errors || result;
  throw new Error(
    `GraphMD dataset validation failed. ${JSON.stringify(errors, null, 2)}`
  );
};

const parseYamlFrontMatter = (raw) => {
  const lines = raw.split(/\r?\n/);
  const root = {};
  const stack = [{ indent: -1, obj: root }];

  for (const line of lines) {
    if (!line.trim() || line.trim().startsWith("#")) {
      continue;
    }
    const match = line.match(/^(\s*)([^:]+):\s*(.*)$/);
    if (!match) {
      continue;
    }
    const indent = match[1].length;
    const key = match[2].trim();
    const rawValue = match[3].trim();

    while (stack.length && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }

    const parent = stack[stack.length - 1].obj;

    if (!rawValue) {
      const child = {};
      parent[key] = child;
      stack.push({ indent, obj: child });
      continue;
    }

    let value = rawValue;
    if (
      (value.startsWith("\"") && value.endsWith("\"")) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    } else if (value === "true" || value === "false") {
      value = value === "true";
    } else if (!Number.isNaN(Number(value))) {
      value = Number(value);
    }

    parent[key] = value;
  }

  return root;
};

const parseRecordFile = (filePath) => {
  const content = fs.readFileSync(filePath, "utf8");
  if (!content.startsWith("---")) {
    throw new Error(`Record missing front matter: ${filePath}`);
  }

  const lines = content.split(/\r?\n/);
  let frontMatterEnd = -1;
  for (let i = 1; i < lines.length; i += 1) {
    if (lines[i].trim() === "---") {
      frontMatterEnd = i;
      break;
    }
  }

  if (frontMatterEnd === -1) {
    throw new Error(`Record missing front matter end: ${filePath}`);
  }

  const frontMatter = lines.slice(1, frontMatterEnd).join("\n");
  const body = lines.slice(frontMatterEnd + 1).join("\n").trim();
  const data = parseYamlFrontMatter(frontMatter);

  return {
    ...data,
    body,
    filePath,
  };
};

const collectMarkdownFiles = (dir) => {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const resolved = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectMarkdownFiles(resolved));
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(resolved);
    }
  }
  return files;
};

const sortByOrderThenId = (records) =>
  [...records].sort((a, b) => {
    const orderA = Number.isFinite(a.fields?.order)
      ? Number(a.fields.order)
      : Number.POSITIVE_INFINITY;
    const orderB = Number.isFinite(b.fields?.order)
      ? Number(b.fields.order)
      : Number.POSITIVE_INFINITY;

    if (orderA !== orderB) {
      return orderA - orderB;
    }

    return String(a.recordId).localeCompare(String(b.recordId));
  });

const renderSpec = (records) => {
  const specRecords = records.filter(
    (record) => record.typeId === "spec" && record.recordId === "ourbox-os-spec"
  );

  if (specRecords.length !== 1) {
    throw new Error(
      `Expected exactly one spec:ourbox-os-spec record, found ${specRecords.length}.`
    );
  }

  const spec = specRecords[0];
  const lines = [];

  lines.push(`# ${spec.fields?.title || "OurBox OS Specification"}`);
  lines.push("");

  if (spec.fields?.version) {
    lines.push(`- Version: ${spec.fields.version}`);
  }
  if (spec.fields?.lastUpdated) {
    lines.push(`- Last Updated: ${spec.fields.lastUpdated}`);
  }
  if (spec.fields?.status) {
    lines.push(`- Status: ${spec.fields.status}`);
  }

  if (spec.fields?.version || spec.fields?.lastUpdated || spec.fields?.status) {
    lines.push("");
  }

  if (spec.body) {
    lines.push(spec.body);
    lines.push("");
  }

  const sections = sortByOrderThenId(
    records.filter(
      (record) =>
        record.typeId === "section" &&
        record.parent === `spec:${spec.recordId}`
    )
  );

  for (const section of sections) {
    const level = Number.isFinite(section.fields?.level)
      ? Number(section.fields.level)
      : 2;
    const headingPrefix = "#".repeat(Math.max(level, 2));
    lines.push(`${headingPrefix} ${section.fields?.title || section.recordId}`);
    lines.push("");

    if (section.body) {
      lines.push(section.body);
      lines.push("");
    }

    const requirements = sortByOrderThenId(
      records.filter(
        (record) =>
          record.typeId === "req" &&
          record.parent === `section:${section.recordId}`
      )
    );

    for (const requirement of requirements) {
      lines.push(
        `### ${requirement.recordId} — ${
          requirement.fields?.title || "Untitled requirement"
        }`
      );
      lines.push("");
      if (requirement.body) {
        lines.push(requirement.body);
        lines.push("");
      }
    }
  }

  return `${lines.join("\n").trim()}\n`;
};

const compileSpec = async () => {
  const snapshot = await loadSnapshot();
  await ensureValidSnapshot(snapshot);

  const recordFiles = collectMarkdownFiles(path.join(process.cwd(), "records"));
  const records = recordFiles.map(parseRecordFile);

  const specOutput = renderSpec(records);
  fs.writeFileSync(path.join(process.cwd(), "SPEC.md"), specOutput);
};

compileSpec().catch((error) => {
  console.error(error);
  process.exit(1);
});
