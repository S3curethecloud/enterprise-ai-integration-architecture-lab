from pathlib import Path
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(
    title="RAG Service",
    description="Deterministic enterprise knowledge retrieval service for policies, runbooks, architecture docs, and compliance context.",
    version="0.3.0",
)

KNOWLEDGE_BASE_ROOT = Path("/app/knowledge-base")

SOURCE_REGISTRY = [
    {
        "source_id": "backup-policy",
        "path": "policies/backup-policy.md",
        "title": "Backup Policy",
        "source_type": "policy",
        "keywords": [
            "backup",
            "database",
            "production",
            "recovery",
            "remediation",
            "ticket",
        ],
    },
    {
        "source_id": "ai-usage-policy",
        "path": "policies/ai-usage-policy.md",
        "title": "Enterprise AI Usage Policy",
        "source_type": "policy",
        "keywords": [
            "ai",
            "model",
            "approval",
            "audit",
            "governance",
            "high-risk",
            "policy",
        ],
    },
    {
        "source_id": "database-remediation-runbook",
        "path": "runbooks/database-remediation.md",
        "title": "Database Remediation Runbook",
        "source_type": "runbook",
        "keywords": [
            "database",
            "backup",
            "remediation",
            "owner",
            "ticket",
            "closure",
        ],
    },
    {
        "source_id": "existing-it-landscape",
        "path": "architecture/existing-it-landscape.md",
        "title": "Existing IT Landscape",
        "source_type": "architecture",
        "keywords": [
            "identity",
            "cmdb",
            "ticketing",
            "audit",
            "policy",
            "architecture",
            "integration",
        ],
    },
    {
        "source_id": "ai-governance-control-map",
        "path": "compliance/ai-governance-control-map.md",
        "title": "AI Governance Control Map",
        "source_type": "compliance",
        "keywords": [
            "governance",
            "control",
            "evidence",
            "risk",
            "audit",
            "approval",
            "observability",
        ],
    },
]


class RetrievalRequest(BaseModel):
    question: str
    asset: dict = Field(default_factory=dict)
    requested_action: str = "answer_only"
    user_role: str = "standard_user"
    max_sources: int = 3


def normalize_terms(text: str) -> list[str]:
    separators = [",", ".", ":", ";", "?", "!", "(", ")", "[", "]", "{", "}", "/", "-", "_"]
    normalized = text.lower()
    for separator in separators:
        normalized = normalized.replace(separator, " ")
    return [term for term in normalized.split() if len(term) > 2]


def read_source_content(source: dict) -> str:
    source_path = KNOWLEDGE_BASE_ROOT / source["path"]
    if not source_path.exists():
        return ""
    return source_path.read_text(encoding="utf-8")


def score_source(query_terms: list[str], source: dict, asset: dict, requested_action: str) -> dict:
    content = read_source_content(source)
    content_terms = set(normalize_terms(content))
    keyword_terms = set(source["keywords"])

    query_set = set(query_terms)

    keyword_matches = sorted(query_set.intersection(keyword_terms))
    content_matches = sorted(query_set.intersection(content_terms))

    asset_boosts = []
    if asset.get("type") == "database" and "database" in keyword_terms:
        asset_boosts.append("asset_type_database")
    if asset.get("environment") == "production" and "production" in keyword_terms:
        asset_boosts.append("production_environment")
    if requested_action == "create_ticket" and "ticket" in keyword_terms:
        asset_boosts.append("ticket_action")

    raw_score = (len(keyword_matches) * 3) + len(content_matches) + (len(asset_boosts) * 2)

    return {
        "source_id": source["source_id"],
        "title": source["title"],
        "path": f"knowledge-base/{source['path']}",
        "source_type": source["source_type"],
        "score": raw_score,
        "keyword_matches": keyword_matches,
        "content_matches": content_matches[:10],
        "boosts": asset_boosts,
        "excerpt": content.strip()[:500],
    }


def confidence_label(score: int) -> str:
    if score >= 10:
        return "high"
    if score >= 5:
        return "medium"
    if score > 0:
        return "low"
    return "none"


def retrieve_context(question: str, asset: dict, requested_action: str, max_sources: int) -> dict:
    query_material = " ".join(
        [
            question,
            requested_action,
            str(asset.get("asset_id", "")),
            str(asset.get("type", "")),
            str(asset.get("environment", "")),
            str(asset.get("data_classification", "")),
        ]
    )

    query_terms = normalize_terms(query_material)

    scored = [
        score_source(query_terms, source, asset, requested_action)
        for source in SOURCE_REGISTRY
    ]

    ranked = sorted(scored, key=lambda item: item["score"], reverse=True)
    selected = [item for item in ranked if item["score"] > 0][:max_sources]

    total_score = sum(item["score"] for item in selected)
    confidence = confidence_label(total_score)

    return {
        "query_terms": sorted(set(query_terms)),
        "sources": selected,
        "source_paths": [item["path"] for item in selected],
        "confidence": {
            "label": confidence,
            "score": total_score,
            "source_count": len(selected),
        },
        "retrieval_strategy": "deterministic_keyword_and_metadata_scoring",
    }


@app.get("/health")
def health():
    return {"service": "rag-service", "status": "ok"}


@app.post("/rag/retrieve")
def retrieve(payload: RetrievalRequest):
    result = retrieve_context(
        question=payload.question,
        asset=payload.asset,
        requested_action=payload.requested_action,
        max_sources=payload.max_sources,
    )

    return {
        "question": payload.question,
        "requested_action": payload.requested_action,
        "asset_id": payload.asset.get("asset_id"),
        "retrieval": result,
        "phase": "phase_3_rag_service",
        "note": "Phase 3 performs deterministic enterprise knowledge retrieval. Vector search and live model inference are intentionally out of scope.",
    }
