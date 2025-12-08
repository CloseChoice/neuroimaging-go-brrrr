# Phase 1: Package Renaming

> **Status**: Spec
> **Dependency**: None (can start immediately)
> **Effort**: Medium (find-replace + test fixes)

---

## Problem

Package is named `arc-bids` / `arc_bids` but supports multiple datasets (ARC, ISLES24, potentially more). The name implies ARC-only scope.

---

## Proposed Solution

Rename to a generic name that reflects multi-dataset capability.

### Option A: `bids-hub` (Recommended)

```
bids-hub/
└── src/bids_hub/
    ├── core.py
    ├── arc.py
    ├── isles24.py
    └── ...
```

**Pros**:
- Clear purpose: BIDS datasets → HuggingFace Hub
- Short, memorable
- Doesn't conflict with existing packages

**CLI**: `bids-hub build arc ...`

### Option B: `neuroimaging-hub`

```
neuroimaging-hub/
└── src/neuroimaging_hub/
```

**Pros**: Broader scope (not just BIDS)
**Cons**: Longer, may imply more than we deliver

### Option C: `hf-bids`

**Pros**: HuggingFace association clear
**Cons**: May conflict with official HF naming conventions

---

## Recommendation

**Use `bids-hub`** for now. Can always rename later if HuggingFace adopts this officially.

---

## Implementation Checklist

### 1. Directory Rename

```bash
# Rename package directory
mv src/arc_bids src/bids_hub
```

### 2. Update `pyproject.toml`

```toml
[project]
name = "bids-hub"  # Was: arc-bids
description = "Upload BIDS neuroimaging datasets to HuggingFace Hub"
keywords = ["bids", "nifti", "neuroimaging", "huggingface", "datasets", "mri", "stroke", "aphasia"]

[project.scripts]
bids-hub = "bids_hub.cli:app"  # Was: arc-bids = "arc_bids.cli:app"

[tool.hatch.build.targets.wheel]
packages = ["src/bids_hub"]  # Was: src/arc_bids

[tool.ruff.lint.isort]
known-first-party = ["bids_hub"]  # Was: arc_bids
```

### 3. Update All Imports

Find and replace across all files:

| Old | New |
|-----|-----|
| `from arc_bids` | `from bids_hub` |
| `import arc_bids` | `import bids_hub` |
| `arc_bids.` | `bids_hub.` |

Files to update:
- `src/bids_hub/__init__.py`
- `src/bids_hub/cli.py`
- `src/bids_hub/arc.py`
- `src/bids_hub/isles24.py`
- `tests/*.py`
- `scripts/*.py`
- `README.md`
- `CLAUDE.md`

### 4. Update CLI Help Text

```python
# cli.py
app = typer.Typer(
    name="bids-hub",  # Was: arc-bids
    help="Upload BIDS neuroimaging datasets to HuggingFace Hub.",
)
```

### 5. Update `__init__.py` Docstring

```python
"""
bids_hub - Upload BIDS neuroimaging datasets to HuggingFace Hub.

Supported datasets:
- ARC (Aphasia Recovery Cohort) - OpenNeuro ds004884
- ISLES24 (Ischemic Stroke Lesion Segmentation) - Zenodo
...
"""
```

### 6. Update README.md

- Change all references from `arc-bids` to `bids-hub`
- Update installation: `pip install bids-hub`
- Update CLI examples: `bids-hub build ...`

### 7. Run Tests

```bash
uv run pytest -v
```

Fix any import errors.

### 8. Update GitHub Repo Name (Optional)

If desired, rename GitHub repo:
- `arc-aphasia-bids` → `bids-hub`

**Note**: This breaks existing links. Consider keeping old repo as redirect.

---

## Verification

After renaming:

```bash
# CLI should work
bids-hub --help
bids-hub arc build --help
bids-hub isles24 build --help

# Imports should work
python -c "from bids_hub import build_hf_dataset, build_arc_file_table"
python -c "from bids_hub.isles24 import build_isles24_file_table"

# Tests should pass
uv run pytest -v
```

---

## Rollback Plan

If issues arise, revert with:

```bash
git checkout main -- .
```

Keep old `arc-bids` name available as alias in pyproject.toml if needed for backward compatibility.
