# MacSweep Task Board

The coding agent should update this file as work progresses.

## Phase 0
- [x] Repository/Xcode reconnaissance
- [x] Build baseline
- [x] Test baseline

## Phase 1
- [x] Domain models
- [x] Domain tests

## Phase 2
- [x] Filesystem abstraction
- [x] Application registry abstraction
- [x] Trash abstraction
- [x] Test doubles

## Phase 3
- [x] Scan engine
- [x] Cancellation
- [x] Progress
- [x] Deduplication
- [x] Exclusions

## Phase 4
- [x] Application discovery
- [x] Bundle identity

## Phase 5
- [x] Uninstalled app rules
- [x] Containers
- [x] Group containers
- [x] Application Support
- [x] Caches
- [x] WebKit/HTTP storage
- [x] Logs
- [x] Saved state
- [x] Launch metadata review

## Phase 6
- [x] Sidebar
- [x] Dashboard
- [x] Results
- [x] Details
- [x] Review

## Phase 7
- [x] Revalidation
- [x] Protected-path enforcement
- [x] Trash cleanup
- [x] Cleanup report

## Phase 8
- [x] Cache scanner
- [x] Log scanner
- [x] Developer scanner
- [x] Large-file scanner

## Phase 9
- [x] Settings
- [x] Exclusions
- [x] History

## Phase 10
- [x] Security audit
- [x] Performance tests
- [x] Race/symlink tests

## Phase 11
- [x] Release build
- [x] Signing preparation
- [x] Notarization preparation
- [x] DMG
- [x] Documentation

## Final
- [x] Full test suite
- [x] Safety review
- [x] No secrets
- [x] No unsafe deletion paths
- [x] Final report

## Iconography (user-provided icons)
- [x] Asset catalog: `MacSweep/Assets.xcassets` (AppIcon from `sweep.png` at all macOS sizes; `Sweep`, `SweepBrush`, `MacStudio`, `MacStudioOutline` image sets)
- [x] App icon wired via `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
- [x] Overview first-run hero ("Ready to Sweep") uses the `Sweep` image
- [x] "Nothing found" states (Overview, Results) use the `SweepBrush` image
- [x] Results "No scan yet" / "Scanning…" states use the `MacStudio` / `MacStudioOutline` images
- [x] Debug + Release builds pass; 119 tests pass

## Interface & calculation verification (2026-09-11)
- [x] Audited all UI action paths (scan/cancel, select, exclude, review sheet, cleanup, history, settings)
- [x] Audited all size calculations (reclaimable total, breakdown, selection, history, dedup)
- [x] Fixed: partial-failure cleanup results now report the bytes actually moved; `totalMovedSize` counts them (history stats were undercounted)
- [x] Fixed: Overview "Reclaimable Storage" now reflects remaining items after cleanup (was stale scan-time total)
- [x] Fixed: large-file findings in ~/Downloads and ~/Desktop are now review-only (were offered as "Move to Trash" but always rejected by protected-path revalidation, contradicting the safety model's "unknown files" rule)
- [x] Fixed: protection gap — a finding that is an ancestor of a protected location (e.g. `Application Support/Google` above the protected `.../Google/Chrome`) could be moved to Trash and would have removed the protected content with it. `ProtectedPathRules.isProtectedOrContainsProtected` + remnants scanner now treat such locations as blocked; unattributed blocked folders are not reported, attributed items containing them become review-only
- [x] Removed unused-variable warning in UninstalledAppRemnantsScanner
- [x] Added `RealFileSystemTests` (exact size totals, symlink exclusion, stat kinds on the real filesystem)
- [x] Added opt-in `RealScanInvariantsTests`: full scan of the real home directory asserts no overlapping findings, no cleanable finding on/above protected paths, reclaimable total = sum of cleanable items (ran clean on this machine; enable with `touch /tmp/macsweep-real-scan-test`)
- [x] App relaunched with final binary: stable, no runtime errors in system log
- [x] Full suite green: 130 tests, Debug + Release builds pass
- Known limitation: remnants nested inside an unattributed parent folder (e.g. `Application Support/Google/Chrome`) are not surfaced as findings; the protected content is never touched, only visibility is reduced
