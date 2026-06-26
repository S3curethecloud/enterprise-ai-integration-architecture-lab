import importlib.util
from pathlib import Path

from fastapi.testclient import TestClient


ROOT = Path(__file__).resolve().parents[1]


def load_rag_module():
    path = ROOT / "services/rag-service/app.py"
    spec = importlib.util.spec_from_file_location("rag_service_app", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_rag_retrieves_backup_policy_for_database_backup_question():
    module = load_rag_module()
    module.KNOWLEDGE_BASE_ROOT = ROOT / "knowledge-base"

    result = module.retrieve_context(
        question="Does this production database violate backup policy?",
        asset={
            "asset_id": "db-prod-01",
            "type": "database",
            "environment": "production",
            "data_classification": "restricted",
        },
        requested_action="create_ticket",
        max_sources=3,
    )

    paths = result["source_paths"]

    assert "knowledge-base/policies/backup-policy.md" in paths
    assert result["confidence"]["label"] in {"medium", "high"}
    assert result["confidence"]["source_count"] >= 1


def test_rag_retrieves_architecture_context_for_integration_question():
    module = load_rag_module()
    module.KNOWLEDGE_BASE_ROOT = ROOT / "knowledge-base"

    result = module.retrieve_context(
        question="Which identity, CMDB, ticketing, and audit systems are integrated?",
        asset={
            "asset_id": "api-prod-01",
            "type": "api",
            "environment": "production",
            "data_classification": "internal",
        },
        requested_action="answer_only",
        max_sources=3,
    )

    paths = result["source_paths"]

    assert "knowledge-base/architecture/existing-it-landscape.md" in paths
    assert result["confidence"]["source_count"] >= 1


def test_rag_endpoint_returns_source_references():
    module = load_rag_module()
    module.KNOWLEDGE_BASE_ROOT = ROOT / "knowledge-base"
    client = TestClient(module.app)

    response = client.post(
        "/rag/retrieve",
        json={
            "question": "What governance controls apply to AI-assisted decisions?",
            "asset": {
                "asset_id": "db-prod-01",
                "type": "database",
                "environment": "production",
                "data_classification": "restricted",
            },
            "requested_action": "create_ticket",
            "user_role": "security_operator",
            "max_sources": 3,
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["phase"] == "phase_3_rag_service"
    assert len(body["retrieval"]["sources"]) >= 1
    assert body["retrieval"]["confidence"]["label"] in {"low", "medium", "high"}


def test_rag_confidence_none_when_no_source_matches():
    module = load_rag_module()
    module.KNOWLEDGE_BASE_ROOT = ROOT / "knowledge-base"

    result = module.retrieve_context(
        question="zebra spaceship banana ocean unrelated",
        asset={
            "asset_id": "unknown",
            "type": "unknown",
            "environment": "unknown",
            "data_classification": "public",
        },
        requested_action="answer_only",
        max_sources=3,
    )

    assert result["source_paths"] == []
    assert result["confidence"]["label"] == "none"
    assert result["confidence"]["score"] == 0
