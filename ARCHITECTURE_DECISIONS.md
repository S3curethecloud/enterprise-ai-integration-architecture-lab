
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
