#!/usr/bin/env bash
set -euo pipefail

echo "Setting up local Python test environment..."

python3 -m venv .venv
. .venv/bin/activate

pip install --upgrade pip
pip install fastapi==0.115.6 uvicorn==0.34.0 pydantic==2.10.4 requests==2.32.3 pytest==8.3.4 httpx==0.28.1

echo "Setup complete."
echo "Activate with: source .venv/bin/activate"
