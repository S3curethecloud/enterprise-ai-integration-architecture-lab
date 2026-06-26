# Phase 4 — Policy Engine

## Objective

Phase 4 externalizes deterministic governance decisions into a dedicated Policy Engine service.

The API Gateway no longer acts as the final policy authority during runtime. It orchestrates identity, CMDB, AI Gateway, RAG Service, and Policy Engine calls.

## Capabilities Added

- Dedicated policy-engine service
- Deterministic policy evaluation
- AI Gateway block enforcement
- RAG confidence-aware policy decisions
- API Gateway integration with Policy Engine
- Audit evidence includes policy-engine decision details

## Policy Inputs

The Policy Engine evaluates:

- user identity
- user role
- requested action
- risk level
- asset classification
- AI Gateway decision metadata
- RAG confidence metadata
- retrieved source count

## Decision Types

- allow
- deny
- allow_with_audit
- approval_required

## Current Scope

This phase creates policy decisions only. It does not implement the approval workflow.

High-risk actions may return `approval_required`, but the actual approval queue is reserved for Phase 5.
