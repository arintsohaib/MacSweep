# 03 — UX/UI

## Navigation

Sidebar:
- Overview
- Uninstalled Apps
- Caches
- Logs
- Developer
- Large Files
- Protected / Review
- History
- Settings

## Overview

Show:
- last scan;
- reclaimable total;
- category breakdown;
- scan button;
- review selected cleanup button;
- warnings if permissions limit scan coverage.

## Finding row

Display:
- checkbox;
- icon/category;
- name;
- size;
- risk badge;
- concise reason;
- disclosure for details.

## Detail

Show:
- why detected;
- installed/uninstalled state;
- bundle identifier;
- paths;
- evidence;
- risk;
- confidence;
- last modified information when useful;
- actions: Show in Finder, Exclude.

## Cleanup review

Before execution:
- total selected size;
- item count;
- exact affected locations;
- risk summary;
- what Trash means;
- confirmation button.

Button text should describe the action, e.g. `Move 12 Items to Trash`.

## Empty/error states

Never show a blank screen without explanation. Distinguish:
- nothing found;
- scan cancelled;
- permission denied;
- scan error;
- cleanup partial failure.

## Visual direction

Native macOS, restrained, clean, information-dense but readable. Avoid fake "optimization" meters and misleading green/red health scores.

Custom artwork lives in `MacSweep/Assets.xcassets` (user-provided icons, no network or external services involved):
- `AppIcon` — broom illustration (`sweep.png`), all standard macOS sizes.
- `Sweep` — first-run hero on the Overview pane.
- `SweepBrush` — "Nothing found" empty states (Overview and result panes).
- `MacStudio` / `MacStudioOutline` — "No scan yet" and "Scanning…" states in result panes.

SF Symbols remain the default for all in-list and chrome icons; custom images are reserved for empty states and app iconography.

## UI decisions (Phase 6)

- Single `@Observable` `AppState` on the MainActor holds scan phase, result, selection, and exclusions; the scan engine runs off the main actor and reports progress back via a MainActor-bound `ProgressReporter`.
- Selection is per stable item ID. Defaults come from the finding's `selectedByDefault`; excluded items cannot be selected.
- The cleanup confirmation button is explicitly disabled until the cleanup engine (Phase 7) exists; the review sheet states that no items will be moved. No fake cleanup.
- History and Settings panes show honest placeholders until Phase 9.
- UI flows are covered by `AppState` unit tests; a dedicated UI test target is added in Phase 10.
