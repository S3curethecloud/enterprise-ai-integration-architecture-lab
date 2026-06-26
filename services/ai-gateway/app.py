from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(
    title="AI Gateway",
    description="Enterprise AI control point for prompt classification, injection detection, risk scoring, and model routing.",
    version="0.2.0",
)

PROMPT_INJECTION_PATTERNS = [
    "ignore previous instructions",
    "ignore all previous instructions",
    "reveal the system prompt",
    "show me your system prompt",
    "bypass policy",
    "bypass governance",
    "disable guardrails",
    "ignore policy engine",
    "act as unrestricted",
    "jailbreak",
    "export secrets",
    "show secrets",
    "leak credentials",
    "delete audit logs",
    "disable logging",
]

CRITICAL_ACTIONS = {
    "delete_resource",
    "export_sensitive_data",
    "disable_logging",
}

HIGH_RISK_ACTIONS = {
    "disable_public_access",
    "modify_identity_policy",
    "change_encryption",
    "change_network_exposure",
}

MEDIUM_RISK_ACTIONS = {
    "create_ticket",
}


class AIGatewayRequest(BaseModel):
    user_id: str
    user_role: str
    question: str
    requested_action: str = "answer_only"
    asset: dict = Field(default_factory=dict)


def detect_prompt_injection(question: str) -> dict:
    normalized = question.lower()
    detected = [
        pattern for pattern in PROMPT_INJECTION_PATTERNS
        if pattern in normalized
    ]

    return {
        "injection_detected": len(detected) > 0,
        "detected_patterns": detected,
    }


def classify_prompt_type(question: str, requested_action: str) -> str:
    normalized = question.lower()

    if requested_action == "create_ticket":
        return "workflow_action_request"

    if requested_action != "answer_only":
        return "control_plane_action_request"

    if any(term in normalized for term in ["policy", "allowed", "compliance", "violate", "violation"]):
        return "policy_question"

    if any(term in normalized for term in ["asset", "database", "server", "cmdb", "production"]):
        return "asset_context_question"

    return "general_enterprise_question"


def estimate_risk_level(requested_action: str, asset: dict, injection_detected: bool) -> str:
    if injection_detected:
        return "high"

    if requested_action in CRITICAL_ACTIONS:
        return "critical"

    if requested_action in HIGH_RISK_ACTIONS:
        return "high"

    if requested_action in MEDIUM_RISK_ACTIONS:
        return "medium"

    if asset.get("environment") == "production" and requested_action != "answer_only":
        return "high"

    if asset.get("data_classification") == "restricted":
        return "medium"

    return "low"


def route_model(risk_level: str, asset: dict) -> dict:
    data_classification = asset.get("data_classification", "unknown")

    if risk_level in {"high", "critical"}:
        return {
            "route": "governed-model-route",
            "model_profile": "restricted-enterprise-reasoning",
            "reason": "High-risk request requires governed model route and deterministic controls.",
        }

    if data_classification == "restricted":
        return {
            "route": "restricted-data-route",
            "model_profile": "internal-context-restricted",
            "reason": "Restricted data classification requires controlled model route.",
        }

    return {
        "route": "standard-enterprise-route",
        "model_profile": "standard-enterprise-assistant",
        "reason": "Request is eligible for standard enterprise model route.",
    }


def controls_for_request(risk_level: str, injection_detected: bool) -> list[str]:
    controls = [
        "request_metadata_recorded",
        "prompt_classified",
        "model_route_selected",
    ]

    if injection_detected:
        controls.extend([
            "prompt_injection_detected",
            "request_block_recommended",
        ])

    if risk_level in {"medium", "high", "critical"}:
        controls.append("policy_engine_required")

    if risk_level in {"high", "critical"}:
        controls.append("human_approval_required")

    return controls


@app.get("/health")
def health():
    return {"service": "ai-gateway", "status": "ok"}


@app.post("/ai-gateway/classify")
def classify_request(payload: AIGatewayRequest):
    injection = detect_prompt_injection(payload.question)
    prompt_type = classify_prompt_type(payload.question, payload.requested_action)
    risk_level = estimate_risk_level(
        requested_action=payload.requested_action,
        asset=payload.asset,
        injection_detected=injection["injection_detected"],
    )
    model_route = route_model(risk_level, payload.asset)
    controls = controls_for_request(risk_level, injection["injection_detected"])

    should_block = injection["injection_detected"]

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id": payload.user_id,
        "user_role": payload.user_role,
        "prompt_type": prompt_type,
        "requested_action": payload.requested_action,
        "risk_level": risk_level,
        "prompt_injection": injection,
        "should_block": should_block,
        "block_reason": "Prompt injection pattern detected." if should_block else None,
        "model_route": model_route,
        "controls_applied": controls,
        "phase": "phase_2_ai_gateway",
        "note": "Phase 2 classifies and routes requests. RAG and live model inference are added in later phases.",
    }
