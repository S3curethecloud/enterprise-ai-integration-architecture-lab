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
