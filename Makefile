.PHONY: help setup demo test evidence

help:
@echo "Enterprise AI Integration Architecture Lab"
@echo ""
@echo "Available targets:"
@echo " make setup - prepare local environment"
@echo " make demo - run local demo"
@echo " make test - run tests"
@echo " make evidence - generate sample evidence"

setup:
./scripts/setup.sh

demo:
./scripts/run_demo.sh

test:
./scripts/run_tests.sh

evidence:
./scripts/generate_evidence.sh
