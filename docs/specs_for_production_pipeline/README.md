# Production Pipeline Cleanup Specs

> **Purpose**: Prepare `arc-aphasia-bids` for integration into `neuroimaging-go-brrrr`
> **Status**: Specs Complete, Implementation Pending

---

## Overview

Before integrating the production pipeline into the collaborative `neuroimaging-go-brrrr` repo, we need to clean up the `arc-aphasia-bids` codebase to:

1. Fix naming (it's not ARC-only anymore)
2. Separate concerns properly
3. Make it truly multi-dataset ready

---

## Phase Specs

| Phase | Document | Status | Effort |
|-------|----------|--------|--------|
| 0 | [Current State Assessment](./00-current-state-assessment.md) | Reference | - |
| 1 | [Package Renaming](./01-package-renaming.md) | Spec | Medium |
| 2 | [Validation Framework](./02-validation-framework.md) | Spec | Medium-High |
| 3 | [CLI Normalization](./03-cli-normalization.md) | Spec | Low-Medium |
| 4 | [Export Cleanup](./04-export-cleanup.md) | Spec | Low |

---

## Execution Order

**Recommended order**:

```
Phase 1 (Rename) → Phase 3 (CLI) → Phase 2 (Validation) → Phase 4 (Exports)
```

**Rationale**:
- Phase 1 is foundational (all imports change)
- Phase 3 is low effort and improves UX immediately
- Phase 2 is the most complex but can be done incrementally
- Phase 4 is cleanup after other phases

**Alternative** (if time-constrained):
- Just do Phase 1 + Phase 4 for minimal cleanup
- Leave Phase 2 + Phase 3 for later

---

## Key Decisions Made

### 1. Package Name: `bids-hub`

Clear, generic, reflects multi-dataset purpose.

### 2. CLI Structure: Subcommand Groups

```bash
bids-hub arc build ...
bids-hub isles24 build ...
```

Not `--dataset` flags.

### 3. Validation: Config-Driven Framework

Dataset-specific validation configs, generic validation runner.

---

## What's NOT Changing

These things are **good** and should be preserved:

1. **`core.py`** - Generic BIDS→HF engine (keep as-is)
2. **Dataset modules** (`arc.py`, `isles24.py`) - Clean separation
3. **Test structure** - Synthetic fixtures pattern
4. **Sharded upload logic** - Workaround for HF upstream bug

---

## After Cleanup: Integration

Once cleanup is complete, the clean `bids-hub` package can be integrated into `neuroimaging-go-brrrr` following the [Integration Spec](../INTEGRATION_SPEC.md).

---

## Files in This Directory

```
docs/specs_for_production_pipeline/
├── README.md                       # This file
├── 00-current-state-assessment.md  # What exists today
├── 01-package-renaming.md          # arc-bids → bids-hub
├── 02-validation-framework.md      # Generic validation
├── 03-cli-normalization.md         # Consistent CLI structure
└── 04-export-cleanup.md            # __init__.py + scripts
```
