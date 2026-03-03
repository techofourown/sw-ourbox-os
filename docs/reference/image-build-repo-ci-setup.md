# Image Build Repo CI/CD Setup

- Status: Stable
- Audience: maintainers setting up CI/CD for a new `img-*` repo
- Related:
  - `./new-hardware-target-checklist.md`
  - `./target-integration-contract.md`
  - `../decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md` (org-level)
  - Runner label catalog and host inventory — contact an org maintainer

## Purpose

This document records how official CI/CD is structured in an `img-*` repo, what
infrastructure must be in place before the first publish can run, and the non-obvious
gotchas that caused problems during the Woodbox migration. Use it when setting up
CI for a new target (e.g. Tinderbox).

---

## 1. Runner infrastructure (do this first)

**Two things must be in place before any official workflow can run.** Neither is
self-serve. Both require access to the GitHub org settings.

### 1a. Runner group access

Official heavy workflows run in the `official-heavy-artifacts` org runner group,
which has `visibility: selected`. A new repo is NOT automatically in the group.

**Symptom when missing**: workflow sits in "queued" indefinitely with no error.

To add the repo:
```bash
# Find the runner group ID
GROUP_ID=$(gh api /orgs/techofourown/actions/runner-groups \
  --jq '.runner_groups[] | select(.name=="official-heavy-artifacts") | .id')

# Get repo ID
NEW_REPO_ID=$(gh api /repos/techofourown/<new-repo> --jq .id)

# Fetch current list of repo IDs in the group
CURRENT_IDS=$(gh api /orgs/techofourown/actions/runner-groups/${GROUP_ID}/repositories \
  --paginate --jq '[.repositories[].id] | join(",")' | tr ',' '\n')

# Add to runner group (PUT replaces entire list — include all existing repos)
python3 -c "
import urllib.request, json, subprocess
token = subprocess.check_output(['gh', 'auth', 'token']).decode().strip()
group_id = '${GROUP_ID}'
url = f'https://api.github.com/orgs/techofourown/actions/runner-groups/{group_id}/repositories'
ids = [int(x) for x in '${CURRENT_IDS}'.split() + ['${NEW_REPO_ID}']]
data = json.dumps({'selected_repository_ids': ids}).encode()
req = urllib.request.Request(url, data=data, method='PUT')
req.add_header('Authorization', f'Bearer {token}')
req.add_header('Accept', 'application/vnd.github+json')
req.add_header('Content-Type', 'application/json')
urllib.request.urlopen(req)
print('done')
"
```

Verify:
```bash
gh api /orgs/techofourown/actions/runner-groups/${GROUP_ID}/repositories \
  --paginate --jq '.repositories[].full_name'
```

### 1b. Runner capability labels

The workflow `runs-on:` must exactly match labels registered on a runner. The label
catalog is maintained privately — contact an org maintainer.

**Example for a new Tinderbox target:**
```yaml
runs-on: [self-hosted, official-heavy, jetson-image]
```

If the `jetson-image` label doesn't exist on any runner, the workflow queues forever.

To add a label to a runner:
```bash
# Find the runner ID
gh api /orgs/techofourown/actions/runners --jq '.runners[] | "\(.id) \(.name)"'

# Add the label
gh api --method POST /orgs/techofourown/actions/runners/<id>/labels \
  --field 'labels[]=jetson-image'
```

Also update the runner label catalog and host inventory (maintained privately — ask an org maintainer).

### 1c. Runner health

If the runner has been idle for hours it can silently lose its GitHub long-poll
connection while appearing "active" in `systemctl status`. Symptom: queued jobs do
not get picked up even after label and group access are correct.

Check the journal:
```bash
journalctl -u 'actions.runner.*' --since '1 hour ago'
```

If no entries, the connection has stalled. Restart the service (requires sudo):
```bash
sudo systemctl restart 'actions.runner.*'
```

Jobs will be picked up within ~15 seconds of reconnect.

---

## 2. Workflow architecture

Every `img-*` repo uses the same six-workflow pattern (adapt from `img-ourbox-woodbox`):

| Workflow | Trigger | Runner | Publishes? |
|---|---|---|---|
| `ci.yml` | PR + push to main | `ubuntu-latest` | No |
| `release.yml` | Push to main | `ubuntu-latest` | No (semantic-release tags only) |
| `official-nightly.yml` | Push to main | `[self-hosted, official-heavy, <target>-image]` | Yes (nightly channel) |
| `official-release.yml` | GitHub Release `published` | `[self-hosted, official-heavy, <target>-image]` | Yes (stable channel) |
| `build-publish-os-self-hosted.yml` | `workflow_dispatch` | `[self-hosted, official-heavy, <target>-image]` | No |
| `revalidate-<target>-build.yml` | `workflow_dispatch` + weekly cron | `[self-hosted, official-heavy, <target>-image]` | No |

### Step order within official workflows

Order matters. Bootstrap must run before GHCR login because bootstrap installs `oras`.

```
1. Fix workspace ownership (sudo chown — pi-gen / other root-owned artifacts)
2. Checkout (fetch-depth: 0)
3. Set nightly/release version (→ GITHUB_ENV)
4. Bootstrap host dependencies (installs oras, xorriso, etc.)
5. GHCR login (oras login — requires oras from step 4)
6. Clean stale workspace artifacts (rm -rf deploy/ artifacts/ ...)
7. Preflight build host
8. Fetch pinned upstream inputs
9. Build OS artifact
10. Build installer artifact
11. Publish OS artifact (official only)
12. Publish installer artifact (official only)
13. Upload provenance files (always: true)
```

### Workflow safety rules

`tools/check-workflow-safety.sh` (run in CI) enforces two rules:

**Rule 1 — No self-hosted workflow on pull_request trigger**
Any workflow with `runs-on: [...self-hosted...]` must NOT trigger on
`pull_request` or `pull_request_target`. Prevents untrusted PR code on
privileged builders.

**Rule 2 — Official publish workflows must not expose workflow_dispatch**
Any workflow that calls `publish-*-artifact-official.sh` must NOT have a
`workflow_dispatch:` trigger. Official publication only flows from push-to-main
(nightly) or GitHub Release `published` event (release).

Consequence: smoke build workflows (`build-publish-os-self-hosted.yml`) are safe
to use `workflow_dispatch` precisely because they do NOT invoke the official
publish scripts.

**Rule 3 — Nightly workflows must declare a path filter**
Branch-push workflows (nightly) must have `paths:` or `paths-ignore:` to avoid
rebuilding on doc-only commits. Release workflows do not need this.

**Rule 4 — Official publish workflows using `release:` must constrain to `types: [published]`**
A `release:` trigger without `types: [published]` would fire on draft creation,
pre-release edits, and deletions. Official publication must only occur on a
fully published, non-draft release.

### Why `release: types: [published]` and not `push: tags: ['v*']`

`push: tags` does **not** fire when semantic-release pushes the version tag via
a GitHub App token, because the release commit message contains `[skip ci]`.
The `release: types: [published]` event fires when `@semantic-release/github`
publishes the GitHub Release object — that step is unaffected by `[skip ci]`.

This is the same pattern used by `sw-ourbox-os`'s own publish workflows
(`platform-contract.yml`, `airgap-platform.yml`) and is the proven working trigger.

```yaml
# Standard path filter for nightly:
paths-ignore:
  - 'docs/**'
  - 'README.md'
  - 'CLAUDE.md'
```

---

## 3. Configuration file conventions

### `tools/config.env` — must use `:=` conditional assignment

**Wrong** (bare assignment clobbers CI env vars):
```bash
OURBOX_VERSION="dev"
```

**Right** (no-op if already set by workflow):
```bash
: "${OURBOX_VERSION:=dev}"
```

This matters because official-nightly.yml sets `OURBOX_VERSION=nightly-${GITHUB_SHA:0:12}`
via `$GITHUB_ENV` before the build steps run. If `config.env` uses bare assignment,
sourcing it overwrites the workflow-provided value and artifacts end up stamped `dev`.
The `:=` form respects already-set variables.

All variables in `config.env` must use `:=`.

### `release/official-inputs.env` — digest-pinned upstream refs

Pin upstream OCI artifacts by digest, not floating tag:
```bash
# Right — immutable
PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:<digest>

# Wrong — mutable, build is not reproducible
PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract:edge
```

To resolve current digests:
```bash
oras resolve ghcr.io/techofourown/sw-ourbox-os/platform-contract:edge
oras resolve ghcr.io/techofourown/sw-ourbox-os/airgap-platform:edge-<arch>
```

Update `official-inputs.env` via PR whenever sw-ourbox-os ships a new bundle.

### `release/official-artifacts.env` — publication targets

Hard-code the repo's publication namespace and channel tags here. These must never
be overridden by workflow inputs.

```bash
OFFICIAL_OS_REPO=ghcr.io/techofourown/ourbox-<device>-os
OFFICIAL_OS_CATALOG_TAG=<target>-catalog
OFFICIAL_OS_NIGHTLY_CHANNELS="<target>-nightly"
OFFICIAL_OS_RELEASE_CHANNELS="<target>-stable"

OFFICIAL_INSTALLER_REPO=ghcr.io/techofourown/ourbox-<device>-installer
OFFICIAL_INSTALLER_NIGHTLY_CHANNELS="<target>-installer-nightly"
OFFICIAL_INSTALLER_RELEASE_CHANNELS="<target>-installer-stable"
```

---

## 4. Shellcheck conventions

A few patterns come up in every image-build repo:

**SC2016 — intentional single-quoted envsubst variable lists**

`envsubst` takes a list of variable names as literal strings. These must be
single-quoted (to prevent expansion), which shellcheck flags as SC2016.
Suppress with a targeted disable:

```bash
# shellcheck disable=SC2016  # single-quoted intentionally — envsubst needs literal $VAR strings
VARS='${OURBOX_HOSTNAME} ${OURBOX_USERNAME} ${OURBOX_PASSWORD_HASH}'
envsubst "${VARS}" < template.tpl > output.yaml
```

**SC2295 — inner quoting in parameter expansion prefix**

When stripping a variable-length prefix from another variable:
```bash
# Wrong (SC2295):
channel="${channel_tag#${OURBOX_TARGET}-}"

# Right:
channel="${channel_tag#"${OURBOX_TARGET}"-}"
```

**SC2018/SC2019 — POSIX character classes in `tr`**

```bash
# Wrong (SC2018/SC2019):
echo "${VAR}" | tr 'A-Z' 'a-z'

# Right:
echo "${VAR}" | tr '[:upper:]' '[:lower:]'
```

**SC2015 — `A && B || C` log patterns**

```bash
# Wrong (SC2015 — C runs if B fails, not just if A fails):
command -v foo >/dev/null && log "foo: $(foo --version)" || true

# Right:
if command -v foo >/dev/null; then log "foo: $(foo --version)"; fi
```

---

## 5. Sanitization

`tools/check-public-sanitization.sh` runs in CI on every PR and push. Copy it from
an existing `img-*` repo (Woodbox or Matchbox) and adapt. It checks three categories:

### 5a. Forbidden files

Files that must never be committed. Add any file whose presence would expose internal
infrastructure (registry credentials, internal TLS certs, etc.):

```bash
FORBIDDEN_FILES=(
  "tools/registry.env"   # internal registry address/credentials
)
```

### 5b. Forbidden content patterns

Patterns that must not appear anywhere in tracked content. Two categories:

**Internal infrastructure identifiers** — the internal registry hostname, the
internal CA certificate path, and the build host name as it appears in Kubernetes
`nodeName:` fields. Copy the exact regex strings from `tools/check-public-sanitization.sh`
in an existing repo (Woodbox or Matchbox). Do not reproduce them in documentation,
as documentation is scanned too.

**Kubernetes security patterns** — manifests must not contain privileged host access,
privileged containers, or host filesystem mounts. Same rule: copy the exact patterns
from the script, don't document them as literal strings here.

### 5c. Banned words

Words that must not appear anywhere in tracked files (word-boundary matched,
case-insensitive). Copy the list from `tools/check-public-sanitization.sh` in an
existing repo — it includes the internal build host name and the private
infrastructure repo name.

Also add any **retired target names** specific to your repo. If the target was known
by a different internal codename during development, ban the old name the same way
Woodbox bans its own retired codename.

The scan uses `\b<word>\b` so substring matches do not trigger it. But the exact
word anywhere in any tracked file — including docs, templates, and baked default
files like `installer/ourbox/rootfs/etc/ourbox/release` — will fail CI. Check
those files before opening a PR.

### 5d. The script excludes itself

The sanitization script references the banned strings as patterns. The scan
automatically excludes `tools/check-public-sanitization.sh` itself from the scan,
so the script can contain the banned strings without triggering its own check.
All other tracked files (including docs) are scanned without exception.

---

## 6. Integration checklist for a new `img-*` repo

### Infrastructure (coordinate with ops)
- [ ] Runner group access — add repo to `official-heavy-artifacts` group
- [ ] Runner capability label — add `<target>-image` label to the builder host
- [ ] Update runner label catalog and host inventory (org maintainer task — maintained privately)
- [ ] Confirm label-catalog entry no longer marked "future"

### Repository setup
- [ ] `tools/config.env` — all variables use `:=` conditional assignment
- [ ] `release/official-inputs.env` — upstream OCI refs digest-pinned
- [ ] `release/official-artifacts.env` — publication namespaces and channel tags set
- [ ] `tools/check-workflow-safety.sh` — copied from Woodbox (no target-specific changes needed)
- [ ] `tools/check-public-sanitization.sh` — copied; add any target-specific banned legacy names
- [ ] All 6 workflow files adapted from Woodbox with correct runner labels and target names
- [ ] `paths-ignore` set on nightly workflow
- [ ] No `workflow_dispatch` on official publish workflows
- [ ] All scripts in `tools/` are `chmod +x` (mode 755)

### Validation
- [ ] CI workflow passes on a PR (sanitization + shellcheck + workflow safety)
- [ ] Smoke build (`workflow_dispatch`) succeeds on the self-hosted runner
- [ ] Revalidate workflow succeeds end-to-end (builds both artifacts)
- [ ] Official nightly runs successfully after merge to main
- [ ] Provenance files uploaded as workflow artifacts
