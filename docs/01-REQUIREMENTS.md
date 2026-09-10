# 01 — Requirements

## Functional requirements

### Scan
- Start and cancel scans.
- Show progress.
- Continue safely when individual paths cannot be read.
- Produce deterministic results.
- Never mutate the filesystem.

### Categories
1. Uninstalled application leftovers.
2. Application caches.
3. Application support leftovers.
4. WebKit/HTTP storage leftovers.
5. Logs.
6. Saved application state.
7. LaunchAgent/LaunchDaemon candidates.
8. Developer caches.
9. Large files.
10. Protected/review-only findings.

### Result
Each finding contains:
- stable ID;
- category;
- application association if known;
- paths;
- total size;
- risk level;
- confidence;
- reason;
- detection evidence;
- recommended action;
- whether selected by default;
- whether cleanup is allowed.

### Review
Users can:
- expand a finding;
- inspect paths;
- show an item in Finder;
- change selection;
- exclude an item;
- see safety explanation;
- preview cleanup.

### Cleanup
- Revalidate every selected item immediately before cleanup.
- Ensure the item still matches the scan identity.
- Refuse changed/ambiguous items.
- Prefer Trash.
- Report successes and failures individually.
- Never treat partial failure as total success.

### Settings
- exclusions;
- default selection behavior;
- scan categories;
- confirmation preference where safe;
- appearance;
- log retention;
- developer cleanup policy.

## Quality requirements

- No silent destructive operations.
- No network dependency.
- Responsive UI.
- Accessibility labels and keyboard navigation.
- Localization-ready strings.
