const HEX64 = /^[0-9a-f]{64}$/;
const SHA = /^sha256:[0-9a-f]{64}$/;
const COMMIT = /^[0-9a-f]{40}$/;
const UTC = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;

function isObj(v) { return v && typeof v === 'object' && !Array.isArray(v); }
function must(cond, msg, errors) { if (!cond) errors.push(msg); }

function validateApprovedUpstreamInputs(data) {
  const e = [];
  must(isObj(data), 'root must be object', e);
  if (!isObj(data)) return e;
  const keys = ['schema','source_repo','approved_release_tag','platform_contract','airgap_platform'];
  for (const k of keys) must(k in data, `missing ${k}`, e);
  must(data.schema === 1, 'schema must be 1', e);
  must(typeof data.source_repo === 'string' && data.source_repo.length > 0, 'source_repo invalid', e);
  must(typeof data.approved_release_tag === 'string' && /^v.+$/.test(data.approved_release_tag), 'approved_release_tag invalid', e);

  const checkRefSet = (x, name) => {
    must(isObj(x), `${name} must be object`, e);
    if (!isObj(x)) return;
    must(typeof x.versioned_ref === 'string' && x.versioned_ref.length > 0, `${name}.versioned_ref invalid`, e);
    must(typeof x.pinned_ref === 'string' && x.pinned_ref.length > 0, `${name}.pinned_ref invalid`, e);
    must(typeof x.digest === 'string' && SHA.test(x.digest), `${name}.digest invalid`, e);
  };

  if (isObj(data.platform_contract)) {
    checkRefSet(data.platform_contract, 'platform_contract');
    must(typeof data.platform_contract.required_route_marker === 'string' && data.platform_contract.required_route_marker.length > 0, 'platform_contract.required_route_marker invalid', e);
  }
  if (isObj(data.airgap_platform)) {
    checkRefSet(data.airgap_platform.arm64, 'airgap_platform.arm64');
    checkRefSet(data.airgap_platform.amd64, 'airgap_platform.amd64');
  }
  return e;
}

function validatePublishRecord(data) {
  const e = [];
  must(isObj(data), 'root must be object', e);
  if (!isObj(data)) return e;
  const req = ['schema','artifact_family','artifact_type','artifact_repo','artifact_ref','artifact_pinned_ref','artifact_digest','source_repo','source_commit','source_version','created','artifact_metadata','input_metadata','dist_files'];
  for (const k of req) must(k in data, `missing ${k}`, e);
  must(data.schema === 1, 'schema must be 1', e);
  must(['platform-contract','airgap-platform','install-defaults'].includes(data.artifact_family), 'artifact_family invalid', e);
  must(typeof data.artifact_type === 'string' && data.artifact_type.length > 0, 'artifact_type invalid', e);
  must(typeof data.artifact_repo === 'string' && data.artifact_repo.length > 0, 'artifact_repo invalid', e);
  must(typeof data.artifact_ref === 'string' && data.artifact_ref.length > 0, 'artifact_ref invalid', e);
  must(typeof data.artifact_pinned_ref === 'string' && data.artifact_pinned_ref.length > 0, 'artifact_pinned_ref invalid', e);
  must(typeof data.artifact_digest === 'string' && SHA.test(data.artifact_digest), 'artifact_digest invalid', e);
  must(typeof data.source_repo === 'string' && data.source_repo.length > 0, 'source_repo invalid', e);
  must(typeof data.source_commit === 'string' && COMMIT.test(data.source_commit), 'source_commit invalid', e);
  must(typeof data.source_version === 'string' && data.source_version.length > 0, 'source_version invalid', e);
  must(typeof data.created === 'string' && UTC.test(data.created), 'created invalid', e);
  for (const k of ['artifact_metadata','input_metadata','dist_files']) {
    must(isObj(data[k]), `${k} must be object`, e);
    if (isObj(data[k])) {
      for (const [kk,v] of Object.entries(data[k])) {
        must(typeof v === 'string', `${k}.${kk} must be string`, e);
      }
    }
  }
  return e;
}

module.exports = { validateApprovedUpstreamInputs, validatePublishRecord };
