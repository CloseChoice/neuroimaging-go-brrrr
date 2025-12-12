# BUG-001: Phantom Submodule Breaks pip install from Git

**Status**: Closed (v0.2.1)
**Severity**: Critical (blocks primary use case)
**Introduced**: Commit `ef99e83` ("add README and add the arc-aphasia-bids tool")
**Discovered**: 2025-12-11

## Problem Statement

Installing this package from git fails with:

```text
fatal: No url found for submodule path 'tools/arc-aphasia-bids' in .gitmodules
```

This blocks `pip install git+https://github.com/...` which is the primary distribution method for downstream consumers (e.g., arc-meshchop).

## Root Cause Analysis

### What Happened

1. **Historical context**: This repository was originally part of or related to a project called "arc-aphasia-bids"
2. **Commit `ef99e83`** added `tools/arc-aphasia-bids` as a git submodule
3. **At some point**, the `.gitmodules` entry for `arc-aphasia-bids` was removed
4. **Critical error**: The gitlink (submodule reference) in the git tree was NOT removed

### Current State

**`.gitmodules` defines only ONE submodule:**
```ini
[submodule "tools/bids-neuroimaging-space"]
    path = tools/bids-neuroimaging-space
    url = https://huggingface.co/spaces/TobiasPitters/bids-neuroimaging
```

**But `git ls-tree HEAD tools/` shows TWO gitlinks:**
```text
160000 commit f6e7e80803e19cd8db517c081486f4eb295fd8d4  tools/arc-aphasia-bids
160000 commit 3b8d8f6d5480f789f532f3a5d356970d1c45ccc4  tools/bids-neuroimaging-space
```

The mode `160000` indicates a gitlink (submodule reference). Git sees `arc-aphasia-bids` as a submodule but cannot find its URL in `.gitmodules`, causing the fatal error.

### Why This Is a "Phantom Submodule"

- The gitlink exists in the git tree (tracked by git)
- The `.gitmodules` entry does NOT exist
- The local directory is empty (only `.` and `..`)
- Git cannot clone it because it has no URL
- This is a corrupted repository state

## Impact

- **Blocks pip install from git**: Primary distribution method unusable
- **Blocks git clone --recurse-submodules**: Standard clone workflow fails
- **Affects downstream consumers**: arc-meshchop cannot depend on this package
- **Tag v0.2.0 is broken**: The existing tag has this bug

## Solution

### Fix Steps

```bash
# 1. Remove the orphaned gitlink from git's index
git rm --cached tools/arc-aphasia-bids

# 2. Remove the empty local directory
rm -rf tools/arc-aphasia-bids

# 3. Commit the fix
git commit -m "fix: remove phantom submodule tools/arc-aphasia-bids

The submodule gitlink existed in git tree but had no .gitmodules entry,
causing 'fatal: No url found for submodule path' during pip install.

Root cause: .gitmodules entry was removed but gitlink was not.
Fix: Remove orphaned gitlink to restore valid repository state."

# 4. Tag the fix
git tag -a v0.2.1 -m "Release v0.2.1 - Fix phantom submodule blocking pip install"

# 5. Push to origin
git push origin main --tags
```

### Verification

After fix, confirm:
```bash
# Should show only bids-neuroimaging-space
git ls-tree HEAD tools/

# Should succeed
pip install git+https://github.com/The-Obstacle-Is-The-Way/neuroimaging-go-brrrr.git@v0.2.1
```

## Prevention

To prevent this in the future:

1. **Never manually edit `.gitmodules`** - always use `git submodule deinit` and `git rm`
2. **Submodule removal checklist**:
   - `git submodule deinit <path>` (remove from .git/config)
   - `git rm <path>` (remove gitlink AND .gitmodules entry)
   - `rm -rf .git/modules/<path>` (remove cached module)
3. **Test pip install from git** before tagging releases

## References

- [Git submodule internals](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Mode 160000 = gitlink](https://git-scm.com/docs/git-ls-tree)
