import os
import uuid
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests

IDENTITY_URL = os.getenv("IDENTITY_URL", "http://identity-service:8000")
CMDB_URL = os.getenv("CMDB_URL", "http://cmdb-adapter:8000")
TICKETING_URL = os.getenv("TICKETING_URL", "http://ticketing-adapter:8000")
AUDIT_URL = os.getenv("AUDIT_URL", "http://audit-service:8000")
AI_GATEWAY_URL = os.getenv("AI_GATEWAY_URL", "http://ai-gateway:8000")
RAG_SERVICE_URL = os.getenv("RAG_SERVICE_URL", "http://rag-service:8000")

app = FastAPI(
    title="Enterprise AI Integration API Gateway",
    description="Control-plane entry point for enterprise AI integration workflow.",
    version="0.3.0",
)


class ReviewRequest(BaseModel):
    user_id: str
    asset_id: str
    question: str
    requested_action: str = "answer_only"


RISK_ORDER = {
    "low": 1,
    "medium": 2,
    "high": 3,
    "critical": 4,
}


def max_risk(left: str, right: str) -> str:
    return left if RISK_ORDER[left] >= RISK_ORDER[right] else right


def classify_risk(requested_action: str, asset: dict) -> str:
    high_risk_actions = {
        "disable_public_access",
        "modify_identity_policy",
        "change_encryption",
        "change_network_exposure",
    }

    critical_actions = {
        "delete_resource",
        "export_sensitive_data",
        "disable_logging",
    }

    if requested_action in critical_actions:
        return "critical"

    if requested_action in high_risk_actions:
        return "high"

    if requested_action == "create_ticket":
        return "medium"

    if asset.get("environment") == "production" and requested_action != "answer_only":
        return "high"

    return "low"


def decide_policy(user_role: str, requested_action: str, risk_level: str) -> dict:
    ticket_roles = {"security_operator", "platform_operator", "architecture_admin"}

    if risk_level == "critical":
        return {
            "decision": "deny",
            "approval_required": False,
            "reason": "Critical action is blocked in the lab control plane.",
        }

    if risk_level == "high":
        return {
            "decision": "approval_required",
            "approval_required": True,
            "reason": "High-risk production or control-plane action requires human approval.",
        }

    if requested_action == "create_ticket":
        if user_role in ticket_roles:
            return {
                "decision": "allow_with_audit",
                "approval_required": False,
                "reason": "User role is permitted to create remediation tickets with audit evidence.",
            }
        return {
            "decision": "deny",
            "approval_required": False,
            "reason": "User role is not permitted to create remediation tickets.",
        }

    return {
        "decision": "allow",
        "approval_required": False,
        "reason": "Read-only request is allowed.",
    }


def deny_for_ai_gateway(ai_gateway_result: dict) -> dict:
    return {
        "decision": "deny",
        "approval_required": False,
        "reason": ai_gateway_result.get("block_reason") or "AI Gateway recommended request block.",
    }


def call_ai_gateway(claims: dict, asset: dict, payload: ReviewRequest) -> dict:
    response = requests.post(
        f"{AI_GATEWAY_URL}/ai-gateway/classify",
        json={
            "user_id": payload.user_id,
            "user_role": claims["role"],
            "question": payload.question,
            "requested_action": payload.requested_action,
            "asset": asset,
        },
        timeout=5,
    )

    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="AI Gateway classification failed")

    return response.json()


def call_rag_service(claims: dict, asset: dict, payload: ReviewRequest) -> dict:
    response = requests.post(
        f"{RAG_SERVICE_URL}/rag/retrieve",
        json={
            "question": payload.question,
            "asset": asset,
            "requested_action": payload.requested_action,
            "user_role": claims["role"],
            "max_sources": 3,
        },
        timeout=5,
    )

    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="RAG retrieval failed")

    return response.json()


def build_grounded_response(asset: dict, question: str, rag_result: dict) -> dict:
    findings = []

    if asset.get("type") == "database" and asset.get("backup_enabled") is False:
        findings.append("Backup policy violation detected: database backup is not enabled.")

    if asset.get("public_access") is True:
        findings.append("Network exposure finding detected: asset has public access enabled.")

    if asset.get("encryption_enabled") is False:
        findings.append("Encryption finding detected: encryption is not enabled.")

    if not findings:
        findings.append("No immediate control violation detected from the available CMDB fields.")

    retrieval = rag_result["retrieval"]

    return {
        "summary": "Enterprise context was evaluated using CMDB asset metadata and retrieved internal policy/runbook sources.",
        "asset": asset["asset_id"],
        "findings": findings,
        "retrieved_sources": retrieval["source_paths"],
        "rag_confidence": retrieval["confidence"],
        "source_summaries": [
            {
                "title": source["title"],
                "path": source["path"],
                "source_type": source["source_type"],
                "score": source["score"],
                "matched_terms": source["keyword_matches"],
            }
            for source in retrieval["sources"]
        ],
        "note": "Phase 3 adds deterministic enterprise knowledge retrieval. Live model inference remains out of scope.",
    }


@app.get("/health")
def health():
    return {"service": "api-gateway", "status": "ok"}


@app.post("/enterprise-ai/review")
def review_request(payload: ReviewRequest):
    request_id = f"REQ-{uuid.uuid4().hex[:12]}"

    claims_response = requests.get(f"{IDENTITY_URL}/claims/{payload.user_id}", timeout=5)
    if claims_response.status_code != 200:
        raise HTTPException(status_code=401, detail="Unable to validate user identity")
    claims = claims_response.json()

    asset_response = requests.get(f"{CMDB_URL}/assets/{payload.asset_id}", timeout=5)
    if asset_response.status_code != 200:
        raise HTTPException(status_code=404, detail="Unable to locate requested asset")
    asset = asset_response.json()

    ai_gateway_result = call_ai_gateway(claims, asset, payload)

    deterministic_risk = classify_risk(payload.requested_action, asset)
    risk_level = max_risk(deterministic_risk, ai_gateway_result["risk_level"])

    rag_result = call_rag_service(claims, asset, payload)

    if ai_gateway_result.get("should_block"):
        policy = deny_for_ai_gateway(ai_gateway_result)
    else:
        policy = decide_policy(claims["role"], payload.requested_action, risk_level)

    grounded_response = build_grounded_response(asset, payload.question, rag_result)

    action_taken = "none"
    ticket = None

    if payload.requested_action == "create_ticket" and policy["decision"] == "allow_with_audit":
        ticket_response = requests.post(
            f"{TICKETING_URL}/tickets",
            json={
                "asset_id": payload.asset_id,
                "summary": f"AI-assisted remediation review: {grounded_response['findings'][0]}",
                "severity": risk_level,
                "created_by": payload.user_id,
            },
            timeout=5,
        )
        ticket_response.raise_for_status()
        ticket = ticket_response.json()
        action_taken = "ticket_created"

    if ai_gateway_result.get("should_block"):
        action_taken = "blocked_by_ai_gateway"

    audit_payload = {
        "request_id": request_id,
        "user_id": payload.user_id,
        "user_role": claims["role"],
        "request_type": payload.requested_action,
        "risk_level": risk_level,
        "policy_decision": policy["decision"],
        "approval_required": policy["approval_required"],
        "asset_id": payload.asset_id,
        "action_taken": action_taken,
        "retrieved_sources": grounded_response["retrieved_sources"],
        "details": {
            "policy_reason": policy["reason"],
            "findings": grounded_response["findings"],
            "ticket": ticket,
            "ai_gateway": ai_gateway_result,
            "rag": rag_result,
        },
    }

    audit_response = requests.post(f"{AUDIT_URL}/audit", json=audit_payload, timeout=5)
    audit_response.raise_for_status()

    return {
        "request_id": request_id,
        "user": {
            "id": claims["sub"],
            "role": claims["role"],
            "department": claims["department"],
        },
        "asset": {
            "asset_id": asset["asset_id"],
            "name": asset["name"],
            "environment": asset["environment"],
            "classification": asset["data_classification"],
        },
        "ai_gateway": ai_gateway_result,
        "rag": rag_result,
        "risk_level": risk_level,
        "policy_decision": policy,
        "grounded_response": grounded_response,
        "action_taken": action_taken,
        "ticket": ticket,
        "audit": audit_response.json(),
    }
