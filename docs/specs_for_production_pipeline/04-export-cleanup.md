# Phase 4: Export Cleanup & Scripts Consolidation

> **Status**: Spec
> **Dependency**: Phases 1-3
> **Effort**: Low

---

## Problem 1: `__init__.py` Only Exports ARC

Current exports ignore ISLES24:

```python
# Current __init__.py
from .arc import build_arc_file_table, get_arc_features
from .core import DatasetBuilderConfig, build_hf_dataset, push_dataset_to_hub
from .validation import ValidationResult, validate_arc_download
# ← NO ISLES24!
```

---

## Problem 2: Standalone Scripts Duplicate Module Logic

```
scripts/
├── validate_download.py           # Duplicates validation.py
├── validate_hf_download.py        # Duplicates validation.py
├── validate_isles24_download.py   # No module equivalent
└── validate_isles24_hf_upload.py  # No module equivalent
```

---

## Solution

### New `__init__.py`

```python
"""
bids_hub - Upload BIDS neuroimaging datasets to HuggingFace Hub.

Supported datasets:
- ARC (Aphasia Recovery Cohort) - OpenNeuro ds004884
- ISLES24 (Ischemic Stroke Lesion Segmentation) - Zenodo

Example:
    from bids_hub import DatasetBuilderConfig, build_hf_dataset
    from bids_hub.arc import build_arc_file_table, get_arc_features
    from bids_hub.isles24 import build_isles24_file_table, get_isles24_features
"""

__version__ = "0.2.0"

# Core (generic)
from .core import (
    DatasetBuilderConfig,
    build_hf_dataset,
    push_dataset_to_hub,
    validate_file_table_columns,
)

# Validation (generic + dataset-specific)
from .validation import (
    ValidationCheck,
    ValidationResult,
    DatasetValidationConfig,
    validate_dataset,
    check_zero_byte_files,  # Fast corruption detection
    validate_arc_download,
    validate_isles24_download,
)

# ARC-specific
from .arc import (
    build_arc_file_table,
    get_arc_features,
    build_and_push_arc,
)

# ISLES24-specific
from .isles24 import (
    build_isles24_file_table,
    get_isles24_features,
    build_and_push_isles24,
)

# Config
from .config import (
    BidsDatasetConfig,
    ARC_CONFIG,
    ISLES24_CONFIG,
)

__all__ = [
    # Version
    "__version__",
    # Core
    "DatasetBuilderConfig",
    "build_hf_dataset",
    "push_dataset_to_hub",
    "validate_file_table_columns",
    # Validation
    "ValidationCheck",
    "ValidationResult",
    "DatasetValidationConfig",
    "validate_dataset",
    "check_zero_byte_files",
    "validate_arc_download",
    "validate_isles24_download",
    # ARC
    "build_arc_file_table",
    "get_arc_features",
    "build_and_push_arc",
    # ISLES24
    "build_isles24_file_table",
    "get_isles24_features",
    "build_and_push_isles24",
    # Config
    "BidsDatasetConfig",
    "ARC_CONFIG",
    "ISLES24_CONFIG",
]
```

---

## Scripts Cleanup

### Delete After Module Integration

Once validation framework (Phase 2) is complete, delete:

| Script | Reason |
|--------|--------|
| `validate_download.py` | Use `bids-hub arc validate` |
| `validate_hf_download.py` | Use `bids-hub arc validate` |
| `validate_isles24_download.py` | Use `bids-hub isles24 validate` |
| `validate_isles24_hf_upload.py` | Use `bids-hub isles24 validate` |

### Keep (if useful)

If any scripts have unique functionality not in the CLI, either:
1. Move logic to CLI/module
2. Keep script but import from module

---

## Implementation Checklist

### 1. Update `__init__.py`

Add ISLES24 exports as shown above.

### 2. Verify All Exports Work

```python
# Test all exports
from bids_hub import (
    # Core
    DatasetBuilderConfig,
    build_hf_dataset,
    push_dataset_to_hub,
    # Validation
    check_zero_byte_files,
    validate_arc_download,
    validate_isles24_download,
    # ARC
    build_arc_file_table,
    get_arc_features,
    # ISLES24
    build_isles24_file_table,
    get_isles24_features,
)
```

### 3. Delete Duplicate Scripts

```bash
rm scripts/validate_download.py
rm scripts/validate_hf_download.py
rm scripts/validate_isles24_download.py
rm scripts/validate_isles24_hf_upload.py
```

### 4. Update `scripts/` Directory

If `scripts/` is empty after cleanup, either:
- Delete the directory
- Add a README explaining scripts are now CLI commands
- Keep only truly standalone utilities (e.g., one-off data exploration)

### 5. Bump Version

```python
__version__ = "0.2.0"  # Breaking changes from API/CLI restructure
```

---

## Verification

```bash
# All imports should work
python -c "from bids_hub import build_arc_file_table, build_isles24_file_table"
python -c "from bids_hub import validate_arc_download, validate_isles24_download"

# CLI should replace scripts
bids-hub arc validate /path/to/arc
bids-hub isles24 validate /path/to/isles24

# Tests should pass
uv run pytest -v
```
