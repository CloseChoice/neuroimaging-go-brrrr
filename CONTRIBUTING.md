# Contributing to neuroimaging-go-brrrr

## Quick Start

1. Fork and clone the repo
2. Install dependencies: `uv sync`
3. Run tests: `make test`

## Development Setup

- **Python 3.11+** required
- **[uv](https://docs.astral.sh/uv/)** required for dependency management
- **Docker** (optional, for DeepISLES inference)

## Code Style

- Formatting: `make format` (ruff)
- Linting: `make lint` (ruff)
- Type checking: `make check` (mypy --strict)

## Pull Request Process

1. Update tests for new functionality
2. Ensure `make all` passes
3. Keep PRs focused and small
