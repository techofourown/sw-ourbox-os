This directory is generated output in published platform-contract artifacts.

Authoritative source inputs live under:

- `platform-contract/profiles/`
- `platform-contract/landing/`
- `platform-contract/todo-bloom/`
- `tools/platform-contract/render-contract.py`

Build or validate the canonical rendered bundle with:

```bash
./tools/platform-contract/build.sh
./tools/platform-contract/validate.sh
```

Verify a live rendered/apply result on a target with:

```bash
/opt/ourbox/airgap/platform/tools/check-target-prereqs.sh
/opt/ourbox/airgap/platform/tools/verify-runtime.sh \
  --contract-dir /opt/ourbox/airgap/platform \
  --render-dir /run/ourbox-platform-rendered
```

Optional PVC persistence verification:

```bash
/opt/ourbox/airgap/platform/tools/verify-persistence.sh \
  --render-dir /run/ourbox-platform-rendered
```
