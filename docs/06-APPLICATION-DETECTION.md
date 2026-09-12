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
- no installed application owns it — checked by exact match, app-extension prefix (`<app>.<extension>`), and team / app-group prefixes (`group.`, `groups.`, `<TeamID>.`) resolved back to the owner — across the standard application folders **and** LaunchServices;
- the path is not protected.

Only two locations are inspected: sandbox containers (`~/Library/Containers`) and application-support folders (`~/Library/Application Support`). Group Containers, LaunchAgents, Preferences, Caches, Logs, WebKit, HTTPStorages and Saved Application State are never scanned by this rule: they are shared, system-managed, or covered by dedicated scanners, and their folder names cannot reliably prove that an application is gone.

Leftover findings are **informational only** — `review` risk, never pre-selected, and `cleanupAllowed = false`. Application data may still be shared with helpers or services, and macOS manages sandbox containers (they carry `com.apple.containermanager.*` metadata and cannot be moved without Full Disk Access), so MacSweep does not remove them automatically.

Folders whose name is not a valid bundle identifier (e.g. `data`, `cache`, `Google`) cannot prove application ownership and are not reported.

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

- Attribution strength drives confidence, not automatic selection: a data folder whose name is a valid bundle identifier is strong attribution; when the owning app is absent the finding is REVIEW, never pre-selected, and never cleanable. System-owned identifiers are not reported at all.
- Group containers are **not scanned** by this rule. Their names mix team prefixes, `group.`/`groups.` prefixes, and non-app group identifiers, so ownership cannot be proven and removal breaks installed applications.
- Launch metadata (`~/Library/LaunchAgents`) is **not scanned** by this rule: updater/helper agents for installed applications are indistinguishable from abandoned ones.
- All discovered locations for one bundle identifier are merged into a single finding (one row, multiple paths), always at REVIEW.
- Renamed applications: bundle-identifier-named data is unaffected by renames (identity is the bundle ID). Name-based folders are not reported, because a non-bundle-ID name cannot prove ownership.
- Symlinked data entries are reported with zero size and are never followed during size calculation.
- Inaccessible locations produce structured permission diagnostics and never stop the scan.

## System-ownership decisions (v0.2.0)

- Installed-app discovery was widened (CoreServices, Utilities, user Applications) and now also resolves via LaunchServices, so Apple system components are recognised as present rather than "uninstalled".
- A `com.apple.*` / core-OS / MacSweep identifier is never a leftover candidate, independent of app discovery.
- `~/Library/Preferences` is excluded from scanning and permanently protected from cleanup.
- No finding is selected automatically; the user must choose every item.

## Leftover-scope decisions (v0.2.1)

- The remnants rule is limited to `~/Library/Containers` and `~/Library/Application Support`.
- App-extension identifiers (`net.whatsapp.WhatsApp.Intents`), team-prefixed app groups (`UBF8T346G9.com.microsoft.teams`), `group.`/`groups.` app groups, and `<TeamID>.groups.com.apple.*` are resolved to their owning app; if the owner is installed, they are not reported.
- Leftovers are informational only (`cleanupAllowed = false`); they are never offered for one-click cleanup.
- Caches, logs, saved state and web-storage scanners skip system-owned identifiers so Apple data is never offered as reclaimable.
- Rationale: folder-name heuristics cannot prove that shared application data is abandoned, and macOS protects sandbox containers. The safe default is to surface information, not to delete.
