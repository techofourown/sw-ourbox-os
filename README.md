# OurBox OS

OurBox OS is **a local-first application platform** that runs on **user-owned hardware** (or
user-owned cloud VMs) and presents a **mobile-first, phone-like web experience** for launching and
using self-hosted apps.

It is called an "OS" because it behaves like a cohesive operating environment:
- a home screen ("Launcher")
- a set of canonical first-party apps (Email, Notes, Contacts, Photos, Messaging, Settings, etc.)
- an app catalog / installation model
- shared identity, permissions, and data foundations

...but it is **not** an operating system distribution or kernel.

## What it is

OurBox OS is a **suite of services** designed to be deployed and managed as a **Kubernetes-based
system** (k3s in the canonical appliance path). Each "app" is a separately deployable unit (often
one or more Kubernetes workloads) that the user can enable/disable/remove.

The core user experience is delivered as a **full-screen, mobile-optimized web app** served from the
user's own device.

## What it is not

- Not a Linux distro.
- Not a replacement for Raspberry Pi OS / Ubuntu / Debian / etc.
- Not "one binary you run."
- Not a cloud SaaS product you must depend on.

## Canonical deployment paths

OurBox OS is designed to run in multiple environments, with one "canonical" hardware experience:

1. **OurBox Mini (canonical appliance)**  
   A small, always-on home server appliance designed and validated to run OurBox OS with minimal user
   friction.

2. **Cloud VM (hosted or self-managed)**  
   OurBox OS can run on a virtual machine in a cloud environment for users who don't want physical
   hardware.

3. **Self-host on your own Linux box (best-effort)**  
   Users can run OurBox OS on compatible Linux systems they control. We aim to keep it practical and
   open, while reserving formal support guarantees for the canonical paths.

## Design principles (non-negotiable product posture)

- **Local-first by default:** core functionality must work on the user's own device.
- **Privacy-first:** no hidden analytics, no silent data extraction.
- **User control:** the user controls what apps exist and what runs.
- **Open-source by default:** people can inspect, rebuild, and modify.

## Repository purpose

This repository (`sw-ourbox-os`) is the **product software**: the platform services, UI, and the
application framework that make "OurBox OS" real.

This repo is **not** the hardware design repo and **not** the image build repo.

Related repos (by convention):
- `hw-ourbox-mini` — hardware design + physical specs for the Mini device
- `img-ourbox-mini-rpi` — the bootable image recipe for the canonical Mini device

## Documentation map

- `SPEC.md` — top-level product requirements (baseline)
- `docs/rfcs/` — proposals and memos (pre-decision)
- `docs/decisions/` — Architecture Decision Records (decisions we are committing to)

See `docs/README.md` for the overall docs workflow.
