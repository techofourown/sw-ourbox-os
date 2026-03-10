#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

function loadJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function validateValue(schemaRoot, schemaNode, value, instancePath, errors) {
  if (!schemaNode || typeof schemaNode !== 'object') return;

  if (schemaNode.$ref) {
    const ref = schemaNode.$ref;
    if (!ref.startsWith('#/')) {
      errors.push(`${instancePath}: unsupported $ref ${ref}`);
      return;
    }
    const parts = ref.slice(2).split('/');
    let target = schemaRoot;
    for (const part of parts) target = target?.[part];
    if (!target) {
      errors.push(`${instancePath}: missing ref target ${ref}`);
      return;
    }
    validateValue(schemaRoot, target, value, instancePath, errors);
    return;
  }

  if (schemaNode.const !== undefined && value !== schemaNode.const) {
    errors.push(`${instancePath}: must equal constant ${JSON.stringify(schemaNode.const)}`);
  }

  if (schemaNode.type === 'object') {
    if (value === null || typeof value !== 'object' || Array.isArray(value)) {
      errors.push(`${instancePath}: must be an object`);
      return;
    }

    const required = schemaNode.required || [];
    for (const key of required) {
      if (!(key in value)) errors.push(`${instancePath}: missing required property '${key}'`);
    }

    const properties = schemaNode.properties || {};
    for (const [key, child] of Object.entries(properties)) {
      if (key in value) validateValue(schemaRoot, child, value[key], `${instancePath}/${key}`, errors);
    }

    const extras = Object.keys(value).filter((k) => !(k in properties));
    if (schemaNode.additionalProperties === false && extras.length > 0) {
      for (const extra of extras) errors.push(`${instancePath}: additional property '${extra}' is not allowed`);
    } else if (schemaNode.additionalProperties && typeof schemaNode.additionalProperties === 'object') {
      for (const extra of extras) {
        validateValue(schemaRoot, schemaNode.additionalProperties, value[extra], `${instancePath}/${extra}`, errors);
      }
    }
  }

  if (schemaNode.type === 'string') {
    if (typeof value !== 'string') {
      errors.push(`${instancePath}: must be a string`);
      return;
    }
    if (schemaNode.minLength !== undefined && value.length < schemaNode.minLength) {
      errors.push(`${instancePath}: must have minLength ${schemaNode.minLength}`);
    }
    if (schemaNode.pattern !== undefined) {
      const re = new RegExp(schemaNode.pattern);
      if (!re.test(value)) errors.push(`${instancePath}: must match pattern ${schemaNode.pattern}`);
    }
    if (schemaNode.enum && !schemaNode.enum.includes(value)) {
      errors.push(`${instancePath}: must be one of ${schemaNode.enum.join(', ')}`);
    }
  }
}

function validateFile(schemaPath, filePath) {
  const schema = loadJson(schemaPath);
  const data = loadJson(filePath);
  const errors = [];
  validateValue(schema, schema, data, '/', errors);
  if (errors.length) {
    console.error(`Schema validation failed for ${filePath}`);
    for (const error of errors) console.error(`- ${error}`);
    return false;
  }
  console.log(`Validated ${filePath} against ${schemaPath}`);
  return true;
}

function assertNoRootGeneratedRequirements(repoRoot) {
  const rootFiles = fs.readdirSync(repoRoot, { withFileTypes: true }).filter((d) => d.isFile()).map((d) => d.name);
  const offenders = rootFiles.filter((name) =>
    /^SRS-.*\.md$/.test(name) || /^SyRS-.*\.md$/.test(name) || name === 'OurBox-OS-Requirements-Omnibus.md'
  );
  if (offenders.length > 0) {
    console.error('Root cleanliness check failed; generated requirements artifacts found at repo root:');
    for (const offender of offenders) console.error(`- ${offender}`);
    return false;
  }
  console.log('Verified: no generated requirements artifacts at repository root.');
  return true;
}

function resolveRepoPath(repoRoot, value) {
  return path.isAbsolute(value) ? value : path.resolve(repoRoot, value);
}

function main() {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const args = process.argv.slice(2);

  const approvedInputs = [];
  const publishRecordFiles = [];
  let discoverPublishRecords = false;
  let checkRootGeneratedClean = false;

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--approved-upstream-inputs' && args[i + 1]) {
      approvedInputs.push(resolveRepoPath(repoRoot, args[i + 1]));
      i += 1;
      continue;
    }
    if (arg === '--publish-record' && args[i + 1]) {
      publishRecordFiles.push(resolveRepoPath(repoRoot, args[i + 1]));
      i += 1;
      continue;
    }
    if (arg === '--discover-publish-records') {
      discoverPublishRecords = true;
      continue;
    }
    if (arg === '--check-root-generated-clean') {
      checkRootGeneratedClean = true;
      continue;
    }
  }

  const noTargets = approvedInputs.length === 0 && publishRecordFiles.length === 0 && !discoverPublishRecords;
  if (noTargets) {
    approvedInputs.push(path.resolve(repoRoot, 'release', 'approved-upstream-inputs.json'));
    discoverPublishRecords = true;
  }

  let ok = true;

  for (const approvedPath of approvedInputs) {
    ok = validateFile(path.resolve(repoRoot, 'schemas', 'approved-upstream-inputs.schema.json'), approvedPath) && ok;
  }

  const discovered = [];
  if (discoverPublishRecords) {
    const distDir = path.resolve(repoRoot, 'dist');
    if (fs.existsSync(distDir)) {
      discovered.push(...fs.readdirSync(distDir)
        .filter((f) => f.endsWith('.publish-record.json'))
        .map((f) => path.resolve(distDir, f)));
    }
  }

  const targets = [...new Set([...publishRecordFiles, ...discovered])];
  for (const target of targets) {
    ok = validateFile(path.resolve(repoRoot, 'schemas', 'artifact-publish-record.schema.json'), target) && ok;
  }

  if (checkRootGeneratedClean) {
    ok = assertNoRootGeneratedRequirements(repoRoot) && ok;
  }

  if (!ok) process.exit(1);
}

main();
