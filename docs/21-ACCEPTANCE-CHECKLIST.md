# 21 — Release Acceptance Checklist

## Product
- [x] Native macOS app launches.
- [x] Scan is cancellable.
- [x] Findings are understandable.
- [x] User can inspect every cleanup item.
- [x] User explicitly approves cleanup.
- [x] Cleanup is reversible through Trash where supported.

## Safety
- [x] Scanner is read-only.
- [x] Cleanup revalidates state.
- [x] Protected paths are enforced.
- [x] Symlink escape tests pass.
- [x] No shell-based recursive deletion.
- [x] No AI dependency for cleanup decisions.
- [x] Permission failures are handled.

## Application leftovers
- [x] Installed app data is preserved.
- [x] Uninstalled app containers can be detected.
- [x] Group/shared data is conservative.
- [x] Helpers/system components are not blindly removed.

## Developer
- [x] Developer caches are review-only by default.
- [x] Rebuild/download consequences are shown.
- [x] Repositories and credentials are protected.
- [x] Docker data is protected.

## Quality
- [x] Unit tests pass.
- [x] Integration tests pass.
- [x] UI tests pass where implemented.
- [x] Release build passes.
- [x] Documentation matches behavior.
