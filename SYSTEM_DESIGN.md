
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
