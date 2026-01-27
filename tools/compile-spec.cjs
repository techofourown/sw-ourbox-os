/* eslint-disable no-console */
const fs = require("node:fs");
const path = require("node:path");

const { validateDatasetSnapshot, parseGraphMDFile } = require("@graphmd/dataset");

const ROOT = path.resolve(__dirname, "..");
const OUT_PATH = path.join(ROOT, "SPEC.md");
const DATASET_DIRS = ["types", "records", "blocks", "plugins"];
const SKIP_DIRS = new Set([".git", "node_modules"]);

function walk(absDir, relDir, files) {
  const entries = fs.readdirSync(absDir, { withFileTypes: true });
  for (const e of entries) {
    if (SKIP_DIRS.has(e.name)) continue;
    const abs = path.join(absDir, e.name);
    const rel = path.posix.join(relDir, e.name);
    if (e.isDirectory()) walk(abs, rel, files);
    else if (e.isFile()) files.set(rel, fs.readFileSync(abs));
  }
}

function loadSnapshot(root) {
  const files = new Map();
  for (const dir of DATASET_DIRS) {
    const abs = path.join(root, dir);
    if (!fs.existsSync(abs)) continue;
    walk(abs, dir, files);
  }
  return { files };
}

function numOrder(fields) {
  const v = fields?.order;
  if (v === undefined || v === null) return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function sortSiblings(a, b) {
  const oa = numOrder(a.fields);
  const ob = numOrder(b.fields);
  if (oa !== null && ob !== null && oa !== ob) return oa - ob;
  if (oa !== null && ob === null) return -1;
  if (oa === null && ob !== null) return 1;
  return String(a.recordId).localeCompare(String(b.recordId));
}

function clampHeadingLevel(levelRaw, fallback) {
  const n = Number(levelRaw);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(Math.max(n, 2), 6);
}

function main() {
  const snapshot = loadSnapshot(ROOT);

  // Validate first.
  const validation = validateDatasetSnapshot(snapshot);
  if (!validation || validation.ok !== true) {
    console.error("❌ DATASET INVALID (GraphMD validator)");
    console.error(JSON.stringify(validation, null, 2));
    process.exit(1);
  }

  // Parse all record objects.
  const records = [];
  for (const [filePath, bytes] of snapshot.files.entries()) {
    const parsed = parseGraphMDFile(filePath, bytes);
    if (parsed.kind === "record") records.push(parsed);
  }

  const byIdentity = new Map(records.map((r) => [r.identity, r]));
  const spec = byIdentity.get("spec:ourbox-os-spec");
  if (!spec) {
    console.error('FATAL: missing required spec record "spec:ourbox-os-spec".');
    process.exit(1);
  }

  // Build children map.
  const childrenByParent = new Map();
  for (const r of records) {
    if (!r.parent) continue;
    if (!childrenByParent.has(r.parent)) childrenByParent.set(r.parent, []);
    childrenByParent.get(r.parent).push(r);
  }
  for (const kids of childrenByParent.values()) kids.sort(sortSiblings);

  const renderReq = (r) => {
    const title = r.fields?.title ?? "";
    const body = String(r.body ?? "").replace(/^\n+/, "").trimEnd();
    const head = `### ${r.recordId} — ${title}`;
    return body ? `${head}\n\n${body}` : head;
  };

  const renderSection = (r) => {
    const level = clampHeadingLevel(r.fields?.level, 2);
    const heading = `${"#".repeat(level)} ${r.fields?.title ?? r.recordId}`;
    const body = String(r.body ?? "").replace(/^\n+/, "").trimEnd();

    const blocks = [];
    blocks.push(body ? `${heading}\n\n${body}` : heading);

    const kids = childrenByParent.get(r.identity) ?? [];
    for (const child of kids) {
      if (child.typeId === "section") blocks.push(renderSection(child));
      else if (child.typeId === "req") blocks.push(renderReq(child));
    }
    return blocks.join("\n\n");
  };

  // Render header
  const lines = [];
  lines.push(`# ${spec.fields?.title ?? "OurBox OS Specification"}`);
  lines.push("");
  if (spec.fields?.version) lines.push(`**Spec Version:** ${spec.fields.version}`);
  if (spec.fields?.lastUpdated) lines.push(`**Last Updated:** ${spec.fields.lastUpdated}`);
  if (spec.fields?.status) lines.push(`**Status:** ${spec.fields.status}`);
  lines.push("");

  const specBody = String(spec.body ?? "").replace(/^\n+/, "").trimEnd();
  if (specBody) lines.push(specBody);

  const top = childrenByParent.get(spec.identity) ?? [];
  for (const child of top) {
    if (child.typeId === "section") lines.push(renderSection(child));
  }

  const out = `\n${lines.join("\n\n").trimEnd()}\n`;
  fs.writeFileSync(OUT_PATH, out);
  console.log("SPEC.md generated.");
}

main();
