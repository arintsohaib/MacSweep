# 15 — Settings

## Sections

### General
- launch behavior;
- appearance;
- confirmation behavior.

### Scan
- enabled categories;
- scan scope;
- exclusions.

### Cleanup
- default selection policy;
- Trash preference;
- developer cleanup caution.

### Advanced
- diagnostics;
- history retention.

## Safety

No setting may disable protected-path enforcement.

No "allow dangerous cleanup" switch in v1.

## Implementation decisions (Phase 9)

- `SettingsView` allows toggling scan categories, selecting minimum large file size (100MB – 5GB), managing excluded paths, and viewing/clearing cleanup history.
- Excluded paths immediately take effect in `AppState` and are passed to `PathExclusions` for all scans.
- Protected-path enforcement is structurally non-configurable: neither settings nor UI controls can disable the safety checks in `ProtectedPathRules` and `CleanupEngine`.

## Scan-category descriptions (v0.3.0)

- Every scan category carries `settingsSummary` (what it scans) and `settingsCleanupNote` (what cleanup means and its risk), rendered under each toggle.
- `ScanCategory.cleanupRisk` distinguishes informational categories (never cleaned: Uninstalled Apps, Large Files, Protected/Review) from review categories (Trash-only after explicit selection).
- Categories without a scan rule in the current build (`applicationSupport`, `launchMetadata`) are shown for transparency but disabled, with a note explaining that no rule exists.
- The Safety Policy section states that informational categories are never moved and lists the permanently protected locations, including `~/Library/Preferences`.

## Cleanup modes and defaults (v0.4.0)

- Default `UserSettings` enables only the Basic profile (`applicationCaches`, `logs`, `uninstalledAppRemnants`, `largeFiles`). Developer caches, web storage and saved state are opt-in via Advanced Clean or Settings.
- Settings written by older builds (version 1, every category enabled) are migrated to the Basic profile on first load and persisted as version 2, so upgrading users also get the safer default. Users can re-enable categories in Settings or by choosing Advanced Clean.
- `CleanupMode` defines the scan profile and the categories Basic may pre-select (regenerable only: caches and logs).
- Choosing a mode on the Overview updates `enabledCategories`, so Settings always reflects the current profile.
- Advanced Clean never pre-selects; users select explicitly, with Select All selecting only cleanable, non-excluded items.
