## Mobile Remote UI Platform (K3s Appliance) — Requirements v0.1

### Purpose

Define the top-level requirements for a **mobile-first "phone-like" user interface** delivered as a **full-screen web app**, backed by a **user-owned Ubuntu appliance running K3s**, where each "app" is a **separate Kubernetes service** the user can enable/disable.

### Scope

* This is **not** a hardware-level operating system/kernel.
* This is a **web-based application environment** that *behaves like* a phone home screen + apps.
* The platform runs on a **dedicated server appliance** owned/controlled by a single user or a small trusted group (e.g., family).

### Definitions

* **Appliance**: The user-controlled Ubuntu server hosting the platform.
* **Launcher**: The always-available "home screen" web app (the entry point).
* **Application**: A web app accessible by URL, backed by one or more Kubernetes services.
* **Service**: A Kubernetes workload representing an application or a shared backend capability.

---

# The 10 Most Important Requirements

### R1 — Platform Environment Constraint (Ubuntu + K3s)

**The system shall run on an Ubuntu-based server appliance and shall use K3s as the orchestration layer for all platform components and applications.**

* **Verification:** A clean Ubuntu installation can host the platform; all apps/components appear as K3s-managed workloads/services.

---

### R2 — Mobile-First Full-Screen Web Experience

**The primary user experience shall be delivered as a full-screen, mobile-optimized web app** usable on modern mobile browsers, without requiring any native mobile app installation.

* Must support touch-first interaction and mobile viewport behaviors.

* Desktop access may work, but the UX is optimized for mobile (no deliberate blocking required).

* **Verification:** On iOS Safari/Android Chrome, the UI is usable end-to-end with touch and fits the screen without desktop-specific assumptions.

---

### R3 — Launcher Is the Always-On Entry Point

**The Launcher shall be continuously available as the entry point** and shall not require the user to "start" it.

* It must load reliably at a stable URL (the "home screen" URL).

* It must provide a phone-like home experience (icons representing apps).

* **Verification:** After appliance boot and normal operation, navigating to the Launcher URL always presents a working home screen without manual service-start steps.

---

### R4 — App Launching Model: Icons → URL-Addressable Apps

**Selecting an app icon in the Launcher shall open the corresponding application by navigating to a distinct web route/URL served by the same appliance.**

* Each app must have a stable, addressable URL.

* The user can move between Launcher and apps with predictable navigation (e.g., a consistent "home" affordance, browser back behavior that doesn't trap users).

* **Verification:** Clicking an icon always takes the user to the intended app URL; returning to Launcher is always possible and consistent.

---

### R5 — Applications Map to Kubernetes Services

**Each application shall be independently deployable and manageable as its own Kubernetes service/workload(s)** within the K3s cluster.

* Apps must be separable: installing/removing/disabling one app must not require rebuilding the entire system.

* Apps must be discoverable by the platform (so the Launcher can represent them).

* **Verification:** Apps can be added/removed as K3s-managed units and appear/disappear in the Launcher accordingly.

---

### R6 — User-Controlled App Catalog and Configuration

**The user shall have complete control over which applications/services exist and are available**, including enabling, disabling, and removing applications.

* The Launcher must reflect the user's chosen catalog (no "phantom" apps).

* The system must expose a clear representation of "what's installed" vs "what's enabled."

* **Verification:** A user action to disable/remove an app results in that app no longer being launchable and its service no longer being available (per the chosen policy).

---

### R7 — Service Lifecycle Policies: Always-On vs On-Demand

**The platform shall support explicit lifecycle policies for services**, including:

* **Always-on services** (at minimum: Launcher and any required core session/auth capability).
* **On-demand services** that start when an app is opened and stop/suspend when not needed.

This is to prevent heavy apps from consuming RAM/CPU continuously.

* **Verification:** A designated on-demand app is not consuming significant resources when unused, and becomes available when opened; always-on services remain available without manual start.

---

### R8 — Core "Phone Basics" App Set Exists as First-Class Apps

**The platform shall provide (at minimum) the following first-class applications, accessible from the Launcher:**

1. Settings
2. Contacts
3. Photos
4. Email
5. Secure Messaging

Each must be launchable as a distinct app (per R4/R5), even if they share backend capabilities.

* **Verification:** Each app appears as an icon in the Launcher and is reachable at its own URL with functional core flows appropriate to the app.

---

### R9 — Privacy-First Data Ownership and Reduced Tracking Surface

**All user data and primary application processing shall remain under the user's control on the appliance by default**, with an explicit goal of minimizing tracking and hidden data extraction.

At minimum:

* No mandatory third-party analytics/trackers.

* No silent dependency on external services for core functionality (unless explicitly enabled by the user).

* Clear boundaries about what data each app can access (especially shared data like contacts).

* **Verification:** Core usage does not require third-party endpoints; user can inspect/understand what apps exist and what shared data they can access.

---

### R10 — Secure Access and Trust-Group Support

**The platform shall support secure authentication and access control for a single user or a small trusted group (e.g., family), including remote access over the internet.**

At minimum:

* Authentication is required before access to private apps/data.

* Separate user accounts are supported when multiple trusted users exist.

* Remote access must be possible (e.g., via user-managed port forwarding), using encrypted transport.

* **Verification:** Multiple accounts can log in with separated access; remote access is feasible without exposing plaintext sessions; unauthorized users cannot access apps/data.

---
