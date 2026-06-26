
Roadmap
Phase 0 — System of Truth

Status: In Progress

Objective: Establish the architecture foundation before writing application code.

Deliverables:

README.md
SYSTEM_DESIGN.md
SECURITY_MODEL.md
GOVERNANCE_MODEL.md
SCALING_STRATEGY.md
ARCHITECTURE_DECISIONS.md
INTERVIEW_PLAYBOOK.md
Mermaid diagrams
Sample evidence records

Exit Criteria:

The repo explains what is being built.
The architecture is understandable without running code.
The system has a clear enterprise integration story.
The future scale-out path is documented.
Phase 1 — Local Enterprise Simulation

Objective: Build mock enterprise systems that represent existing IT infrastructure.

Services:

identity-service
cmdb-adapter
ticketing-adapter
audit-service

Exit Criteria:

Mock users and roles exist.
Mock assets exist in a CMDB-style API.
Mock tickets can be created.
Audit events can be written as JSON.
Phase 2 — AI Gateway

Objective: Create the control point between users, AI models, policies, and enterprise systems.

Capabilities:

Prompt classification
Prompt injection detection
Risk scoring
Model routing abstraction
Pre-policy checks
Post-response validation
Request metadata logging

Exit Criteria:

Requests are classified before reaching the model.
Unsafe or unsupported requests are blocked.
Every AI request receives a risk label.
Phase 3 — RAG Service

Objective: Add enterprise knowledge retrieval.

Sources:

Security policies
Runbooks
Architecture docs
Compliance docs

Exit Criteria:

User questions retrieve relevant internal context.
Responses include source references.
Unsupported answers are rejected or marked low confidence.
Phase 4 — Policy Engine

Objective: Enforce governance decisions before AI-assisted actions.

Decisions:

allow
deny
allow_with_audit
approval_required

Exit Criteria:

Ticket creation is governed by policy.
High-risk actions require approval.
Denied actions explain why.
Phase 5 — Human Approval Workflow

Objective: Add human-in-the-loop control.

Exit Criteria:

High-risk requests enter approval queue.
Approved requests can continue.
Rejected requests are logged.
Phase 6 — Observability and Evidence

Objective: Make the platform operationally visible.

Metrics:

Request count
Policy decisions
High-risk requests
Prompt injection attempts
RAG confidence
Model latency
Ticket creation events
Audit records written

Exit Criteria:

Evidence is produced for every request.
Logs can support troubleshooting and compliance review.
Phase 7 — Cloud Scale-Out

Objective: Extend the local architecture into cloud-native enterprise deployment patterns.

Targets:

AWS
Azure
GCP

Exit Criteria:

Terraform modules exist for cloud deployment.
Cloud identity, networking, model access, observability, and secrets are documented.
