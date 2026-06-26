# Phase 1 — Local Enterprise Simulation

## Objective

Phase 1 turns the architecture foundation into a working local enterprise simulation.

The platform now includes mock services for:

- Identity
- CMDB
- Ticketing
- Audit evidence
- API gateway orchestration

## Services

| Service | Port | Purpose |
|---|---:|---|
| api-gateway | 8000 | Main enterprise AI integration entry point |
| identity-service | 8001 | Mock OIDC/JWT/RBAC claims |
| cmdb-adapter | 8002 | Mock enterprise asset inventory |
| ticketing-adapter | 8003 | Mock remediation workflow |
| audit-service | 8004 | Evidence writer for AI-assisted decisions |

## Demo Flow

A security operator asks whether a production database violates backup policy and requests ticket creation.

The API Gateway:

1. Validates the user through the Identity Service.
2. Retrieves asset metadata from the CMDB Adapter.
3. Classifies request risk.
4. Applies deterministic policy logic.
5. Creates a ticket if allowed.
6. Writes an audit evidence record.
7. Returns a structured enterprise AI review response.

## Why This Matters

This phase proves that the lab is not a chatbot. It is an enterprise integration architecture where AI-style reasoning is surrounded by identity, policy, workflow, and evidence controls.

RAG, model inference, policy-as-code, and human approval are added in later phases.
