# 06 — Application Detection

## Objective

Identify installed applications and correlate abandoned application data.

## Application sources

Discover applications through appropriate macOS APIs and standard application locations, including:
- `/Applications`
- `~/Applications`
- other system-supported application discovery mechanisms where appropriate.

Do not assume these are the only application locations.

## Application identity

Capture:
- bundle URL;
- bundle identifier;
- display name;
- version;
- executable status where useful.

Prefer bundle identifier as the primary identity.

## Known data locations

Rules may inspect:
- `~/Library/Application Support`
- `~/Library/Caches`
- `~/Library/Containers`
- `~/Library/Group Containers`
- `~/Library/Preferences`
- `~/Library/WebKit`
- `~/Library/HTTPStorages`
- `~/Library/Saved Application State`
- `~/Library/Logs`
- application-related LaunchAgents

Use Apple's APIs and platform conventions where possible rather than blindly hardcoding paths.

## Uninstalled detection

A candidate is high-confidence only when:
- associated application is absent;
- association is strong;
- no known shared ownership exists;
- path is not protected;
- cleanup is reversible.

## Bundle ID mapping

Build a rule registry that can associate conventional paths with bundle IDs without assuming every application's storage follows one naming scheme.

## Special cases

Explicitly test:
- sandbox containers;
- group containers;
- extensions;
- multiple versions;
- renamed applications;
- apps installed outside `/Applications`;
- shared data;
- apps with external helpers;
- apps with system components.

Do not remove system helpers merely because the main application is absent.

## Uninstalled-leftovers rule decisions (Phase 5)

- Attribution strength drives risk: a data folder whose name is a valid bundle identifier is strong attribution; when the owning app is absent the finding is LOW (default-selected). Folders that only match a display/segment name of no installed app cannot confirm absence, so they are REVIEW, not selected by default.
- Group containers are always at least REVIEW (shared ownership), even when the owning app is absent. A group container whose `group.`-stripped identifier matches an installed app is treated as active and skipped.
- Launch metadata (`~/Library/LaunchAgents`) for an absent app is always REVIEW (helpers and system components are not auto-removed). System-level launch directories are never scanned.
- All discovered locations for one bundle identifier are merged into a single finding (one row, multiple paths); the finding's risk is the maximum of its paths' risks.
- Renamed applications: bundle-identifier-named data is unaffected by renames (identity is the bundle ID); name-based data becomes conservative REVIEW.
- Symlinked data entries are reported with zero size and are never followed during size calculation; the cleanup engine revalidates them before any move.
- Inaccessible locations produce structured permission diagnostics and never stop the scan.
