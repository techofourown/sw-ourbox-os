---
typeId: section
recordId: SRS-0203-1-introduction
parent: "spec:SRS-0203"
fields:
  title: "Introduction"
  level: 1
  order: 1
---
This SRS defines requirements for the **k3s platform contract** used to deploy and operate OurBox OS workloads on an OurBox instance.

Scope includes:
- k3s as the Kubernetes distribution used on-box for OurBox OS workloads
- Kubernetes namespace posture (operational grouping; not tenant boundaries)
- **data placement** requirements for system-of-record data when deployed in k3s (persistent storage expectations)
- **defaults** required for out-of-box operation (e.g., default persistent volume provisioning, namespace conventions)
- **governance** posture for the deployment configuration baseline (how the deployed platform is defined and controlled)
- **verification** posture for confirming the running cluster satisfies the contract

Out of scope:
- gateway routing semantics and app/path policy (see `[[spec:SRS-0201]]`)
- on-box CouchDB data modeling posture (see `[[spec:SRS-0202]]`)
- tenant blob store semantics and CAS rules (see `[[spec:SRS-0205]]`)
- app-specific behavior and UI flows (see app SRSs)
