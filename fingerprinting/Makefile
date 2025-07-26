# Makefile for running fingerprint scans using Molecule
# I used this to determine what base image is closes to Synology DSM 7

.PHONY: fingerprint
fingerprint:
	@echo "👉 Destroy any existing instances"
	@uv run molecule destroy
	@echo "👉 Create & converge new instances"
	@uv run molecule create
	@uv run molecule converge
	@echo "👉 Clean up"
	@uv run molecule destroy

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make fingerprint - Run a fingerprint scan using Molecule"
	@echo "  make help - Show this help message"
