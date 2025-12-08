.PHONY: help install lint format check test test-cov clean all

help:
	@echo "Available targets:"
	@echo "  install    - Install dependencies with uv"
	@echo "  lint       - Run ruff linter"
	@echo "  format     - Format code with ruff"
	@echo "  check      - Run mypy type checker"
	@echo "  test       - Run pytest"
	@echo "  test-cov   - Run pytest with coverage"
	@echo "  all        - Run lint, check, test"
	@echo "  clean      - Remove cache directories"

install:
	uv sync --dev

lint:
	uv run ruff check .

format:
	uv run ruff format .

check:
	uv run mypy --strict --python-version 3.11 --ignore-missing-imports src/ tests/ scripts/

test:
	uv run pytest

test-cov:
	uv run pytest --cov --cov-report=term-missing

all: lint check test

clean:
	rm -rf .pytest_cache .mypy_cache .ruff_cache __pycache__
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
