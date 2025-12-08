# Phase 2: Validation Framework Extraction

> **Status**: Spec
> **Dependency**: Phase 1 (Package Renaming) - optional but recommended
> **Effort**: Medium-High

---

## Problem

Current `validation.py` is ARC-specific with hardcoded counts from the Sci Data paper:

```python
EXPECTED_COUNTS = {
    "subjects": 230,      # ARC-specific
    "sessions": 902,      # ARC-specific
    "t1w_series": 441,    # ARC-specific
    ...
}
```

ISLES24 has NO validation module - only standalone scripts in `scripts/`.

---

## Proposed Solution

Extract a **generic validation framework** with **dataset-specific configs**.

### New Structure

```
src/bids_hub/
├── validation/
│   ├── __init__.py       # Exports ValidationResult, validate_dataset()
│   ├── base.py           # Generic validation framework
│   ├── arc.py            # ARC-specific config + checks
│   └── isles24.py        # ISLES24-specific config + checks
```

---

## Design

### Generic Framework (`validation/base.py`)

```python
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

@dataclass
class ValidationCheck:
    """Result of a single validation check."""
    name: str
    expected: str
    actual: str
    passed: bool
    details: str = ""

@dataclass
class ValidationResult:
    """Complete validation results."""
    bids_root: Path
    checks: list[ValidationCheck] = field(default_factory=list)

    @property
    def all_passed(self) -> bool: ...
    def summary(self) -> str: ...

@dataclass
class DatasetValidationConfig:
    """Configuration for validating a specific dataset."""
    name: str
    expected_counts: dict[str, int]
    required_files: list[str]
    modality_patterns: dict[str, str]  # e.g., {"t1w": "*_T1w.nii.gz"}
    custom_checks: list[Callable[[Path], ValidationCheck]] = field(default_factory=list)

def check_zero_byte_files(bids_root: Path) -> tuple[int, list[str]]:
    """
    CRITICAL: Fast detection of zero-byte NIfTI files (common corruption indicator).

    This check is HIGH PRIORITY from audit - faster than nibabel integrity checks
    and catches obvious corruption before expensive decompression.

    Returns:
        (count of zero-byte files, list of relative paths)
    """
    zero_byte_files = []
    for nifti in bids_root.rglob("*.nii.gz"):
        if nifti.stat().st_size == 0:
            zero_byte_files.append(str(nifti.relative_to(bids_root)))
    return len(zero_byte_files), zero_byte_files

def validate_dataset(
    bids_root: Path,
    config: DatasetValidationConfig,
    run_bids_validator: bool = False,
    nifti_sample_size: int = 10,
    tolerance: float = 0.0,
) -> ValidationResult:
    """
    Generic validation using dataset-specific config.

    Always runs:
    1. Required files check
    2. Zero-byte file detection (fast, catches obvious corruption)
    3. Subject/session counts (with tolerance)
    4. Modality counts (based on config patterns)
    5. Optional: BIDS validator
    6. Optional: NIfTI integrity spot-check (nibabel)
    """
    ...
```

### ARC-Specific Config (`validation/arc.py`)

```python
from .base import DatasetValidationConfig

# Expected counts from Sci Data paper (Gibson et al., 2024)
ARC_VALIDATION_CONFIG = DatasetValidationConfig(
    name="arc",
    expected_counts={
        "subjects": 230,
        "sessions": 902,
        "t1w_series": 441,
        "t2w_series": 447,
        "flair_series": 235,
        "bold_series": 850,
        "dwi_series": 613,
        "sbref_series": 88,
        "lesion_masks": 230,
    },
    required_files=[
        "dataset_description.json",
        "participants.tsv",
        "participants.json",
    ],
    modality_patterns={
        "t1w": "*_T1w.nii.gz",
        "t2w": "*_T2w.nii.gz",
        "flair": "*_FLAIR.nii.gz",
        "bold": "*_bold.nii.gz",
        "dwi": "*_dwi.nii.gz",
        "sbref": "*_sbref.nii.gz",
        "lesion": "*_desc-lesion_mask.nii.gz",
    },
)

def validate_arc_download(bids_root: Path, **kwargs) -> ValidationResult:
    """Convenience wrapper for ARC validation."""
    from .base import validate_dataset
    return validate_dataset(bids_root, ARC_VALIDATION_CONFIG, **kwargs)
```

### ISLES24-Specific Config (`validation/isles24.py`)

```python
from .base import DatasetValidationConfig

# Expected counts from Zenodo v7 (source: scripts/validate_isles24_download.py)
ISLES24_VALIDATION_CONFIG = DatasetValidationConfig(
    name="isles24",
    expected_counts={
        "subjects": 149,  # Verified from scripts/validate_isles24_download.py:30
        "ncct": 149,      # All subjects have NCCT
        "cta": 149,       # All subjects have CTA
        "ctp": 140,       # ~94% have CTP
        "tmax": 140,
        "mtt": 140,
        "cbf": 140,
        "cbv": 140,
        "dwi": 149,
        "adc": 149,
        "lesion_mask": 149,
        "lvo_mask": 100,  # ~67% have LVO mask
        "cow_mask": 100,  # ~67% have CoW segmentation
    },
    required_files=[
        "clinical_data-description.xlsx",  # ISLES24 uses xlsx, not participants.tsv
    ],
    modality_patterns={
        "ncct": "*_ncct.nii.gz",
        "cta": "*_cta.nii.gz",
        "dwi": "*_dwi.nii.gz",
        "lesion": "*_lesion-msk.nii.gz",
        # ... add all ISLES24 modalities
    },
)

def validate_isles24_download(bids_root: Path, **kwargs) -> ValidationResult:
    """Convenience wrapper for ISLES24 validation."""
    from .base import validate_dataset
    return validate_dataset(bids_root, ISLES24_VALIDATION_CONFIG, **kwargs)
```

---

## Implementation Checklist

### 1. Create `validation/` Directory

```bash
mkdir -p src/bids_hub/validation
touch src/bids_hub/validation/__init__.py
```

### 2. Extract Generic Framework

Move reusable code from `validation.py` to `validation/base.py`:
- `ValidationCheck` dataclass
- `ValidationResult` dataclass
- `check_zero_byte_files()` - **NEW: From scripts/validate_isles24_download.py (HIGH PRIORITY)**
- `_check_required_files()`
- `_check_subject_count()`
- `_check_participants_tsv()`
- `_count_sessions_with_modality()`
- `_check_series_count()`
- `_check_nifti_integrity()` - nibabel-based spot check (slower, but more thorough)
- `_check_bids_validator()`

**Note**: `check_zero_byte_files()` is a fast pre-check that should run BEFORE the slower nibabel integrity check. Source: `scripts/validate_isles24_download.py:99-110`.

Parameterize with `DatasetValidationConfig` instead of hardcoded values.

### 3. Create ARC-Specific Config

Move `EXPECTED_COUNTS` and `REQUIRED_BIDS_FILES` to `validation/arc.py`.

### 4. Create ISLES24-Specific Config

Extract validation logic from `scripts/validate_isles24_download.py` into `validation/isles24.py`.

### 5. Update `validation/__init__.py`

```python
from .base import (
    ValidationCheck,
    ValidationResult,
    DatasetValidationConfig,
    validate_dataset,
    check_zero_byte_files,  # Exported for direct use
)
from .arc import ARC_VALIDATION_CONFIG, validate_arc_download
from .isles24 import ISLES24_VALIDATION_CONFIG, validate_isles24_download

__all__ = [
    "ValidationCheck",
    "ValidationResult",
    "DatasetValidationConfig",
    "validate_dataset",
    "check_zero_byte_files",
    "ARC_VALIDATION_CONFIG",
    "validate_arc_download",
    "ISLES24_VALIDATION_CONFIG",
    "validate_isles24_download",
]
```

### 6. Update Main `__init__.py`

```python
from .validation import (
    ValidationResult,
    validate_arc_download,
    validate_isles24_download,
)
```

### 7. Update CLI

```python
# cli.py
@app.command()
def validate(
    bids_root: Path,
    dataset: str = typer.Option("arc", help="Dataset type: arc, isles24"),
    ...
):
    if dataset == "arc":
        result = validate_arc_download(bids_root, ...)
    elif dataset == "isles24":
        result = validate_isles24_download(bids_root, ...)
```

### 8. Delete Standalone Scripts

After validation module works, delete:
- `scripts/validate_download.py`
- `scripts/validate_hf_download.py`
- `scripts/validate_isles24_download.py`
- `scripts/validate_isles24_hf_upload.py`

### 9. Update Tests

- `test_validation.py` → test generic framework
- Add `test_validation_arc.py` for ARC-specific tests
- Add `test_validation_isles24.py` for ISLES24-specific tests

---

## Verification

```bash
# CLI validation should work for both datasets
bids-hub validate data/arc --dataset arc
bids-hub validate data/isles24 --dataset isles24

# Python API should work
from bids_hub.validation import validate_arc_download, validate_isles24_download

# Tests should pass
uv run pytest tests/test_validation*.py -v
```

---

## Future Extensions

With this framework, adding new datasets becomes trivial:

```python
# validation/atlas.py
ATLAS_VALIDATION_CONFIG = DatasetValidationConfig(
    name="atlas",
    expected_counts={"subjects": 955, ...},
    ...
)
```
