# Integration Specification: Unifying Production & Consumption Pipelines

**Status**: Draft
**Author**: Claude (with human direction)
**Date**: 2025-12-08

---

## Executive Summary

This document specifies how to integrate the **production pipeline** from `arc-aphasia-bids` into `neuroimaging-go-brrrr` to create a unified neuroimaging-to-HuggingFace toolkit with both:

1. **Production Pipeline**: BIDS → HuggingFace Hub (upload)
2. **Consumption Pipeline**: HuggingFace Hub → Research (download/stream/visualize)

---

## Current State Analysis

### Repository: `neuroimaging-go-brrrr` (This Repo)

| Component | Status | Lines of Code |
|-----------|--------|---------------|
| Production Pipeline | Example script only | 41 lines |
| Consumption Pipeline | Jupyter notebooks | ~200 lines |
| Core Library | Empty skeleton | 0 lines |
| Visualization | NiiVue integration | Working |
| Dev Tooling | Complete | ruff, mypy, pre-commit |

**What it has:**
- Coordination hub structure
- Consumption examples (streaming + NiiVue visualization)
- Good dev tooling
- Documentation/roadmap

**What it lacks:**
- Actual production pipeline
- Validation
- CLI

---

### Repository: `arc-aphasia-bids` (External)

| Component | Status | Lines of Code |
|-----------|--------|---------------|
| Core Library (`core.py`) | Production-ready | ~200 lines |
| ARC Dataset (`arc.py`) | Complete | ~250 lines |
| ISLES'24 Dataset (`isles24.py`) | Complete | ~250 lines |
| Validation (`validation.py`) | Comprehensive | ~300 lines |
| CLI (`cli.py`) | Typer-based | ~150 lines |
| **Total** | | **~1,150 lines** |

**What it has:**
- Generic BIDS → HF conversion core
- Memory-efficient sharded uploads (handles 300GB datasets)
- Workarounds for upstream HuggingFace bugs
- Comprehensive validation
- Two working dataset implementations
- CLI with dry-run support

**What it lacks:**
- Consumption pipeline
- Visualization
- Generic naming (package is `arc_bids`, repo is `arc-aphasia-bids`)

---

## The Naming Problem

The current `arc-aphasia-bids` repo has outgrown its name:

```
arc_bids/           # Name suggests ARC-only
├── core.py         # But this is GENERIC
├── arc.py          # ARC-specific ✓
├── isles24.py      # ISLES-specific (not ARC!)
├── validation.py   # ARC-specific (needs generalization)
└── cli.py          # Supports both datasets
```

As more datasets are added (ATLAS, SOOP, etc.), this naming becomes increasingly confusing.

---

## Proposed Unified Architecture

### Package Structure

```
neuroimaging-go-brrrr/
├── src/
│   └── bids_hub/                   # Package name: bids_hub (clear, specific)
│       │
│       ├── __init__.py
│       │
│       ├── core/                   # Generic utilities
│       │   ├── __init__.py
│       │   ├── builder.py          # DatasetBuilderConfig, build_hf_dataset()
│       │   ├── uploader.py         # push_dataset_to_hub() with sharding
│       │   └── types.py            # Common type definitions
│       │
│       ├── datasets/               # Dataset-specific implementations
│       │   ├── __init__.py
│       │   ├── base.py             # Abstract base class for datasets
│       │   ├── arc.py              # ARC (Aphasia Recovery Cohort)
│       │   ├── isles24.py          # ISLES'24 (Stroke Lesion Segmentation)
│       │   └── atlas.py            # Future: ATLAS v2.0
│       │
│       ├── validation/             # Generalized validation framework
│       │   ├── __init__.py
│       │   ├── base.py             # ValidationResult, ValidationCheck
│       │   ├── bids.py             # Generic BIDS validation
│       │   └── arc.py              # ARC-specific expected counts
│       │
│       ├── consumption/            # NEW: Download/streaming utilities
│       │   ├── __init__.py
│       │   ├── loader.py           # Wrappers around load_dataset()
│       │   └── visualization.py    # NiiVue integration helpers
│       │
│       └── cli.py                  # Unified Typer CLI
│
├── scripts/
│   └── visualization/              # Keep notebooks for examples
│       ├── ArcAphasiaBids.ipynb
│       └── ArcAphasiaBidsLoadData.ipynb
│
├── tests/
│   ├── test_core.py
│   ├── test_datasets/
│   │   ├── test_arc.py
│   │   └── test_isles24.py
│   └── test_validation.py
│
└── docs/
    ├── INTEGRATION_SPEC.md         # This document
    └── brainstorming/
```

### CLI Design

```bash
# Production: Upload datasets
bids-hub arc build /path/to/ds004884 --hf-repo hugging-science/arc-aphasia-bids
bids-hub isles24 build /path/to/isles24 --hf-repo hugging-science/isles24-stroke

# Validation: Check downloads before upload
bids-hub arc validate /path/to/ds004884
bids-hub isles24 validate /path/to/isles24

# Info: Dataset details
bids-hub arc info
bids-hub list
```

---

## Integration Steps

### Phase 1: Core Migration

1. **Rename package**: `arc_bids` → `bids_hub`
2. **Create core module structure**:
   - Move `core.py` → `bids_hub/core/builder.py`
   - Extract upload logic → `bids_hub/core/uploader.py`
3. **Create datasets module**:
   - Move `arc.py` → `bids_hub/datasets/arc.py`
   - Move `isles24.py` → `bids_hub/datasets/isles24.py`
   - Create `base.py` with abstract `BIDSDataset` class

### Phase 2: Validation Generalization

1. **Extract generic validation framework**:
   - `ValidationResult`, `ValidationCheck` → `validation/base.py`
   - Generic BIDS checks → `validation/bids.py`
   - **Zero-byte file detection** (fast corruption check) → `validation/base.py`
2. **Keep dataset-specific expected counts**:
   - ARC counts → `validation/arc.py`
   - Add ISLES validation → `validation/isles24.py`

### Phase 3: Consumption Pipeline

1. **Create consumption module**:
   - Wrapper functions for `load_dataset()` with sensible defaults
   - Helper for NiiVue visualization
2. **Extract reusable code from notebooks**

### Phase 4: CLI Unification

1. **Create unified CLI** with subcommand groups:
   - `bids-hub arc build/validate/info`
   - `bids-hub isles24 build/validate/info`
   - `bids-hub list` (show supported datasets)

### Phase 5: Testing & Documentation

1. **Port tests** from arc-aphasia-bids
2. **Add integration tests**
3. **Update README** with unified usage

---

## Key Design Decisions

### 1. Single Package vs. pip install

**Decision**: Single unified package (not `pip install arc-aphasia-bids`)

**Rationale**:
- Researchers want one tool, not a constellation of packages
- Easier to maintain one CI/CD pipeline
- Shared code (core, validation) doesn't need duplication
- Version coordination is automatic

### 2. Dataset Plugin Architecture

**Decision**: Use a simple module-per-dataset approach (not a plugin system)

**Rationale**:
- BIDS datasets are finite and well-known
- Plugin systems add complexity without proportional benefit
- Each dataset module follows the same pattern:
  ```python
  def build_<dataset>_file_table(bids_root: Path) -> pd.DataFrame
  def get_<dataset>_features() -> Features
  def build_and_push_<dataset>(config: DatasetBuilderConfig) -> None
  ```

### 3. Validation Strategy

**Decision**: Generic framework + dataset-specific expected counts

**Rationale**:
- BIDS structure is consistent (same checks apply everywhere)
- But expected file counts differ per dataset
- Tolerance parameter allows for partial downloads

### 4. Memory-Efficient Uploads

**Decision**: Keep the custom sharded upload from arc-aphasia-bids

**Rationale**:
- Neuroimaging datasets are huge (100GB-300GB)
- Standard `push_to_hub()` causes OOM
- Current implementation handles 902 sessions × 300MB = 270GB

---

## Migration Path for arc-aphasia-bids

After integration, the `arc-aphasia-bids` repo should:

1. **Archive** the repository (mark as deprecated)
2. **Update README** to point to `neuroimaging-go-brrrr`
3. **Keep as reference** for the original implementation

The submodule in `tools/arc-aphasia-bids` can be removed since the code will be integrated directly.

---

## Dependencies

```toml
dependencies = [
  "datasets>=3.4.0",
  "hf-xet>=1.0.0",        # REQUIRED: XET storage for optimized HF Hub uploads (300GB+ datasets)
  "huggingface-hub>=0.32.0",
  "nibabel>=5.0.0",
  "pandas>=2.0.0",
  "typer>=0.12.0",
  "openpyxl>=3.1.5",      # ISLES'24 xlsx reading
]

[tool.uv.sources]
# CRITICAL: Pin to specific commit until upstream PR #7896 is merged.
# PyPI stable has embed_table_storage bug causing SIGKILL on Sequence(Nifti()) after ds.shard()
# See UPSTREAM_BUG.md for details.
datasets = { git = "https://github.com/huggingface/datasets.git", rev = "004a5bf4addd9293d6d40f43360c03c8f7e42b28" }
```

**WARNING**: The `datasets` git pin is REQUIRED. Without it, sharded uploads of large NIfTI datasets will crash with SIGKILL.

---

## Open Questions

1. **PyPI publishing**: Should we publish to PyPI after integration?
   - Pro: Easy installation for researchers
   - Con: Maintenance burden, version coordination

2. **HuggingFace Space integration**: The `bids-neuroimaging-space` submodule is for visualization. Should that code also be integrated?

---

## Success Criteria

Integration is complete when:

- [ ] All production code from arc-aphasia-bids is in neuroimaging-go-brrrr
- [ ] CLI works: `bids-hub arc build ...`
- [ ] CLI works: `bids-hub arc validate ...`
- [ ] Consumption helpers work in notebooks
- [ ] All tests pass
- [ ] README documents unified usage
- [ ] arc-aphasia-bids is archived with redirect

---

## Appendix: File-by-File Migration Map

| Source (arc-aphasia-bids) | Destination (neuroimaging-go-brrrr) |
|---------------------------|-------------------------------------|
| `src/arc_bids/core.py` | `src/bids_hub/core/builder.py` + `uploader.py` |
| `src/arc_bids/arc.py` | `src/bids_hub/datasets/arc.py` |
| `src/arc_bids/isles24.py` | `src/bids_hub/datasets/isles24.py` |
| `src/arc_bids/validation.py` | `src/bids_hub/validation/` (split) |
| `src/arc_bids/cli.py` | `src/bids_hub/cli.py` (enhanced) |
| `tests/test_arc.py` | `tests/test_arc.py` (update imports) |
| `tests/test_isles24.py` | `tests/test_isles24.py` (update imports) |
| `tests/test_core_nifti.py` | `tests/test_core_nifti.py` (update imports) |
| `tests/test_validation.py` | `tests/test_validation.py` (update imports) |
| `tests/test_cli_skeleton.py` | `tests/test_cli.py` **(REWRITE for new subcommand structure)** |
| `UPSTREAM_BUG.md` | `docs/UPSTREAM_BUG.md` |
