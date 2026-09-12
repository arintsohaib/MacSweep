# 04 — Safety Model

## Principle

Safety is based on evidence, not file size.

## Risk levels

### LOW
Strong evidence of abandoned, application-owned data:
- application is not installed;
- ownership is strongly attributable;
- path is a known application-data location;
- no conflicting owner/reference exists.

Default: selectable.

### REVIEW
Potentially removable but with ambiguity:
- shared containers;
- developer caches;
- logs with uncertain ownership;
- old launch metadata;
- data with multiple plausible consumers.

Default: not selected.

### PROTECTED
Do not offer normal cleanup:
- macOS system paths;
- user documents;
- source repositories;
- SSH/key material;
- keychains;
- shell configuration;
- unknown files;
- active application data;
- critical developer environments;
- Docker VM/storage;
- package-manager installations;
- anything requiring bypassing security.

Large-file findings in personal folders (`~/Downloads`, `~/Desktop`) are user documents / unknown files by definition, so they are always review-only: the app surfaces them with full details but never offers a one-click move, and cleanup revalidation rejects them as protected even if forced.

## Protected path strategy

Use canonicalized URLs/paths and ancestor checks. Protection must survive symlinks and path normalization.

Never rely only on string-prefix checks.

## System ownership

Absence of an installed app is not evidence that data is abandoned. macOS ships hundreds of background agents, daemons, frameworks, and internal components that have no application bundle, and their user-library data (default-app associations, Finder/Dock state, notifications, sharing, message state, ...) is system configuration. Removing it makes macOS silently reset user settings.

Therefore:

- Bundle identifiers owned by macOS (`com.apple.*`, `org.cups.*`, `com.openssh.*`, ...) and by MacSweep itself are never cleanup candidates, regardless of app discovery.
- `~/Library/Preferences` is never scanned for cleanup and is permanently protected at cleanup time.
- App extensions (`<app>.<extension>`) and app groups (`group.`, `groups.`, `<TeamID>.` prefixes) are resolved back to their owning application; if the owner is installed they are not reported.
- Group containers, launch agents, caches, logs, web storage and saved state are not used to infer that an application is gone. They are shared or system-managed, and macOS protects app containers (`com.apple.containermanager.*`).
- A folder whose name is not a valid reverse-DNS bundle identifier cannot prove application ownership and is not reported as a leftover.
- Installed-app detection must consider all standard application locations **and** LaunchServices, so system components are recognised as present.
- Uninstalled-app leftovers are informational only: `review` risk, never pre-selected, and never cleanable. Nothing is selected or removed automatically.

## Revalidation

Before cleanup:
1. Re-stat/canonicalize.
2. Confirm identity and expected size/metadata.
3. Confirm current classification.
4. Confirm user selection.
5. Abort that item if anything material changed.

## Symlinks

Do not recursively follow symlinks during discovery unless a specific, safe rule requires it. Cleanup must not follow a symlink to an unrelated target.

## Race conditions

Assume filesystem state can change between scan and cleanup. Favor safe failure over guessing.
