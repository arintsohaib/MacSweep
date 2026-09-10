# 08 — Developer Cleanup

Developer cleanup is intentionally conservative.

## Categories

Potential findings:
- Homebrew cache/downloads;
- npm/pnpm/yarn caches;
- pip cache;
- Swift Package Manager caches;
- Xcode DerivedData;
- simulator data;
- Gradle caches;
- Maven caches;
- Playwright browser downloads;
- Docker data.

## Default policy

Most developer findings are REVIEW, not LOW.

Never delete:
- repositories;
- source code;
- SSH configuration;
- signing certificates;
- keychains;
- active toolchains;
- installed package managers;
- Docker VM/storage automatically.

## Explanations

Every developer cleanup item must explain likely consequences, such as:
- rebuild/download required;
- browser binaries may need reinstall;
- build artifacts will regenerate.

## Docker

v1 should detect and report Docker storage conservatively. Do not implement destructive Docker pruning until a dedicated, tested policy exists.

## Implementation decisions (Phase 8)

- `ApplicationCacheScanner` and `LogScanner` discover general caches and logs in `~/Library/Caches` and `~/Library/Logs`. All active caches and logs are classified as `REVIEW` (`selectedByDefault: false`) to require explicit user selection.
- `SavedStateScanner` and `WebStorageScanner` discover window restoration state and WebKit / HTTPStorage state, classified as `REVIEW`.
- `DeveloperScanner` inspects Xcode DerivedData, CoreSimulator caches, Homebrew cache, SPM cache, npm, Yarn, pip, Gradle, and Playwright browsers. All are classified as `REVIEW` with clear consequence statements in the finding reason.
- Docker VM and container storage (`~/Library/Containers/com.docker.docker`) is detected as `PROTECTED` (`cleanupAllowed: false`, `recommendedAction: .reviewOnly`) to prevent loss of containers in v1.
- `LargeFileScanner` inspects `~/Downloads` and `~/Desktop` for regular files exceeding `minLargeFileSize` (default 512 MB), classified as `REVIEW`. Package bundles, directories, and symlinks are excluded.
- Deduplication ensures higher-priority category findings (e.g. uninstalled app containers/caches) take precedence over general cache or large file findings.
