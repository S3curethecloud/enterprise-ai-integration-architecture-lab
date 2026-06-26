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
