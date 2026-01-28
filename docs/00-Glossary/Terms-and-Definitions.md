# Terms and Definitions

## Purpose
This document defines standard systems and software engineering terms and acronyms used across
requirements, architecture, design, and verification artifacts.

**Rule:** one concept gets one term. Avoid ambiguous synonyms.

---

## Normative keywords
The following keywords indicate requirement strength when used in requirements specifications:

- **SHALL**: mandatory requirement.
- **SHALL NOT**: mandatory prohibition.
- **SHOULD**: recommended; valid reasons may exist to deviate, but the reasons must be understood and documented.
- **SHOULD NOT**: recommended prohibition; valid reasons may exist to deviate, but the reasons must be understood and documented.
- **MAY**: optional; permitted but not required.

---

## Acronyms
| Acronym | Term |
|---|---|
| AD | Architecture Description |
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| BRS | Business Requirements Specification |
| ConOps | Concept of Operations |
| COTS | Commercial Off-The-Shelf |
| DoD | Department of Defense |
| E2E | End-to-End |
| FMEA | Failure Modes and Effects Analysis |
| FTA | Fault Tree Analysis |
| HLR | High-Level Requirement |
| ICD | Interface Control Document |
| IDD | Interface Design Description |
| I/O | Input/Output |
| KPI | Key Performance Indicator |
| LLR | Low-Level Requirement |
| MBSE | Model-Based Systems Engineering |
| NFR | Non-Functional Requirement |
| QA | Quality Attribute |
| RAM | Reliability, Availability, Maintainability |
| RFC | Request for Comments |
| RTM | Requirements Traceability Matrix |
| SDD | Software Design Description |
| SDR | System Design Review |
| SRS | Software Requirements Specification |
| StRS | Stakeholder Requirements Specification |
| SyRS | System Requirements Specification |
| T&E | Test and Evaluation |
| TBD | To Be Determined |
| TBR | To Be Reviewed |
| TRR | Test Readiness Review |
| V&V | Verification and Validation |
| VCD | Verification Cross-Reference (or Compliance) Document |
| VVP | Verification and Validation Plan |
| VVTR | Verification and Validation Test Report |

---

## Definitions

### Acceptance criteria
Objective, measurable conditions that must be satisfied for a deliverable, feature, or requirement
to be considered complete and acceptable.

### Allocation
Assignment of a system-level requirement to one or more system elements (e.g., subsystems,
components, software items) responsible for satisfying it.

### Assumption
A statement accepted as true for planning or design purposes. Assumptions should be explicitly
identified because they can become risks if invalid.

### Architecture
The fundamental concepts or properties of a system in its environment embodied in its elements,
relationships, and the principles of its design and evolution.

### Architecture Description (AD)
A work product that expresses an architecture for specific stakeholders and concerns using one or
more views (and associated viewpoints).

### Architecture Decision Record (ADR)
A lightweight record of a significant architectural decision, including context, decision, and
consequences.

### Baseline
A formally agreed set of configuration items (including documents, code, and other artifacts) that
serves as the basis for further development and can be changed only through controlled change
procedures.

### Business requirement
A statement of a business objective, outcome, or value the system is intended to deliver.

### Business Requirements Specification (BRS)
A specification of business requirements and business-level constraints and objectives.

### Capability
A named ability or function the system provides, typically described at an operational level.

### Change control
A defined process for proposing, evaluating, approving, implementing, and documenting changes to
baselined artifacts.

### Component
An identifiable part of a system that encapsulates behavior and may be independently replaceable
within a defined architecture. (Also commonly used as “software component.”)

### Concept of Operations (ConOps)
A description of how the system will be used in its operational environment, including operational
scenarios, stakeholders, roles, and constraints.

### Constraint
A restriction that limits design or implementation choices (e.g., mandated technologies, standards,
interfaces, safety rules, performance ceilings/floors).

### Derived requirement
A requirement that results from analysis, decomposition, or design decisions, and is traceable back
to a parent requirement or stakeholder need.

### Design
The representation of a system element that shows how requirements will be realized, including
structures, interfaces, behaviors, and implementation choices.

### Document identifier
A unique identifier assigned to a document or record to support traceability, configuration
management, and referencing.

### Functional requirement
A requirement that specifies a function, behavior, or capability the system or system element shall
provide.

### Hazard
A system state or set of conditions that, together with a particular set of worst-case environmental
conditions, will lead to an accident or loss event.

### High-Level Requirement (HLR)
A requirement stated at a system or major subsystem level, often emphasizing “what” over detailed
implementation.

### Interface
A shared boundary across which information, control, or physical interaction occurs between system
elements.

### Interface Control Document (ICD)
A controlled document that defines an interface between system elements, including interface
characteristics, constraints, and responsibilities.

### Interface Design Description (IDD)
A design-level description of interfaces, including data structures, protocols, and interaction
details.

### Low-Level Requirement (LLR)
A detailed requirement typically allocated to a specific component or software unit, suitable for
direct implementation and unit verification.

### Non-Functional Requirement (NFR)
A requirement that specifies a quality attribute or constraint (e.g., performance, security,
usability, availability, maintainability, portability) rather than a function.

### Quality attribute (QA)
A measurable or assessable property of a system that affects its quality (e.g., reliability,
usability, performance, security).

### Requirement
A statement that translates or expresses a need and its associated constraints and conditions.
Requirements should be necessary, unambiguous, verifiable, and traceable.

### Requirements Traceability Matrix (RTM)
A matrix (or structured dataset) that links requirements to their sources, allocations, and
verification evidence (e.g., test cases, analyses, inspections).

### Risk
An uncertain event or condition that, if it occurs, has a positive or negative effect on objectives.
Typically characterized by likelihood and consequence (impact).

### Stakeholder
An individual or organization that has a right, share, or interest in the system, or is affected by
the system.

### Stakeholder Requirements Specification (StRS)
A specification capturing stakeholder needs and expectations, including operational scenarios and
constraints, typically preceding or informing system requirements.

### Subsystem
A system element composed of multiple components that together provide a set of capabilities within
the larger system.

### System
A combination of interacting elements organized to achieve one or more stated purposes.

### System element
A member of the set of elements that constitute a system (e.g., subsystem, component, software item,
hardware item, process).

### System Requirements Specification (SyRS)
A specification of system requirements, including functional requirements, quality requirements, and
constraints, with defined verification provisions.

### Software Requirements Specification (SRS)
A specification of software requirements for a software item, including functional requirements,
interfaces, performance, and constraints, with defined verification provisions.

### Software Design Description (SDD)
A description of the software design that defines how software requirements are realized, including
architecture, components, interfaces, data, and key algorithms.

### Traceability
The ability to follow the life of a requirement in both forward and backward directions (from
origins through implementation and verification, and back).

### Validation
Confirmation that the system, as delivered, fulfills stakeholder needs and intended use in the
operational environment (“Are we building the right thing?”).

### Verification
Confirmation that a system element fulfills specified requirements (“Are we building the thing
right?”).

### Verification and Validation (V&V)
The set of activities and artifacts that establish verification (requirements met) and validation
(stakeholder needs met).

### Verification and Validation Plan (VVP)
A plan that defines the V&V approach, responsibilities, environments, methods, and evidence required
to verify and validate requirements.

### Verification methods
Common methods used to verify requirements:
- **Test**: exercising the item with defined procedures and measuring results.
- **Analysis**: using mathematical or logical reasoning, modeling, or simulation.
- **Inspection**: examining artifacts (code, documents, configurations) for correctness.
- **Demonstration**: showing functionality in operation without exhaustive measurement.

### Verification evidence
Artifacts that demonstrate a requirement has been verified (e.g., test results, analysis reports,
inspection records, review minutes).

### View
A representation of an architecture from the perspective of a defined set of concerns.

### Viewpoint
A specification of the conventions for constructing and using a view (e.g., notations, modeling
techniques, analysis methods, and stakeholder concerns addressed).

---
