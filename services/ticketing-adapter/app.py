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
