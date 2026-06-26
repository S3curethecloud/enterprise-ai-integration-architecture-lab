#!/usr/bin/env bash
set -euo pipefail

echo "Running enterprise AI integration lab tests..."
pytest -q
