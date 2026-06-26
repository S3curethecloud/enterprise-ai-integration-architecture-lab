import importlib.util
from pathlib import Path

from fastapi.testclient import TestClient


ROOT = Path(__file__).resolve().parents[1]


def load_app(relative_path: str):
    path = ROOT / relative_path
    spec = importlib.util.spec_from_file_location(path.stem, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module.app


def test_identity_service_returns_security_operator_claims():
    app = load_app("services/identity-service/app.py")
    client = TestClient(app)

    response = client.get("/claims/user-security")

    assert response.status_code == 200
    body = response.json()
    assert body["role"] == "security_operator"
    assert "ticket:create" in body["permissions"]


def test_cmdb_adapter_returns_production_database_asset():
    app = load_app("services/cmdb-adapter/app.py")
    client = TestClient(app)

    response = client.get("/assets/db-prod-01")

    assert response.status_code == 200
    body = response.json()
    assert body["environment"] == "production"
    assert body["backup_enabled"] is False
    assert body["data_classification"] == "restricted"


def test_ticketing_adapter_creates_ticket():
    app = load_app("services/ticketing-adapter/app.py")
    client = TestClient(app)

    response = client.post(
        "/tickets",
        json={
            "asset_id": "db-prod-01",
            "summary": "Backup policy violation detected",
            "severity": "medium",
            "created_by": "user-security",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["ticket_id"].startswith("TICKET-")
    assert body["status"] == "open"


def test_api_gateway_policy_allows_security_operator_ticket_creation():
    path = ROOT / "services/api-gateway/app.py"
    spec = importlib.util.spec_from_file_location("api_gateway_app", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)

    decision = module.decide_policy(
        user_role="security_operator",
        requested_action="create_ticket",
        risk_level="medium",
    )

    assert decision["decision"] == "allow_with_audit"
    assert decision["approval_required"] is False


def test_api_gateway_policy_requires_approval_for_high_risk_action():
    path = ROOT / "services/api-gateway/app.py"
    spec = importlib.util.spec_from_file_location("api_gateway_app_high_risk", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)

    decision = module.decide_policy(
        user_role="architecture_admin",
        requested_action="disable_public_access",
        risk_level="high",
    )

    assert decision["decision"] == "approval_required"
    assert decision["approval_required"] is True
