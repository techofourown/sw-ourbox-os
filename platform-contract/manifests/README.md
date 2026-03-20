This directory is generated output in published platform-contract artifacts.

Authoritative source inputs live under:

- `platform-contract/profiles/`
- `platform-contract/landing-status/`
- `tools/platform-contract/render-contract.py`

Legacy local-only fixture assets also remain under:

- `platform-contract/landing/`
- `platform-contract/todo-bloom/`

Current published application catalogs are expected to ship static app content
inside the selected application images rather than via `asset_dir` overlays.

Build or validate the canonical rendered bundle with:

```bash
./tools/platform-contract/build.sh
./tools/platform-contract/validate.sh
```

Verify a live rendered/apply result on a target with:

```bash
/opt/ourbox/substrate/platform/tools/check-target-prereqs.sh
/opt/ourbox/substrate/platform/tools/verify-runtime.sh \
  --contract-dir /opt/ourbox/substrate/platform \
  --render-dir /run/ourbox-platform-rendered
```

Optional PVC persistence verification:

```bash
/opt/ourbox/substrate/platform/tools/verify-persistence.sh \
  --render-dir /run/ourbox-platform-rendered
```
