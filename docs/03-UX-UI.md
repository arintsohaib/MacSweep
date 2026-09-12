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

### Cleanup modes (v0.4.0)

- Overview offers two scan intents: **Basic Clean** (caches, logs, plus informational leftovers and large files) and **Advanced Clean** (all categories).
- Basic pre-selects only regenerable cache/log items; Advanced pre-selects nothing.
- Advanced results show a caution banner, and the review sheet warns when developer caches, web storage, or saved state are selected.
- The Overview and every findings pane expose **Select All / Deselect All**, which only ever select cleanable, non-excluded items.
- Default settings enable only the Basic profile, so a new user never scans or cleans everything by accident.

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

### Layout system (v0.5.0)

- A shared `Theme` (corner radius, spacing, max content width) and a `card()` modifier group related content on a subtle `controlBackgroundColor` surface with a hairline border.
- Overview: hero header, Basic/Advanced mode cards, stat cards (Reclaimable / Findings / Selected), a category breakdown with per-category icons and bars, and tinted notice cards.
- Findings: category icon tile, icon-bearing risk badge, "Review only" / "Excluded" tags, and a right-aligned monospaced size.
- Settings: category rows show an icon, an Info/Review risk tag, a summary and a cleanup note. Every scan category has a `systemImage` and settings metadata.

## UI decisions (Phase 6)

- Single `@Observable` `AppState` on the MainActor holds scan phase, result, selection, and exclusions; the scan engine runs off the main actor and reports progress back via a MainActor-bound `ProgressReporter`.
- Selection is per stable item ID. Defaults come from the finding's `selectedByDefault`; excluded items cannot be selected.
- The cleanup confirmation button is explicitly disabled until the cleanup engine (Phase 7) exists; the review sheet states that no items will be moved. No fake cleanup.
- History and Settings panes show honest placeholders until Phase 9.
- UI flows are covered by `AppState` unit tests; a dedicated UI test target is added in Phase 10.
