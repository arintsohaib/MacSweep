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
