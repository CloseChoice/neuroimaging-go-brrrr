# Phase 0: Current State Assessment

> **Status**: Reference Document
> **Source**: `arc-aphasia-bids` repository
> **Purpose**: Document current architecture before cleanup

---

## Summary

The `arc-aphasia-bids` repo has grown beyond its original ARC-only scope to support multiple datasets (ARC, ISLES24). The core architecture is solid, but naming, exports, and validation are ARC-centric despite the multi-dataset reality.

---

## Current File Structure

```
arc-aphasia-bids/
├── src/arc_bids/
│   ├── __init__.py       # Only exports ARC stuff (ISSUE)
│   ├── core.py           # GENERIC - Dataset-agnostic (GOOD)
│   ├── config.py         # Has ARC + ISLES24 configs (OK)
│   ├── arc.py            # ARC-specific (GOOD)
│   ├── isles24.py        # ISLES24-specific (GOOD)
│   ├── validation.py     # ARC-ONLY hardcoded (ISSUE)
│   └── cli.py            # Mixed structure (ISSUE)
├── scripts/
│   ├── validate_download.py         # Duplicates validation.py
│   ├── validate_hf_download.py      # Duplicates validation.py
│   ├── validate_isles24_download.py # ISLES24 validation (no module equivalent)
│   └── validate_isles24_hf_upload.py
├── tests/
│   ├── test_arc.py
│   ├── test_isles24.py
│   ├── test_core_nifti.py
│   ├── test_validation.py
│   └── test_cli_skeleton.py
└── pyproject.toml        # Package name: "arc-bids"
```

---

## What's Working Well

### 1. `core.py` - Generic BIDS→HF Engine (~290 lines)

This is genuinely dataset-agnostic and well-designed:

```python
# Key components:
@dataclass
class DatasetBuilderConfig:
    bids_root: Path
    hf_repo_id: str
    split: str | None = None
    dry_run: bool = False

def build_hf_dataset(config, file_table, features) -> Dataset
def push_dataset_to_hub(ds, config, embed_external_files=True, **push_kwargs)
```

**Key feature**: Custom sharded upload with workaround for `huggingface/datasets#7894` (SIGKILL on `Sequence(Nifti())` after `ds.shard()`).

### 2. Dataset-Specific Modules (arc.py, isles24.py)

Clean separation of concerns:

| Module | Function | Schema |
|--------|----------|--------|
| `arc.py` | `build_arc_file_table()` | Session-level (longitudinal) |
| `isles24.py` | `build_isles24_file_table()` | Subject-level (flattened) |

Each provides:
- `build_*_file_table(bids_root) -> pd.DataFrame`
- `get_*_features() -> Features`
- `build_and_push_*(config) -> None`

### 3. Test Coverage

Good tests for both datasets using synthetic BIDS fixtures.

---

## Issues Requiring Cleanup

### Issue 1: Package Naming Mismatch

**Problem**: Package is called `arc-bids` / `arc_bids` but supports ARC + ISLES24.

```toml
# pyproject.toml
[project]
name = "arc-bids"  # ← Misleading
```

**Impact**: Confusing for users, implies ARC-only.

---

### Issue 2: `__init__.py` Only Exports ARC

**Problem**: ISLES24 functionality exists but isn't exported.

```python
# Current __init__.py
from .arc import build_arc_file_table, get_arc_features
from .core import DatasetBuilderConfig, build_hf_dataset, push_dataset_to_hub
from .validation import ValidationResult, validate_arc_download
# ← NO ISLES24 EXPORTS
```

**Impact**: Users can't do `from arc_bids import build_isles24_file_table`.

---

### Issue 3: `validation.py` is ARC-Specific

**Problem**: Hardcoded ARC validation counts from Sci Data paper.

```python
# validation.py
EXPECTED_COUNTS = {
    "subjects": 230,      # ← ARC-specific
    "sessions": 902,      # ← ARC-specific
    "t1w_series": 441,    # ← ARC-specific
    ...
}
```

**Impact**: Can't validate ISLES24 downloads with the same framework.

---

### Issue 4: CLI Structure Inconsistency

**Problem**: ARC commands at top level, ISLES24 as subcommand.

```bash
# Current CLI
arc-bids build ...           # ARC (top-level)
arc-bids validate ...        # ARC (top-level)
arc-bids info                # ARC (top-level)
arc-bids isles24 build ...   # ISLES24 (subcommand)
```

**Impact**: Inconsistent UX. Why is ARC special?

---

### Issue 5: Standalone Scripts Duplicate Module Logic

**Problem**: Scripts in `scripts/` duplicate validation module.

| Script | Duplicates |
|--------|------------|
| `validate_download.py` | `validation.py` |
| `validate_hf_download.py` | `validation.py` |
| `validate_isles24_download.py` | (no module equivalent!) |

**Impact**: Maintenance burden, divergent behavior.

---

## Dependency on Upstream Bug Fix

The package pins `datasets` to a specific git commit:

```toml
[tool.uv.sources]
datasets = { git = "https://github.com/huggingface/datasets.git", rev = "004a5bf4addd..." }
```

**Reason**: PyPI stable has `embed_table_storage` bug causing SIGKILL on `Sequence(Nifti())`.

**Action needed**: Track upstream PR #7896, remove pin when merged.

---

## Metrics

| Metric | Value |
|--------|-------|
| Total Python files | 17 |
| Lines of code (src/) | ~1,150 |
| Lines of code (tests/) | ~600 |
| Datasets supported | 2 (ARC, ISLES24) |
| Test coverage | Good (synthetic fixtures) |

---

## Next Steps

See subsequent phase specs:
- **Phase 1**: Package Renaming (`arc_bids` → `bids_hub`)
- **Phase 2**: Validation Framework Extraction
- **Phase 3**: CLI Structure Normalization
- **Phase 4**: Export Cleanup
