# 02 — Architecture

## Stack

- Swift
- SwiftUI
- Foundation
- AppKit only where native functionality is needed
- Swift Concurrency
- XCTest / Swift Testing as appropriate for the installed toolchain

Do not introduce third-party dependencies without a concrete requirement.

## Layers

```text
Views
  ↓
AppState / ViewModels
  ↓
Use Cases
  ├── ScanUseCase
  ├── ReviewUseCase
  └── CleanupUseCase
  ↓
Domain
  ├── CleanupItem
  ├── ApplicationInfo
  ├── ScanResult
  ├── Risk
  └── Evidence
  ↓
Infrastructure
  ├── FileSystem
  ├── ApplicationRegistry
  ├── Metadata
  ├── Trash
  └── Persistence
```

## Critical boundary

Scanner interfaces must not expose mutation methods.

Cleanup must not accept arbitrary path strings directly from UI. It accepts validated domain objects created by the scanner/review flow.

## Suggested modules

- App
- Domain
- Scanner
- Rules
- Cleanup
- Persistence
- UI
- Utilities
- Tests

Use protocols at OS boundaries so filesystem and application-registry behavior can be mocked.

## Domain decisions (Phase 1)

- Stable item ID: `CleanupItemID` is a deterministic 128-bit SHA-256 digest (prefix `ms_`) of `category + application identity + sorted canonical path list`. Size and modification metadata intentionally do not affect the ID, so an item keeps its identity across scans while size/mtime change.
- `BundleIdentifier` identity is case-insensitive (equality, hashing, and ID derivation use the lowercased form).
- Display sizes are logical byte counts, formatted in 1024-based units to match Finder.
- `CleanupItem` is created through a throwing initializer that enforces safety invariants: non-empty validated file-URL paths, no duplicate or nested paths (prevents double-counting), no filesystem root, required reason and structured evidence, and risk/selection/action consistency (protected ⇒ never cleanable, never preselected).
- `CleanupReport.summary` never claims full success when any item was rejected, failed, or cancelled.

## Infrastructure decisions (Phase 2)

- OS-boundary protocols (`FileSystem`, `ApplicationRegistry`, `TrashService`) are synchronous and `Sendable`. The scan engine is responsible for executing them off the main actor (detached background tasks), keeping the main actor free of filesystem traversal.
- `FileSystem` is strictly read-only: `stat`, `canonicalizedURL`, `immediateChildren`, `totalSize`, `exists`. All mutation goes through `TrashService`. This makes "scanner is read-only" a type-level guarantee.
- `RealFileSystem.totalSize` computes logical size, never follows symlinks, and symlinks contribute 0 bytes. Inaccessible subtrees are skipped (contribute 0); callers that need to know about skips use the granular operations and emit diagnostics.
- `SystemApplicationRegistry` scans `/Applications`, `/System/Applications`, `/System/Applications/Utilities`, and `~/Applications`, then falls back to Launch Services (`NSWorkspace.urlForApplication(withBundleIdentifier:)`) for apps installed elsewhere. Results are cached once per registry instance (snapshot semantics); the scan engine creates a fresh registry per scan. No private APIs are used.
- `RealTrashService` uses `FileManager.trashItem(at:resultingItemURL:)` — the native Trash mechanism. No shell commands, no permanent deletion.
- Test doubles (`InMemoryFileSystem`, `MockApplicationRegistry`, `RecordingTrashService`) live in `MacSweep/Infrastructure/TestDoubles/` and are compiled into the app target so the hosted test bundle can use them; they contain no production logic.

## Concurrency

Use structured concurrency. Scans should be cancellable. Avoid unbounded task creation. Protect shared mutable state with actors or appropriate synchronization.
