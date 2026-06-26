import importlib.util
from pathlib import Path

from fastapi.testclient import TestClient


ROOT = Path(__file__).resolve().parents[1]


def load_policy_module():
    path = ROOT / "services/policy-engine/app.py"
    spec = importlib.util.spec_from_file_location("policy_engine_app", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_policy_engine_denies_prompt_injection_block():
    module = load_policy_module()

    result = module.policy_decision(
        user_role="security_operator",
        requested_action="create_ticket",
        risk_level="high",
        asset={"asset_id": "db-prod-01"},
        ai_gateway={
            "should_block": True,
            "block_reason": "Prompt injection pattern detected.",
        },
        rag={
            "retrieval": {
                "confidence": {
                    "label": "high",
                    "source_count": 3,
                }
            }
        },
    )

    assert result["decision"] == "deny"
    assert result["rule_id"] == "POL-AI-001"


def test_policy_engine_requires_approval_for_high_risk_action():
    module = load_policy_module()

    result = module.policy_decision(
        user_role="architecture_admin",
        requested_action="disable_public_access",
        risk_level="high",
        asset={"asset_id": "db-prod-01"},
        ai_gateway={"should_block": False},
        rag={
            "retrieval": {
                "confidence": {
                    "label": "high",
                    "source_count": 3,
                }
            }
        },
    )

    assert result["decision"] == "approval_required"
    assert result["approval_required"] is True
    assert result["rule_id"] == "POL-RISK-003"


def test_policy_engine_allows_ticket_with_retrieved_context():
    module = load_policy_module()

    result = module.policy_decision(
        user_role="security_operator",
        requested_action="create_ticket",
        risk_level="medium",
        asset={"asset_id": "db-prod-01"},
        ai_gateway={"should_block": False},
        rag={
            "retrieval": {
                "confidence": {
                    "label": "high",
                    "source_count": 3,
                }
            }
        },
    )

    assert result["decision"] == "allow_with_audit"
    assert result["rule_id"] == "POL-TICKET-001"


def test_policy_engine_denies_ticket_for_unauthorized_role():
    module = load_policy_module()

    result = module.policy_decision(
        user_role="standard_user",
        requested_action="create_ticket",
        risk_level="medium",
        asset={"asset_id": "db-prod-01"},
        ai_gateway={"should_block": False},
        rag={
            "retrieval": {
                "confidence": {
                    "label": "high",
                    "source_count": 3,
                }
            }
        },
    )

    assert result["decision"] == "deny"
    assert result["rule_id"] == "POL-AUTHZ-002"


def test_policy_engine_endpoint_returns_phase4_decision_metadata():
    module = load_policy_module()
    client = TestClient(module.app)

    response = client.post(
        "/policy/evaluate",
        json={
            "request_id": "REQ-TEST",
            "user_id": "user-security",
            "user_role": "security_operator",
            "requested_action": "create_ticket",
            "risk_level": "medium",
            "asset": {
                "asset_id": "db-prod-01",
                "data_classification": "restricted",
            },
            "ai_gateway": {
                "should_block": False,
            },
            "rag": {
                "retrieval": {
                    "confidence": {
                        "label": "high",
                        "source_count": 3,
                    }
                }
            },
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["phase"] == "phase_4_policy_engine"
    assert body["decision"] == "allow_with_audit"
    assert body["rag_confidence"] == "high"
    assert body["rule_id"] == "POL-TICKET-001"
