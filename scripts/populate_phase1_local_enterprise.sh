#!/usr/bin/env bash
set -euo pipefail

echo "Populating Phase 1 local enterprise simulation..."

mkdir -p services/api-gateway
mkdir -p services/identity-service
mkdir -p services/cmdb-adapter
mkdir -p services/ticketing-adapter
mkdir -p services/audit-service
mkdir -p knowledge-base/policies
mkdir -p knowledge-base/runbooks
mkdir -p knowledge-base/architecture
mkdir -p evidence/generated
mkdir -p tests

cat > services/identity-service/requirements.txt <<'EOM'
fastapi==0.115.6
uvicorn==0.34.0
pydantic==2.10.4
EOM

cat > services/identity-service/Dockerfile <<'EOM'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOM

cat > services/identity-service/app.py <<'EOM'
from fastapi import FastAPI, HTTPException

app = FastAPI(
    title="Identity Service",
    description="Mock enterprise identity service for AI integration architecture lab.",
    version="0.1.0",
)

USERS = {
    "user-standard": {
        "sub": "user-standard",
        "name": "Standard Business User",
        "role": "standard_user",
        "department": "business",
        "clearance": "public",
        "permissions": ["knowledge:read"],
    },
    "user-security": {
        "sub": "user-security",
        "name": "Security Operator",
        "role": "security_operator",
        "department": "security",
        "clearance": "internal",
        "permissions": ["knowledge:read", "asset:read", "ticket:create"],
    },
    "user-platform": {
        "sub": "user-platform",
        "name": "Platform Operator",
        "role": "platform_operator",
        "department": "platform",
        "clearance": "internal",
        "permissions": ["knowledge:read", "asset:read", "ticket:create"],
    },
    "user-architect": {
        "sub": "user-architect",
        "name": "Enterprise AI Architect",
        "role": "architecture_admin",
        "department": "architecture",
        "clearance": "restricted",
        "permissions": ["knowledge:read", "asset:read", "ticket:create", "policy:review", "audit:read"],
    },
    "user-auditor": {
        "sub": "user-auditor",
        "name": "Audit Reader",
        "role": "audit_reader",
        "department": "audit",
        "clearance": "internal",
        "permissions": ["audit:read"],
    },
}


@app.get("/health")
def health():
    return {"service": "identity-service", "status": "ok"}


@app.get("/claims/{user_id}")
def get_claims(user_id: str):
    user = USERS.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Unknown user")
    return user
EOM

cat > services/cmdb-adapter/requirements.txt <<'EOM'
fastapi==0.115.6
uvicorn==0.34.0
pydantic==2.10.4
EOM

cat > services/cmdb-adapter/Dockerfile <<'EOM'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOM

cat > services/cmdb-adapter/app.py <<'EOM'
from fastapi import FastAPI, HTTPException

app = FastAPI(
    title="CMDB Adapter",
    description="Mock CMDB adapter representing existing enterprise IT asset inventory.",
    version="0.1.0",
)

ASSETS = {
    "db-prod-01": {
        "asset_id": "db-prod-01",
        "name": "Customer Production Database",
        "type": "database",
        "environment": "production",
        "owner": "payments-platform",
        "data_classification": "restricted",
        "backup_enabled": False,
        "public_access": False,
        "encryption_enabled": True,
        "criticality": "high",
    },
    "api-prod-01": {
        "asset_id": "api-prod-01",
        "name": "Production Payments API",
        "type": "api",
        "environment": "production",
        "owner": "payments-platform",
        "data_classification": "internal",
        "backup_enabled": True,
        "public_access": True,
        "encryption_enabled": True,
        "criticality": "high",
    },
    "vm-dev-01": {
        "asset_id": "vm-dev-01",
        "name": "Development Utility VM",
        "type": "virtual_machine",
        "environment": "development",
        "owner": "platform-engineering",
        "data_classification": "internal",
        "backup_enabled": True,
        "public_access": False,
        "encryption_enabled": True,
        "criticality": "low",
    },
}


@app.get("/health")
def health():
    return {"service": "cmdb-adapter", "status": "ok"}


@app.get("/assets")
def list_assets():
    return {"assets": list(ASSETS.values())}


@app.get("/assets/{asset_id}")
def get_asset(asset_id: str):
    asset = ASSETS.get(asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Unknown asset")
    return asset
EOM

cat > services/ticketing-adapter/requirements.txt <<'EOM'
fastapi==0.115.6
uvicorn==0.34.0
pydantic==2.10.4
EOM

cat > services/ticketing-adapter/Dockerfile <<'EOM'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOM

cat > services/ticketing-adapter/app.py <<'EOM'
from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(
    title="Ticketing Adapter",
    description="Mock ticketing adapter representing an existing enterprise remediation workflow.",
    version="0.1.0",
)

TICKETS = []


class TicketCreate(BaseModel):
    asset_id: str
    summary: str
    severity: str = Field(default="medium")
    created_by: str
    source: str = Field(default="enterprise-ai-integration-lab")


@app.get("/health")
def health():
    return {"service": "ticketing-adapter", "status": "ok"}


@app.get("/tickets")
def list_tickets():
    return {"tickets": TICKETS}


@app.post("/tickets")
def create_ticket(ticket: TicketCreate):
    ticket_id = f"TICKET-{len(TICKETS) + 1001}"
    record = {
        "ticket_id": ticket_id,
        "asset_id": ticket.asset_id,
        "summary": ticket.summary,
        "severity": ticket.severity,
        "created_by": ticket.created_by,
        "source": ticket.source,
        "status": "open",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    TICKETS.append(record)
    return record
EOM

cat > services/audit-service/requirements.txt <<'EOM'
fastapi==0.115.6
uvicorn==0.34.0
pydantic==2.10.4
EOM

cat > services/audit-service/Dockerfile <<'EOM'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOM

cat > services/audit-service/app.py <<'EOM'
import json
from datetime import datetime, timezone
from pathlib import Path
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(
    title="Audit Service",
    description="Evidence writer for AI-assisted enterprise decisions.",
    version="0.1.0",
)

AUDIT_EVENTS = []
EVIDENCE_DIR = Path("/app/evidence/generated")
EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)


class AuditEvent(BaseModel):
    request_id: str
    user_id: str
    user_role: str
    request_type: str
    risk_level: str
    policy_decision: str
    approval_required: bool
    asset_id: str | None = None
    action_taken: str | None = None
    retrieved_sources: list[str] = Field(default_factory=list)
    details: dict = Field(default_factory=dict)


@app.get("/health")
def health():
    return {"service": "audit-service", "status": "ok"}


@app.get("/audit")
def list_audit_events():
    return {"events": AUDIT_EVENTS}


@app.post("/audit")
def write_audit_event(event: AuditEvent):
    record = event.model_dump()
    record["timestamp"] = datetime.now(timezone.utc).isoformat()
    AUDIT_EVENTS.append(record)

    output_file = EVIDENCE_DIR / f"{record['request_id']}.json"
    output_file.write_text(json.dumps(record, indent=2), encoding="utf-8")

    return {
        "status": "written",
        "request_id": record["request_id"],
        "evidence_file": str(output_file),
    }
EOM

cat > services/api-gateway/requirements.txt <<'EOM'
fastapi==0.115.6
uvicorn==0.34.0
pydantic==2.10.4
requests==2.32.3
EOM

cat > services/api-gateway/Dockerfile <<'EOM'
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOM

cat > services/api-gateway/app.py <<'EOM'
import os
import uuid
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests

IDENTITY_URL = os.getenv("IDENTITY_URL", "http://identity-service:8000")
CMDB_URL = os.getenv("CMDB_URL", "http://cmdb-adapter:8000")
TICKETING_URL = os.getenv("TICKETING_URL", "http://ticketing-adapter:8000")
AUDIT_URL = os.getenv("AUDIT_URL", "http://audit-service:8000")

app = FastAPI(
    title="Enterprise AI Integration API Gateway",
    description="Control-plane entry point for enterprise AI integration workflow.",
    version="0.1.0",
)


class ReviewRequest(BaseModel):
    user_id: str
    asset_id: str
    question: str
    requested_action: str = "answer_only"


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


def build_grounded_response(asset: dict, question: str) -> dict:
    findings = []

    if asset.get("type") == "database" and asset.get("backup_enabled") is False:
        findings.append("Backup policy violation detected: database backup is not enabled.")

    if asset.get("public_access") is True:
        findings.append("Network exposure finding detected: asset has public access enabled.")

    if asset.get("encryption_enabled") is False:
        findings.append("Encryption finding detected: encryption is not enabled.")

    if not findings:
        findings.append("No immediate control violation detected from the available CMDB fields.")

    return {
        "summary": "Enterprise context was evaluated using CMDB asset metadata and internal policy references.",
        "asset": asset["asset_id"],
        "findings": findings,
        "retrieved_sources": [
            "knowledge-base/policies/backup-policy.md",
            "knowledge-base/policies/ai-usage-policy.md",
            "knowledge-base/runbooks/database-remediation.md",
        ],
        "note": "Phase 1 uses deterministic enterprise simulation. RAG and model inference are added in later phases.",
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

    risk_level = classify_risk(payload.requested_action, asset)
    policy = decide_policy(claims["role"], payload.requested_action, risk_level)
    grounded_response = build_grounded_response(asset, payload.question)

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
        "risk_level": risk_level,
        "policy_decision": policy,
        "grounded_response": grounded_response,
        "action_taken": action_taken,
        "ticket": ticket,
        "audit": audit_response.json(),
    }
EOM

cat > knowledge-base/policies/backup-policy.md <<'EOM'
# Backup Policy

Production databases must have backup enabled.

Restricted or customer-impacting systems must be covered by recovery procedures, operational ownership, and remediation tracking.

If backup is disabled on a production database, the platform should create a remediation ticket when the requesting user has permission. Direct infrastructure changes require human approval.
EOM

cat > knowledge-base/policies/ai-usage-policy.md <<'EOM'
# Enterprise AI Usage Policy

AI systems may assist with analysis, summarization, retrieval, and recommendation.

AI systems must not directly authorize high-risk enterprise actions. Production-impacting actions require deterministic policy evaluation and human approval.

Every AI-assisted decision must create audit evidence.
EOM

cat > knowledge-base/runbooks/database-remediation.md <<'EOM'
# Database Remediation Runbook

When a production database violates backup policy:

1. Confirm asset ownership.
2. Confirm environment and data classification.
3. Create a remediation ticket.
4. Assign the owning platform team.
5. Track remediation to closure.
6. Preserve audit evidence.
EOM

cat > knowledge-base/architecture/existing-it-landscape.md <<'EOM'
# Existing IT Landscape

The lab simulates an enterprise environment with the following systems:

- Identity provider
- CMDB
- Ticketing platform
- Audit evidence store
- AI integration gateway
- Policy enforcement layer
- Enterprise knowledge base
EOM

cat > docker-compose.yml <<'EOM'
services:
  identity-service:
    build: ./services/identity-service
    ports:
      - "8001:8000"

  cmdb-adapter:
    build: ./services/cmdb-adapter
    ports:
      - "8002:8000"

  ticketing-adapter:
    build: ./services/ticketing-adapter
    ports:
      - "8003:8000"

  audit-service:
    build: ./services/audit-service
    ports:
      - "8004:8000"
    volumes:
      - ./evidence:/app/evidence

  api-gateway:
    build: ./services/api-gateway
    ports:
      - "8000:8000"
    environment:
      IDENTITY_URL: http://identity-service:8000
      CMDB_URL: http://cmdb-adapter:8000
      TICKETING_URL: http://ticketing-adapter:8000
      AUDIT_URL: http://audit-service:8000
    depends_on:
      - identity-service
      - cmdb-adapter
      - ticketing-adapter
      - audit-service
EOM

cat > scripts/setup.sh <<'EOM'
#!/usr/bin/env bash
set -euo pipefail

echo "Setting up local Python test environment..."

python3 -m venv .venv
. .venv/bin/activate

pip install --upgrade pip
pip install fastapi==0.115.6 uvicorn==0.34.0 pydantic==2.10.4 requests==2.32.3 pytest==8.3.4 httpx==0.28.1

echo "Setup complete."
echo "Activate with: source .venv/bin/activate"
EOM

cat > scripts/run_demo.sh <<'EOM'
#!/usr/bin/env bash
set -euo pipefail

echo "Starting local enterprise AI integration simulation..."
docker compose up -d --build

echo "Waiting for services..."
sleep 5

echo ""
echo "Health checks:"
curl -s http://localhost:8000/health | python3 -m json.tool
curl -s http://localhost:8001/health | python3 -m json.tool
curl -s http://localhost:8002/health | python3 -m json.tool
curl -s http://localhost:8003/health | python3 -m json.tool
curl -s http://localhost:8004/health | python3 -m json.tool

echo ""
echo "Demo request: security operator creates remediation ticket for production database backup issue"
curl -s -X POST http://localhost:8000/enterprise-ai/review \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-security",
    "asset_id": "db-prod-01",
    "question": "Does this production database violate backup policy?",
    "requested_action": "create_ticket"
  }' | python3 -m json.tool

echo ""
echo "Generated evidence:"
ls -1 evidence/generated || true
EOM

cat > scripts/run_tests.sh <<'EOM'
#!/usr/bin/env bash
set -euo pipefail

if [ -d ".venv" ]; then
  . .venv/bin/activate
fi

pytest -q
EOM

cat > tests/test_phase1_contracts.py <<'EOM'
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
EOM

cat > docs/11-phase1-local-enterprise-simulation.md <<'EOM'
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
EOM

chmod +x scripts/*.sh

echo "Phase 1 local enterprise simulation populated."
