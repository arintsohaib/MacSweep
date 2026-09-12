# 06 — Application Detection

## Objective

Identify installed applications and correlate abandoned application data.

## Application sources

Discover applications through appropriate macOS APIs and standard application locations, including:
- `/Applications` and `/Applications/Utilities`
- `/System/Applications` and `/System/Applications/Utilities`
- `/System/Library/CoreServices` and `/System/Library/CoreServices/Applications`
- `~/Applications`
- LaunchServices resolution (`NSWorkspace.urlForApplication(withBundleIdentifier:)`) and other system-supported discovery mechanisms where appropriate.

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
- `~/Library/WebKit`
- `~/Library/HTTPStorages`
- `~/Library/Saved Application State`
- `~/Library/Logs`
- application-related LaunchAgents

`~/Library/Preferences` is deliberately **not** inspected for cleanup. Preferences are user settings; removing them makes macOS silently reset user configuration (default applications, Dock, Finder, notifications, ...). The path is also permanently protected at cleanup time.

Use Apple's APIs and platform conventions where possible rather than blindly hardcoding paths.

## System ownership

Bundle identifiers owned by macOS (`com.apple.*` and core-OS domains such as `org.cups.*`, `com.openssh.*`) and by MacSweep itself are **never** application leftovers, regardless of whether a matching app bundle is found. macOS ships hundreds of background agents, daemons, frameworks, and internal components that have no app bundle; treating them as leftovers destroys system state.

System ownership is enforced in two places:
- at scan time, such candidates are not reported at all;
- at cleanup time, `SystemOwnerRules` rejects any system-owned finding even if it somehow reached the engine.

## Uninstalled detection

A candidate is a leftover only when:
- its name is a valid reverse-DNS bundle identifier;
- that identifier is **not** system-owned (Apple/MacSweep);
- no installed application resolves to that identifier (standard application folders **and** LaunchServices);
- for group containers, the `group.`-stripped owner identifier is also not installed;
- the path is not protected;
- the location is a known application-data location.

Leftover findings are always `review` risk, never pre-selected, and cleanup only ever happens after explicit per-item selection. Folders whose name is not a valid bundle identifier (e.g. `data`, `cache`, `Google`) cannot prove application ownership and are not reported.

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

- Attribution strength drives confidence, not automatic selection: a data folder whose name is a valid bundle identifier is strong attribution; when the owning app is absent the finding is REVIEW and never pre-selected. System-owned identifiers are not reported at all.
- Group containers are always at least REVIEW (shared ownership), even when the owning app is absent. A group container whose `group.`-stripped identifier matches an installed app is treated as active and skipped.
- Launch metadata (`~/Library/LaunchAgents`) for an absent app is always REVIEW (helpers and system components are not auto-removed). System-level launch directories are never scanned.
- All discovered locations for one bundle identifier are merged into a single finding (one row, multiple paths); the finding's risk is the maximum of its paths' risks.
- Renamed applications: bundle-identifier-named data is unaffected by renames (identity is the bundle ID). Name-based folders are not reported, because a non-bundle-ID name cannot prove ownership.
- Symlinked data entries are reported with zero size and are never followed during size calculation; the cleanup engine revalidates them before any move.
- Inaccessible locations produce structured permission diagnostics and never stop the scan.

## System-ownership decisions (v0.2.0)

- Installed-app discovery was widened (CoreServices, Utilities, user Applications) and now also resolves via LaunchServices, so Apple system components are recognised as present rather than "uninstalled".
- A `com.apple.*` / core-OS / MacSweep identifier is never a leftover candidate, independent of app discovery.
- `~/Library/Preferences` is excluded from scanning and permanently protected from cleanup.
- No finding is selected automatically; the user must choose every item.
