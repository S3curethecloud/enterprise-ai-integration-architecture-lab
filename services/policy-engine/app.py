from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(
    title="Policy Engine",
    description="Deterministic enterprise policy decision service for AI-assisted workflows.",
    version="0.4.0",
)

TICKET_CREATOR_ROLES = {
    "security_operator",
    "platform_operator",
    "architecture_admin",
}

RISK_ORDER = {
    "low": 1,
    "medium": 2,
    "high": 3,
    "critical": 4,
}


class PolicyEvaluationRequest(BaseModel):
    request_id: str
    user_id: str
    user_role: str
    requested_action: str
    risk_level: str
    asset: dict = Field(default_factory=dict)
    ai_gateway: dict = Field(default_factory=dict)
    rag: dict = Field(default_factory=dict)


def rag_confidence_label(rag: dict) -> str:
    return (
        rag.get("retrieval", {})
        .get("confidence", {})
        .get("label", "none")
    )


def rag_source_count(rag: dict) -> int:
    return (
        rag.get("retrieval", {})
        .get("confidence", {})
        .get("source_count", 0)
    )


def policy_decision(
    user_role: str,
    requested_action: str,
    risk_level: str,
    asset: dict,
    ai_gateway: dict,
    rag: dict,
) -> dict:
    if ai_gateway.get("should_block") is True:
        return {
            "decision": "deny",
            "approval_required": False,
            "evidence_required": True,
            "rule_id": "POL-AI-001",
            "reason": ai_gateway.get("block_reason") or "AI Gateway recommended request block.",
            "controls_required": [
                "audit_evidence",
                "security_review",
                "prompt_injection_record",
            ],
        }

    if risk_level == "critical":
        return {
            "decision": "deny",
            "approval_required": False,
            "evidence_required": True,
            "rule_id": "POL-RISK-004",
            "reason": "Critical action is blocked in the lab control plane.",
            "controls_required": [
                "audit_evidence",
                "executive_review",
            ],
        }

    if risk_level == "high":
        return {
            "decision": "approval_required",
            "approval_required": True,
            "evidence_required": True,
            "rule_id": "POL-RISK-003",
            "reason": "High-risk production or control-plane action requires human approval.",
            "controls_required": [
                "audit_evidence",
                "human_approval",
                "change_review",
            ],
        }

    confidence = rag_confidence_label(rag)
    source_count = rag_source_count(rag)

    if requested_action == "create_ticket":
        if user_role not in TICKET_CREATOR_ROLES:
            return {
                "decision": "deny",
                "approval_required": False,
                "evidence_required": True,
                "rule_id": "POL-AUTHZ-002",
                "reason": "User role is not permitted to create remediation tickets.",
                "controls_required": [
                    "audit_evidence",
                    "access_review",
                ],
            }

        if confidence == "none" or source_count == 0:
            return {
                "decision": "approval_required",
                "approval_required": True,
                "evidence_required": True,
                "rule_id": "POL-RAG-001",
                "reason": "Ticket creation requires retrieved enterprise context.",
                "controls_required": [
                    "audit_evidence",
                    "human_approval",
                    "source_validation",
                ],
            }

        return {
            "decision": "allow_with_audit",
            "approval_required": False,
            "evidence_required": True,
            "rule_id": "POL-TICKET-001",
            "reason": "User role is permitted to create remediation tickets with retrieved enterprise context and audit evidence.",
            "controls_required": [
                "audit_evidence",
                "retrieval_context",
                "ticket_traceability",
            ],
        }

    if requested_action == "answer_only":
        return {
            "decision": "allow",
            "approval_required": False,
            "evidence_required": True,
            "rule_id": "POL-READ-001",
            "reason": "Read-only request is allowed with evidence capture.",
            "controls_required": [
                "audit_evidence",
                "retrieval_context",
            ],
        }

    return {
        "decision": "deny",
        "approval_required": False,
        "evidence_required": True,
        "rule_id": "POL-DEFAULT-000",
        "reason": "Requested action is not supported by the current policy engine scope.",
        "controls_required": [
            "audit_evidence",
            "policy_review",
        ],
    }


@app.get("/health")
def health():
    return {"service": "policy-engine", "status": "ok"}


@app.post("/policy/evaluate")
def evaluate_policy(payload: PolicyEvaluationRequest):
    decision = policy_decision(
        user_role=payload.user_role,
        requested_action=payload.requested_action,
        risk_level=payload.risk_level,
        asset=payload.asset,
        ai_gateway=payload.ai_gateway,
        rag=payload.rag,
    )

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "request_id": payload.request_id,
        "user_id": payload.user_id,
        "user_role": payload.user_role,
        "requested_action": payload.requested_action,
        "risk_level": payload.risk_level,
        "asset_id": payload.asset.get("asset_id"),
        "asset_classification": payload.asset.get("data_classification"),
        "rag_confidence": rag_confidence_label(payload.rag),
        "rag_source_count": rag_source_count(payload.rag),
        "decision": decision["decision"],
        "approval_required": decision["approval_required"],
        "evidence_required": decision["evidence_required"],
        "rule_id": decision["rule_id"],
        "reason": decision["reason"],
        "controls_required": decision["controls_required"],
        "phase": "phase_4_policy_engine",
        "note": "Phase 4 externalizes deterministic policy decisions from the API Gateway into a dedicated Policy Engine service.",
    }
