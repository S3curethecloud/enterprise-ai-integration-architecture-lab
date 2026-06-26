# Phase 2 — AI Gateway

## Objective

Phase 2 introduces an AI Gateway as the enterprise control point between user requests, model routing, governance, and existing IT integrations.

This phase does not add RAG or live model inference yet. It creates the control-plane layer needed before those capabilities are introduced.

## Capabilities Added

- Prompt classification
- Prompt injection detection
- Risk scoring metadata
- Model routing abstraction
- Request control metadata
- API Gateway integration with AI Gateway

## Why This Matters

Enterprise AI systems need a control point that evaluates a request before it reaches a model or triggers an enterprise workflow.

The AI Gateway helps answer:

- What kind of request is this?
- Does the prompt contain injection patterns?
- What is the risk level?
- Which model route should be used?
- Which controls should be applied?
- Should this request be blocked before policy or action execution?

## AI Gateway Decisions

| Output | Purpose |
|---|---|
| prompt_type | Classifies request intent |
| risk_level | Estimates AI-specific request risk |
| prompt_injection | Captures injection detection results |
| should_block | Recommends block for unsafe prompt patterns |
| model_route | Selects abstract model route |
| controls_applied | Lists controls activated for the request |

## Current Scope

In Phase 2, the AI Gateway does not call a real LLM.

It provides deterministic classification, routing, and control metadata so the platform can later integrate RAG and model providers safely.

## Exit Criteria

- AI Gateway service runs locally.
- API Gateway calls AI Gateway before policy/action execution.
- Prompt injection attempt is detected.
- Blocked request creates audit evidence.
- Safe ticket workflow still works.
- Tests validate classification and routing behavior.
