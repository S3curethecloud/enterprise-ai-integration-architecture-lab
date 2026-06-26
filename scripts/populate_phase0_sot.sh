#!/usr/bin/env bash
set -euo pipefail

cat > README.md <<'EOM'
# Enterprise AI Integration Architecture Lab

Engineering-grade lab for designing scalable AI systems that integrate AI models with existing enterprise IT infrastructure.

## Mission

This lab demonstrates how an AI Architect designs a production-ready AI integration platform that connects AI models to existing systems such as identity providers, CMDBs, ticketing platforms, policy repositories, audit services, observability tools, and cloud infrastructure.

The goal is not to build a simple chatbot.

The goal is to show how enterprise AI systems should be designed with:

- Identity and access control
- Secure AI gateway patterns
- Retrieval-augmented generation over internal knowledge
- Policy-based governance
- Audit evidence
- Human approval for high-risk actions
- Observability and operational controls
- Future cloud-scale deployment paths

## Core Scenario

A regulated enterprise wants to use AI to assist infrastructure, security, and operations teams. The AI system must answer questions, retrieve internal context, evaluate policy, interact with existing systems, and create auditable evidence without bypassing enterprise controls.

Example request:

> Check whether this production database violates backup policy and create a remediation ticket if allowed.

The system must:

1. Authenticate the user.
2. Validate the request.
3. Retrieve relevant policy and runbook context.
4. Query the mock CMDB.
5. Classify risk.
6. Enforce governance policy.
7. Generate a grounded response.
8. Create a ticket only when allowed.
9. Write audit evidence.
10. Require human approval for high-risk actions.

## Architecture Components

| Component | Purpose |
|---|---|
| API Gateway | Entry point for user and system requests |
| Identity Service | Simulates OIDC, JWT claims, roles, and access control |
| AI Gateway | Controls prompts, model routing, risk scoring, and AI request validation |
| RAG Service | Retrieves enterprise knowledge from policies, runbooks, and architecture docs |
| Policy Engine | Decides allow, deny, allow with audit, or approval required |
| CMDB Adapter | Simulates existing infrastructure asset inventory |
| Ticketing Adapter | Simulates remediation workflow integration |
| Audit Service | Writes evidence records for every AI-assisted decision |
| Approval Service | Handles human-in-the-loop workflow for high-risk actions |
| Observability Layer | Tracks latency, risk, decisions, failures, and usage |

## Lab Outcome

By the end of this lab, the platform should demonstrate how to safely integrate AI into enterprise IT workflows while preserving security, governance, scalability, and operational accountability.

## Current Status

- [x] Repository scaffold created
- [x] System-of-truth files initialized
- [ ] Architecture documentation populated
- [ ] Local services implemented
- [ ] Mock enterprise APIs implemented
- [ ] Policy engine implemented
- [ ] RAG workflow implemented
- [ ] Audit evidence generated
- [ ] Tests implemented
- [ ] Cloud deployment tracks added

## Repo Structure

```text
enterprise-ai-integration-architecture-lab/
├── docs/
├── diagrams/
├── services/
├── knowledge-base/
├── tests/
├── evidence/
├── terraform/
└── scripts/
Enterprise-Grade Design Principle

This lab is designed local-first, but not local-only.

The initial version runs in Docker Compose for fast demonstration and interview walkthroughs. The architecture is intentionally modular so each service can later be deployed to AWS, Azure, or GCP using cloud-native compute, identity, networking, observability, and model services.
EOM
cat > ROADMAP.md <<'EOM'

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
EOM

cat > SYSTEM_DESIGN.md <<'EOM'

System Design
Problem Statement

Enterprises want to integrate AI models into existing IT workflows, but uncontrolled AI integration creates risk. AI systems may access sensitive data, produce unsupported answers, trigger actions without approval, or bypass existing governance workflows.

This lab solves that problem by designing an enterprise AI integration architecture where every AI-assisted request passes through identity, policy, retrieval, risk scoring, audit, and observability controls.

Design Goals
Integrate AI with existing enterprise systems.
Preserve identity and role-based authorization.
Retrieve grounded enterprise context before answering.
Prevent unauthorized AI-triggered actions.
Require approval for high-risk operations.
Generate audit evidence for every request.
Support local demonstration and future cloud scaling.
Non-Goals
This is not a generic chatbot.
This is not a multi-agent experiment first.
This is not a model benchmarking project.
This is not a production SaaS platform yet.
This is not tied to one cloud provider or model vendor.
Users
User	Role	Example Need
Cloud Architect	architecture_admin	Review cloud asset posture
Security Engineer	security_operator	Identify policy violations
Platform Engineer	platform_operator	Create remediation tickets
Auditor	audit_reader	Review AI decision evidence
Business User	standard_user	Ask approved policy questions
Core Flow
User sends a request.
API Gateway receives the request.
Identity Service validates user claims.
AI Gateway classifies request type and risk.
RAG Service retrieves relevant enterprise context.
Policy Engine evaluates whether the requested action is allowed.
Model provider generates a grounded response.
Response Orchestrator validates the answer.
Ticketing Adapter creates a ticket if allowed.
Audit Service writes the evidence record.
Observability layer captures metrics and logs.
Risk Levels
Risk Level	Meaning	Example
Low	Read-only information request	Explain backup policy
Medium	Workflow creation with limited blast radius	Create remediation ticket
High	Control-plane or production-impacting action	Disable public access on production asset
Critical	Destructive or sensitive action	Delete resource, expose secret, modify identity policy
System Boundaries

The AI model is not trusted as an authority.

The model can assist with reasoning and summarization, but policy decisions, access control, and approval requirements must be enforced by deterministic services outside the model.
EOM
cat > SECURITY_MODEL.md <<'EOM'

Security Model
Security Objective

The platform must allow AI-assisted enterprise workflows without allowing AI to bypass identity, authorization, governance, audit, or human approval controls.

Core Security Principles
Never trust model output as policy authority.
Authenticate every request.
Authorize every action.
Retrieve only approved context.
Classify data before model exposure.
Log every AI decision.
Require human approval for high-risk actions.
Keep model provider access abstracted and controlled.
Enforce least privilege for service-to-service communication.
Identity Model

The identity-service simulates enterprise identity claims.

Example claim:

{
  "sub": "user-1001",
  "name": "Cloud Architect",
  "role": "architecture_admin",
  "department": "platform-security",
  "clearance": "internal"
}
Authorization Model
Role	Allowed
standard_user	Read approved knowledge base content
security_operator	Review risks and create low/medium tickets
platform_operator	Query assets and propose remediation
architecture_admin	Review architecture, policy, and control decisions
audit_reader	Read evidence records only
AI Threats
Threat	Control
Prompt injection	AI Gateway classifier and sanitizer
Unauthorized action	Policy Engine
Sensitive data exposure	Data classification and retrieval filters
Hallucinated answer	RAG grounding and response validation
Untraceable decision	Audit Service
Excessive model use	Rate limits and token controls
Privilege escalation	Role-based authorization
Risky automation	Human approval workflow
Trust Boundary

The AI model is outside the trusted control boundary.

Trusted services:

Identity Service
Policy Engine
Audit Service
Approval Service

Semi-trusted services:

RAG Service
AI Gateway
Enterprise adapters

Untrusted or externally dependent:

Model provider
User prompt input
Retrieved documents until validated
EOM
cat > GOVERNANCE_MODEL.md <<'EOM'

Governance Model
Governance Objective

The platform must ensure that AI-assisted actions are explainable, policy-aligned, auditable, and controlled by enterprise risk rules.

Decision Types
Decision	Meaning
allow	Request is permitted
deny	Request is blocked
allow_with_audit	Request is permitted but must be logged
approval_required	Request cannot proceed without human approval
Governance Inputs
User role
Request type
Target system
Asset classification
Data classification
Risk level
Retrieved policy context
Requested action
Prior approval state
Example Decision Record
{
  "request_id": "REQ-1001",
  "user_role": "security_operator",
  "request_type": "create_ticket",
  "target_system": "ticketing",
  "asset_classification": "internal",
  "risk_level": "medium",
  "decision": "allow_with_audit",
  "approval_required": false,
  "reason": "Security operators may create remediation tickets for internal assets."
}
High-Risk Rule

Any request that modifies production infrastructure, identity policies, network exposure, encryption settings, or data access controls must require human approval.

Evidence Requirements

Every request must produce an evidence record containing:

request_id
timestamp
user identity
role
request type
retrieved sources
policy decision
risk level
model provider metadata
final response summary
action taken
approval state
EOM
cat > SCALING_STRATEGY.md <<'EOM'

Scaling Strategy
Scaling Philosophy

The lab starts local-first but is designed to scale into a cloud-native enterprise AI integration platform.

Local-first means the system can run on a laptop using Docker Compose for fast demos and interviews.

Enterprise-grade means the system boundaries, interfaces, controls, and deployment paths are designed so the same architecture can be moved to production-grade cloud infrastructure.

Scale Dimensions
Dimension	Local Lab	Enterprise Scale
API Entry	FastAPI	API Gateway, ALB, APIM, Cloud Run ingress
Compute	Docker Compose	ECS, EKS, AKS, GKE, Cloud Run
Identity	Mock JWT	Entra ID, IAM Identity Center, Okta, Cloud Identity
AI Model	Local/mock provider	Bedrock, Azure OpenAI, Vertex AI
RAG Store	Local files/vector DB	OpenSearch, Aurora pgvector, Azure AI Search, AlloyDB
Policy	Local policy engine	OPA, Cedar, managed policy service
Audit	JSON files	S3, CloudWatch, Log Analytics, Cloud Logging
Secrets	.env	Secrets Manager, Key Vault, Secret Manager
Observability	Local logs	OpenTelemetry, Grafana, Cloud-native monitoring
Horizontal Scaling

The services should remain stateless where possible:

api-gateway
ai-gateway
rag-service
policy-engine
ticketing-adapter
cmdb-adapter

Stateful components should be externalized:

vector store
audit storage
ticket records
approval queue
policy repository
Model Scaling

The model layer must be abstracted so the platform can support:

AWS Bedrock
Azure OpenAI
Vertex AI
OpenAI API
local models
future internal models

The AI Gateway should route based on:

risk level
cost profile
latency requirements
data classification
model capability
provider availability
Enterprise Deployment Future

The cloud deployment should eventually include:

private networking
workload identity
service-to-service authorization
centralized logging
secrets management
least privilege IAM
policy-as-code
infrastructure-as-code
CI/CD validation
security tests
EOM
cat > ARCHITECTURE_DECISIONS.md <<'EOM'

Architecture Decisions
ADR-001: Local-First, Cloud-Ready

Decision: Build the first version locally using Docker Compose.

Reason: The lab must be easy to demonstrate, test, and explain before cloud deployment complexity is introduced.

Consequence: Cloud deployment will be added later through Terraform modules.

ADR-002: AI Gateway as Central Control Point

Decision: All model interactions must pass through an AI Gateway.

Reason: Enterprise AI systems need a control plane for prompt validation, request classification, risk scoring, routing, and logging.

Consequence: Application services do not call model providers directly.

ADR-003: Policy Engine Outside the Model

Decision: Policy decisions must be deterministic and external to the AI model.

Reason: The model is not a trusted policy authority.

Consequence: The model may recommend, explain, or summarize, but it cannot authorize enterprise actions.

ADR-004: Adapter Pattern for Existing IT Systems

Decision: Existing enterprise systems are represented through adapters.

Reason: Real enterprises already have CMDBs, ticketing tools, identity providers, data stores, and observability systems.

Consequence: The platform can later replace mock adapters with real integrations.

ADR-005: Evidence as a First-Class Output

Decision: Every request must generate audit evidence.

Reason: Enterprise AI architecture must support traceability, governance, compliance, and incident review.

Consequence: The Audit Service is required from the early phases.
EOM
cat > INTERVIEW_PLAYBOOK.md <<'EOM'

Interview Playbook
Project Pitch

I built the Enterprise AI Integration Architecture Lab to demonstrate how AI models can be integrated into existing enterprise IT infrastructure without bypassing identity, security, governance, or operational controls.

The project is not a simple chatbot. It is a system design lab that models the real architecture an AI Architect would need in a regulated enterprise environment.

What the Lab Demonstrates
System design for scalable AI platforms
AI gateway architecture
RAG over enterprise knowledge
Integration with existing IT systems
Identity and role-based access control
Policy-based governance
Human approval for high-risk actions
Audit evidence for AI-assisted decisions
Observability for AI operations
Cloud-ready deployment planning
STAR Story
Situation

Enterprises want to adopt AI quickly, but many AI pilots fail because they are built as isolated chat interfaces without proper integration into identity, policy, audit, and IT workflows.

Task

I wanted to design a lab that shows how an AI Architect should safely connect AI models to enterprise systems such as CMDBs, ticketing platforms, policies, runbooks, and observability tools.

Action

I designed a modular architecture with an API Gateway, Identity Service, AI Gateway, RAG Service, Policy Engine, CMDB Adapter, Ticketing Adapter, Audit Service, and Approval Service. I made the AI Gateway the central control point for request classification, prompt validation, model routing, and risk scoring. I also kept policy decisions outside the model so that deterministic governance controls decide whether an action is allowed, denied, audited, or routed for approval.

Result

The result is an engineering-grade AI system design lab that demonstrates how to integrate AI into enterprise workflows while preserving governance, security, auditability, and scalability. The lab starts local-first for demonstration but is structured so it can scale into AWS, Azure, or GCP.

Interview Soundbite

This project shows that AI architecture is not just model selection. It is about designing the full integration fabric around the model: identity, data access, retrieval, policy, audit, observability, human control, and cloud scalability.
EOM
cat > diagrams/enterprise-ai-reference-architecture.mmd <<'EOM'
flowchart TB
User[Enterprise User] --> Client[Web UI or CLI Client]
Client --> APIGW[API Gateway]

APIGW --> Identity[Identity Service<br/>OIDC / JWT / RBAC]
Identity --> AIGW[AI Gateway<br/>Prompt Controls / Risk Scoring / Model Routing]

AIGW --> Policy[Policy Engine<br/>Allow / Deny / Approval Required]
AIGW --> RAG[RAG Service<br/>Enterprise Knowledge Retrieval]

RAG --> KB[Knowledge Base<br/>Policies / Runbooks / Architecture Docs]

Policy --> CMDB[CMDB Adapter<br/>Assets / Owners / Classification]
Policy --> Ticketing[Ticketing Adapter<br/>Remediation Workflow]

AIGW --> Model[Model Provider<br/>Bedrock / Azure OpenAI / Vertex AI / Local Model]

Model --> Response[Response Orchestrator<br/>Grounded Answer / Risk / Recommended Action]

Response --> Audit[Audit Service<br/>Evidence / Decision Records]
Response --> Approval[Approval Service<br/>Human-in-the-Loop]

Audit --> Observability[Observability Layer<br/>Logs / Metrics / Traces / Dashboards]

EOM
cat > diagrams/ai-request-flow.mmd <<'EOM'
sequenceDiagram
participant U as User
participant API as API Gateway
participant ID as Identity Service
participant AI as AI Gateway
participant RAG as RAG Service
participant POL as Policy Engine
participant M as Model Provider
participant AUD as Audit Service

U->>API: Submit AI-assisted request
API->>ID: Validate identity and role
ID-->>API: Return claims
API->>AI: Forward request with claims
AI->>AI: Classify prompt and risk
AI->>RAG: Retrieve enterprise context
RAG-->>AI: Return relevant sources
AI->>POL: Evaluate governance policy
POL-->>AI: Decision
AI->>M: Generate grounded response
M-->>AI: Response
AI->>AUD: Write evidence record
AI-->>API: Return final response
API-->>U: Display response

EOM
cat > diagrams/governance-decision-flow.mmd <<'EOM'
flowchart TD
Start[Request Received] --> Auth{Authenticated?}
Auth -- No --> Deny[Deny]
Auth -- Yes --> Classify[Classify Request]

Classify --> Risk{Risk Level}

Risk -- Low --> Allow[Allow]
Risk -- Medium --> Audit[Allow with Audit]
Risk -- High --> Approval[Approval Required]
Risk -- Critical --> DenyCritical[Deny or Executive Approval]

Allow --> Evidence[Write Evidence]
Audit --> Evidence
Approval --> Human[Human Review]
Deny --> Evidence
DenyCritical --> Evidence
Human --> Evidence

EOM
cat > evidence/sample-policy-decision.json <<'EOM'
{
"request_id": "REQ-1001",
"user_role": "security_operator",
"request_type": "create_remediation_ticket",
"target_system": "ticketing",
"asset_classification": "internal",
"risk_level": "medium",
"decision": "allow_with_audit",
"approval_required": false,
"reason": "Security operators may create remediation tickets for internal assets.",
"evidence_required": true
}
EOM
cat > evidence/sample-low-risk-request.json <<'EOM'
{
"request_id": "REQ-LOW-1001",
"user": "standard_user",
"role": "standard_user",
"prompt": "Explain the enterprise backup policy for internal databases.",
"risk_level": "low",
"expected_decision": "allow"
}
EOM
cat > evidence/sample-high-risk-request.json <<'EOM'
{
"request_id": "REQ-HIGH-1001",
"user": "platform_operator",
"role": "platform_operator",
"prompt": "Disable public access on the production database immediately.",
"risk_level": "high",
"expected_decision": "approval_required"
}
EOM
cat > evidence/sample-audit-record.json <<'EOM'
{
"request_id": "REQ-1001",
"timestamp": "2026-06-26T00:00:00Z",
"user": {
"id": "user-1001",
"role": "security_operator"
},
"request": {
"type": "create_remediation_ticket",
"risk_level": "medium",
"data_classification": "internal"
},
"retrieval": {
"sources": [
"knowledge-base/policies/backup-policy.md",
"knowledge-base/runbooks/database-remediation.md"
]
},
"policy_decision": {
"decision": "allow_with_audit",
"approval_required": false
},
"action": {
"ticket_created": true,
"ticket_id": "TICKET-1001"
}
}
EOM
cat > Makefile <<'EOM'
.PHONY: help setup demo test evidence

help:
@echo "Enterprise AI Integration Architecture Lab"
@echo ""
@echo "Available targets:"
@echo " make setup - prepare local environment"
@echo " make demo - run local demo"
@echo " make test - run tests"
@echo " make evidence - generate sample evidence"

setup:
./scripts/setup.sh

demo:
./scripts/run_demo.sh

test:
./scripts/run_tests.sh

evidence:
./scripts/generate_evidence.sh
EOM
cat > scripts/run_tests.sh <<'EOM'
#!/usr/bin/env bash
set -euo pipefail

echo "Running enterprise AI integration lab tests..."
pytest -q
EOM
cat > scripts/generate_evidence.sh <<'EOM'
#!/usr/bin/env bash
set -euo pipefail

echo "Sample evidence records are available in the evidence/ directory."
ls -1 evidence/
EOM
chmod +x scripts/*.sh
echo "Phase 0 System of Truth content populated."
cat > scripts/generate_evidence.sh <<'EOM'
#!/usr/bin/env bash
set -euo pipefail

echo "Sample evidence records are available in the evidence/ directory."
ls -1 evidence/
EOM

chmod +x scripts/*.sh

echo "Phase 0 System of Truth content populated."
