# Phase 3 — RAG Service

## Objective

Phase 3 adds deterministic enterprise knowledge retrieval to the lab.

The RAG Service retrieves relevant internal context from the local knowledge base and returns source references, source summaries, match metadata, and confidence information.

This phase intentionally avoids live LLM calls and vector databases. The goal is to establish a controlled retrieval contract before adding model inference.

## Capabilities Added

- Enterprise knowledge retrieval
- Source reference matching
- Policy and runbook context extraction
- RAG confidence metadata
- API Gateway integration with RAG output
- Audit evidence containing retrieval details

## Retrieval Sources

The RAG Service reads from:

- knowledge-base/policies
- knowledge-base/runbooks
- knowledge-base/architecture
- knowledge-base/compliance

## Retrieval Metadata

Each retrieval result includes:

- source_id
- title
- path
- source_type
- score
- keyword_matches
- content_matches
- excerpt
- confidence label
- confidence score

## Why This Matters

Enterprise AI should not answer from model memory alone.

This phase introduces a controlled retrieval layer so answers and workflow decisions can be tied back to internal policy, runbook, architecture, and compliance sources.

## Out of Scope

- Live LLM inference
- Vector database
- Embedding model
- Cloud deployment
- Multi-agent orchestration
- Observability dashboards
