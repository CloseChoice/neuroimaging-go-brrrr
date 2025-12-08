# Phase 3: CLI Structure Normalization

> **Status**: Spec
> **Dependency**: Phase 1 (Package Renaming)
> **Effort**: Low-Medium

---

## Problem

Current CLI has inconsistent structure:

```bash
# ARC commands (top-level - legacy)
arc-bids build ...
arc-bids validate ...
arc-bids info

# ISLES24 commands (subcommand group)
arc-bids isles24 build ...
```

**Why is ARC special?** It shouldn't be. This is just legacy from when the package only supported ARC.

---

## Proposed Solution

### Option A: All Datasets as Subcommands (Recommended)

```bash
bids-hub arc build /path/to/ds004884 --hf-repo user/arc-dataset
bids-hub arc validate /path/to/ds004884
bids-hub arc info

bids-hub isles24 build /path/to/isles24 --hf-repo user/isles24-dataset
bids-hub isles24 validate /path/to/isles24
bids-hub isles24 info
```

**Pros**:
- Consistent structure
- Easy to add new datasets
- Clear namespace separation

### Option B: Unified Commands with `--dataset` Flag

```bash
bids-hub build /path/to/data --dataset arc --hf-repo user/dataset
bids-hub validate /path/to/data --dataset arc
bids-hub info --dataset arc
```

**Pros**:
- Fewer commands to remember
- Single entry point

**Cons**:
- Requires `--dataset` flag every time
- Less tab-completion friendly

---

## Recommendation

**Use Option A (subcommand groups)** for better UX and extensibility.

---

## Implementation

### New CLI Structure

```python
# cli.py
import typer

app = typer.Typer(
    name="bids-hub",
    help="Upload BIDS neuroimaging datasets to HuggingFace Hub.",
    add_completion=False,
)

# --- ARC Subcommand Group ---
arc_app = typer.Typer(help="Commands for the ARC (Aphasia Recovery Cohort) dataset.")
app.add_typer(arc_app, name="arc")

@arc_app.command("build")
def arc_build(
    bids_root: Path,
    hf_repo: str = typer.Option("hugging-science/arc-aphasia-bids"),
    dry_run: bool = typer.Option(True),
) -> None:
    """Build and push ARC dataset to HuggingFace Hub."""
    ...

@arc_app.command("validate")
def arc_validate(bids_root: Path, ...) -> None:
    """Validate ARC dataset download."""
    ...

@arc_app.command("info")
def arc_info() -> None:
    """Show ARC dataset information."""
    ...

# --- ISLES24 Subcommand Group ---
isles24_app = typer.Typer(help="Commands for the ISLES24 stroke dataset.")
app.add_typer(isles24_app, name="isles24")

@isles24_app.command("build")
def isles24_build(bids_root: Path, ...) -> None:
    """Build and push ISLES24 dataset to HuggingFace Hub."""
    ...

@isles24_app.command("validate")
def isles24_validate(bids_root: Path, ...) -> None:
    """Validate ISLES24 dataset download."""
    ...

@isles24_app.command("info")
def isles24_info() -> None:
    """Show ISLES24 dataset information."""
    ...

# --- Global Commands ---
@app.command("list")
def list_datasets() -> None:
    """List all supported datasets."""
    typer.echo("Supported datasets:")
    typer.echo("  arc     - Aphasia Recovery Cohort (OpenNeuro ds004884)")
    typer.echo("  isles24 - Ischemic Stroke Lesion Segmentation 2024 (Zenodo)")
```

---

## Implementation Checklist

### 1. Restructure `cli.py`

- Create `arc_app` subcommand group
- Move existing `build`, `validate`, `info` to `arc_app`
- Keep `isles24_app` (already exists)
- Add `list` command to show supported datasets

### 2. Remove Top-Level Legacy Commands

Delete:
```python
@app.command()
def build(...):  # Remove this
    ...

@app.command()
def validate(...):  # Remove this
    ...

@app.command()
def info():  # Remove this
    ...
```

### 3. Update Help Text

```python
arc_app = typer.Typer(
    help="ARC (Aphasia Recovery Cohort) dataset commands.\n\n"
         "Source: OpenNeuro ds004884\n"
         "License: CC0 (Public Domain)"
)
```

### 4. Update README and Docs

Update all CLI examples:

```bash
# Old
arc-bids build /path/to/arc

# New
bids-hub arc build /path/to/arc
```

### 5. Add Backward Compatibility (Optional)

If users depend on old CLI:

```python
# cli.py - Deprecated aliases
@app.command("build", hidden=True)
def build_legacy(bids_root: Path, ...):
    """DEPRECATED: Use 'bids-hub arc build' instead."""
    typer.echo("Warning: 'build' is deprecated. Use 'bids-hub arc build'.", err=True)
    arc_build(bids_root, ...)
```

---

## Verification

```bash
# Help should show subcommands
bids-hub --help
# Output: Commands: arc, isles24, list

# ARC commands
bids-hub arc --help
bids-hub arc build --help
bids-hub arc validate --help
bids-hub arc info

# ISLES24 commands
bids-hub isles24 --help
bids-hub isles24 build --help

# List supported datasets
bids-hub list
```

---

## Future Extensions

Adding new datasets:

```python
# New dataset
atlas_app = typer.Typer(help="ATLAS v2.0 stroke dataset commands.")
app.add_typer(atlas_app, name="atlas")

@atlas_app.command("build")
def atlas_build(...): ...
```

Users get:
```bash
bids-hub atlas build /path/to/atlas
```
