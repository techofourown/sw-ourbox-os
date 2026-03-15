# OurBox App Authoring Guide

- Status: Stable
- Audience: app authors, catalog maintainers, and maintainers creating new `sw-ourbox-apps-*` or `sw-ourbox-catalog-*` repositories
- Related:
  - [Apps repository contract](./apps-repository-contract.md)
  - [Application catalog repository contract](./application-catalog-repository-contract.md)
  - [Downstream consumer surfaces](./downstream-consumer-surfaces.md)
  - [Target integration contract](./target-integration-contract.md)
  - [Platform contract tooling](../../tools/platform-contract/README.md)
  - [Apps repo template](../../templates/apps-repo/README.md)
  - [Application catalog repo template](../../templates/application-catalog-repo/README.md)

## 1. Purpose

This guide defines the supported end-to-end path for getting a new application
into an OurBox system.

The intended workflow is:

1. create or extend an apps repository that publishes one or more OCI images,
2. emit machine-readable publish metadata for the published digests,
3. add the app's identity, routing, and health metadata to an application
   catalog repository,
4. publish the application catalog bundle,
5. let the installer select that catalog and selected apps,
6. let `sw-ourbox-os` render the platform contract from that selected catalog.

If you follow this guide, a new app should become:

- installable from the host-side installer,
- routable by hostname on the target,
- visible on the landing page,
- and visible in landing-page status as healthy, starting, or failing.

## 2. System model

There are three repository roles in the authoring path.

### 2.1 Apps repository

An apps repository owns application source code and publishes OCI images.

Examples:

- `sw-ourbox-apps-chat`
- `sw-ourbox-apps-demo`
- `sw-ourbox-apps-hello-world`

It does **not** decide:

- which apps are bundled together,
- which apps are defaults,
- what hostname they should use,
- or whether they appear on the landing page.

### 2.2 Application catalog repository

A catalog repository consumes published app images and defines:

- which apps belong in the catalog,
- which apps are defaults,
- which hostname each app uses,
- which service and port the platform contract should route to,
- which health marker proves the app is alive,
- and which `display_name` / `description` the landing page shows.

Examples:

- `sw-ourbox-catalog-demo`
- `sw-ourbox-catalog-hello-world`

### 2.3 `sw-ourbox-os`

`sw-ourbox-os` consumes the selected application catalog plus the selected app
set and renders the platform contract.

The platform contract renderer consumes:

- `catalog.json`
- `images.lock.json`
- `selected-apps.json` written by the installer composer

The renderer uses catalog metadata to produce:

- Kubernetes manifests,
- ingress rules,
- landing-page app cards,
- landing-page app health targets.

This is why the catalog entry is the real integration seam.

## 3. Authoring doctrine

These rules are not optional if you want the app to behave like a first-class
OurBox app.

### 3.1 Publish digests, not mutable tags

Catalog repos pin image digests. The app repo may publish tags like `latest` and
`sha-<commit>`, but the catalog must consume a digest-pinned ref.

### 3.2 Stable app identity beats display name

Every catalog entry must carry a stable `app_uid` such as
`techofourown/ourbox-chat`. This is the machine identity used when multiple
catalogs are merged.

Do not use display-name matching as identity.

### 3.3 The catalog owns route and UX metadata

The app repo owns the image. The catalog owns:

- `display_name`
- `description`
- `host_template`
- `service_name`
- `service_port`
- `expected_status`
- `body_marker`
- `route_description`

Those fields are what make the app a full app in the system rather than just an
image sitting in GHCR.

### 3.4 The landing page is catalog-driven

The landing page is generated from the selected catalog apps. It reads:

- `display_name`
- `description`
- `host_template`
- `service_name`

If those fields are wrong, the landing page will be wrong.

### 3.5 App health is contract-driven

The landing page status surface does not guess. It checks the target apps that
the catalog and rendered platform contract say should exist.

That means the catalog entry must accurately identify the app's service name and
expected successful behavior.

### 3.6 Avoid Kubernetes service-env collisions

Do not name your own environment variables in a way that collides with the
Kubernetes service env vars that are injected from a Service object.

Concrete example:

- bad: `OURBOX_CHAT_PORT`
- safer: `OURBOX_CHAT_LISTEN_PORT`

If your Service is named `ourbox-chat`, Kubernetes may inject
`OURBOX_CHAT_PORT=tcp://...`, which is not usable as an integer CLI flag.

### 3.7 Mobile-first is the baseline UX

OurBox is a phone-first web platform. New apps should assume:

- the primary client is a mobile browser,
- touch interaction matters,
- responsive layout is required,
- and the app should still be inspectable from a desktop browser.

## 4. Quickstart

Use this sequence when creating a new app from scratch.

### 4.1 Create the apps repository

Recommended naming:

- repo: `sw-ourbox-apps-<collection>`
- image repo: `ghcr.io/<org>/sw-ourbox-apps-<collection>/<app-id>`

Start from:

- [`templates/apps-repo/`](../../templates/apps-repo/)

Minimum contents:

- `apps-manifest.json`
- `.github/workflows/ci.yml`
- `.github/workflows/publish-images.yml`
- `scripts/check-apps-manifest.sh`
- `scripts/check-app-builds.sh`
- app source directories such as `apps/<app-id>/`

### 4.2 Add the application image

For each app, provide at least:

- a `Dockerfile`,
- an entrypoint or startup command,
- a deterministic HTTP surface,
- and an app-specific runtime smoke test.

The app must expose a stable HTTP response that the catalog can later validate.

### 4.3 Fill in `apps-manifest.json`

Schema:

- [`schemas/apps-manifest.schema.json`](../../schemas/apps-manifest.schema.json)

Required fields:

| Field | Meaning |
|---|---|
| `schema` | currently `1` |
| `kind` | `ourbox-apps-collection` |
| `collection_id` | machine identifier for the repo's app collection |
| `display_name` | human-facing name for the collection |
| `apps[]` | list of apps published by the repo |
| `apps[].app_id` | machine app id used within the repo |
| `apps[].display_name` | human-facing app name |
| `apps[].source_path` | build context path |
| `apps[].image_repo` | full GHCR image repo |
| `apps[].default_tag` | default moving tag, usually `latest` |

Example:

```json
{
  "schema": 1,
  "kind": "ourbox-apps-collection",
  "collection_id": "chat",
  "display_name": "Chat Apps Publisher",
  "apps": [
    {
      "app_id": "ourbox-chat",
      "display_name": "OurBox Chat",
      "source_path": "apps/ourbox-chat",
      "image_repo": "ghcr.io/techofourown/sw-ourbox-apps-chat/ourbox-chat",
      "default_tag": "latest"
    }
  ]
}
```

### 4.4 Add app-repo CI

Minimum CI:

- validate manifest shape and required files,
- syntax-check the repo scripts,
- build each application image,
- run app-specific smoke tests when practical.

Start from:

- [`templates/apps-repo/.github/workflows/ci.yml`](../../templates/apps-repo/.github/workflows/ci.yml)
- [`templates/apps-repo/scripts/check-apps-manifest.sh`](../../templates/apps-repo/scripts/check-apps-manifest.sh)
- [`templates/apps-repo/scripts/check-app-builds.sh`](../../templates/apps-repo/scripts/check-app-builds.sh)

### 4.5 Add publish workflow

Minimum publish behavior:

- build and push digest-pinned OCI images,
- publish `latest` and `sha-<commit>` tags if desired,
- emit a machine-readable publish record for each published image digest.

Schema:

- [`schemas/application-image-publish-record.schema.json`](../../schemas/application-image-publish-record.schema.json)

Start from:

- [`templates/apps-repo/.github/workflows/publish-images.yml`](../../templates/apps-repo/.github/workflows/publish-images.yml)

### 4.6 Create or update the catalog repository

Start from:

- [`templates/application-catalog-repo/`](../../templates/application-catalog-repo/)

Minimum contents:

- `catalog/catalog.json`
- `catalog/images.lock.json`
- `catalog/profile.env`
- `scripts/render-catalog-bundle.sh`
- `scripts/check-catalog-bundle-smoke.sh`
- `scripts/check-image-refs-exist.sh`
- `.github/workflows/ci.yml`
- `.github/workflows/publish-catalog-bundle.yml`

### 4.7 Add the app entry to `catalog.json`

Schema:

- [`schemas/application-catalog.schema.json`](../../schemas/application-catalog.schema.json)

Required per-app integration fields:

| Field | Meaning |
|---|---|
| `id` | catalog-local app id |
| `app_uid` | stable global machine identity such as `techofourown/ourbox-chat` |
| `display_name` | landing-page and installer display text |
| `description` | landing-page description |
| `service_name` | Kubernetes Service name rendered into the platform contract |
| `service_port` | Service port exposed in the rendered platform contract |
| `host_template` | route host such as `chat.{box_host}` |
| `path` | routed path, usually `/` |
| `expected_status` | expected HTTP success status |
| `body_marker` | short marker string proving the app responded correctly |
| `route_description` | human-readable route label used in validation output |
| `image_names` | list of image names that must exist in `images.lock.json` |

Optional but commonly used:

| Field | Meaning |
|---|---|
| `renderer` | app-specific renderer hint |
| `default_backend` | whether this app is the default ingress backend |

Important behavior:

- `display_name` and `description` are what the landing page shows.
- `service_name` is what the landing-page status surface uses to correlate the
  app with runtime state.
- `image_names[0]` is the primary image ref consumed by the platform renderer.

### 4.8 Pin the image digest in `images.lock.json`

Each image lock entry binds a logical image name to a digest-pinned image ref.

Example:

```json
{
  "schema": 1,
  "profile": "hello-world",
  "images": [
    {
      "name": "ourbox-chat",
      "ref": "ghcr.io/techofourown/sw-ourbox-apps-chat/ourbox-chat@sha256:...",
      "used_by": [
        "ourbox-chat"
      ]
    }
  ]
}
```

Rules:

- every `ref` must be digest-pinned,
- every `name` referenced by a catalog app must exist in `images.lock.json`,
- every `used_by` id must exist in `catalog.json`.

### 4.9 Update `profile.env`

This file is installer-facing catalog metadata. At minimum it should include:

- `OURBOX_APPLICATION_CATALOG_ID`
- `OURBOX_APPLICATION_CATALOG_NAME_SLUG`
- `OURBOX_APPLICATION_CATALOG_DEFAULT_APP_IDS`

Keep it in sync with `catalog.json`.

### 4.10 Publish the catalog bundle

Minimum publish behavior:

- render `catalog.json`, `images.lock.json`, `profile.env`, and `manifest.env`
  into `dist/application-catalog-bundle.tar.gz`,
- publish that tarball to GHCR,
- emit a machine-readable publish record.

Schema:

- [`schemas/application-catalog-bundle-publish-record.schema.json`](../../schemas/application-catalog-bundle-publish-record.schema.json)

Start from:

- [`templates/application-catalog-repo/.github/workflows/publish-catalog-bundle.yml`](../../templates/application-catalog-repo/.github/workflows/publish-catalog-bundle.yml)

### 4.11 Select the catalog in the installer

The installer flow is:

1. choose OS artifact,
2. choose one or more application catalogs,
3. choose selected apps from the merged catalog,
4. emit `selected-apps.json`,
5. render the platform contract from the chosen catalog and selected apps.

This means your app only becomes part of a final system when:

- its image was published,
- the catalog bundle was published,
- the selected installation chose that catalog,
- and the selected app set included the app.

## 5. Apps repository template contract

The template in [`templates/apps-repo/`](../../templates/apps-repo/) is the
reference starter shape for a new apps repository.

Recommended layout:

```text
.
├── .github/workflows/
│   ├── ci.yml
│   └── publish-images.yml
├── apps-manifest.json
├── apps/
│   └── <app-id>/
│       ├── Dockerfile
│       └── ...
└── scripts/
    ├── check-apps-manifest.sh
    └── check-app-builds.sh
```

### 5.1 CI expectations

App repos should keep CI on GitHub-hosted runners unless there is a real reason
to require self-hosted infrastructure.

Minimum checks:

- `bash -n` on repo scripts,
- manifest validation,
- per-app image build smoke,
- per-app runtime smoke when feasible.

### 5.2 Publish workflow expectations

The publish workflow should:

1. resolve the app matrix from `apps-manifest.json`,
2. build and push each image,
3. write one publish record per app,
4. upload the publish records as workflow artifacts.

The template workflow shows this pattern.

### 5.3 Versioning expectations

Moving tags such as `latest` are allowed for convenience, but downstream
catalogs should always pin a digest.

Recommended tags:

- `latest`
- `sha-<commit>`

## 6. Catalog repository template contract

The template in
[`templates/application-catalog-repo/`](../../templates/application-catalog-repo/)
is the reference starter shape for a new catalog repository.

Recommended layout:

```text
.
├── .github/workflows/
│   ├── ci.yml
│   └── publish-catalog-bundle.yml
├── catalog/
│   ├── catalog.json
│   ├── images.lock.json
│   └── profile.env
└── scripts/
    ├── check-catalog-bundle-smoke.sh
    ├── check-image-refs-exist.sh
    └── render-catalog-bundle.sh
```

### 6.1 Required validation

Catalog CI should prove:

- `catalog.json` shape is valid,
- `default_app_ids` all exist,
- `app_uid` values are unique,
- `image_names` are satisfied by `images.lock.json`,
- every image ref is digest-pinned,
- the rendered bundle contains the exact expected inputs,
- referenced image digests exist in GHCR.

### 6.2 Publish workflow expectations

The publish workflow should:

1. render the bundle,
2. publish `dist/application-catalog-bundle.tar.gz` to GHCR,
3. resolve the pushed digest,
4. write the publish record,
5. upload the bundle and publish record as artifacts.

## 7. How `sw-ourbox-os` consumes your catalog

The platform renderer accepts:

```bash
./tools/platform-contract/render-contract.py \
  --contract-root ./platform-contract \
  --output-dir /tmp/rendered \
  --application-catalog /path/to/catalog.json \
  --images-lock-file /path/to/images.lock.json \
  --selected-apps-file /path/to/selected-apps.json
```

The important behaviors are:

- ingress routes come from `host_template`, `path`, `service_name`, and
  `service_port`,
- landing cards come from `display_name`, `description`, and `host_template`,
- landing status targets use `service_name`,
- image refs come from `image_names[0]` mapped through `images.lock.json`.

If an app is selected but absent from the catalog inputs, the renderer will
fail rather than silently inventing a route.

## 8. Landing-page behavior

The landing page now reflects whichever apps are selected on the device.

To show correctly on the landing page, the app must have:

- `display_name`
- `description`
- `host_template`
- `service_name`

To show useful status, the app must also have:

- a routable Service,
- a correct `service_name`,
- a meaningful `expected_status`,
- and a useful `body_marker`.

If an app is expected to exist but is failing at runtime, the landing page can
show that distinction only if the catalog metadata is correct.

## 9. Health and route design guidelines

Recommended app behavior:

- return HTTP `200` for the primary route,
- expose a stable text marker on the route or a health endpoint,
- start quickly enough that readiness checks are meaningful,
- keep the first response deterministic enough for a simple smoke test.

Avoid:

- apps that only become reachable after a client-side redirect chain with no
  stable success marker,
- apps that require a live internet fetch before the first useful paint,
- health surfaces that return success before the app is actually ready.

## 10. Offline-bundled app expectations

If you want the app to work immediately after installation with no further
download, make sure:

- the application image is fully self-contained,
- large model or data assets are already in the image,
- the catalog pins the exact image digest,
- and the downstream image repo bundles that image via the selected catalog.

This is how `ourbox-chat` works: the model is bundled into the image, the
catalog pins the digest, and the selected catalog carries the app into the final
installation.

## 11. Release checklist

Before telling someone to add your app to a catalog, verify all of these:

- app repo CI is green,
- app repo publish workflow produced digest-pinned images,
- each published app has a publish record,
- the catalog entry uses the correct `app_uid`,
- `display_name` and `description` are the intended landing-page copy,
- `service_name` and `service_port` match the real runtime,
- `host_template` is the desired hostname,
- `expected_status` and `body_marker` are valid,
- `images.lock.json` pins the right digest,
- catalog CI is green,
- catalog publish workflow produced a bundle and publish record.

## 12. Common failure modes

### 12.1 The app image publishes, but the app never shows up

Cause:

- the catalog was never updated,
- or the selected installation never chose the catalog or app.

### 12.2 The landing page shows the app, but the route is broken

Cause:

- `host_template`, `service_name`, `service_port`, or `path` is wrong.

### 12.3 The landing page shows the app, but status is red

Cause:

- the pod is unhealthy,
- the Service name is wrong,
- or the app does not satisfy the expected HTTP marker.

### 12.4 The installer offers the catalog, but the wrong apps are preselected

Cause:

- `default_app_ids` or `profile.env` is out of sync with `catalog.json`.

### 12.5 The app crashes only in Kubernetes

Cause:

- a Service-derived environment variable collided with an app-defined env var,
- or the container assumed a local Docker network model that does not hold in
  Kubernetes.

### 12.6 The catalog validates locally but breaks later

Cause:

- the image refs were tags rather than digests,
- or the publish record was never consulted when updating `images.lock.json`.

## 13. Minimal supported authoring surface

If you want the smallest possible supported path, the minimum is:

1. publish a digest-pinned OCI image from an apps repo,
2. add a catalog entry with the required route and health metadata,
3. add the image digest to `images.lock.json`,
4. publish the catalog bundle.

That is enough for the app to be selectable and rendered into the platform
contract.

Everything else in this guide exists to make that path reliable, inspectable,
and maintainable.
