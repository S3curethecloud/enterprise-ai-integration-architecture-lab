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
