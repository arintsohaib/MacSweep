# 20 — Implementation Plan

## Phase 0 — Repository reconnaissance

- Inspect repository.
- Confirm Xcode/Swift/macOS SDK.
- Create/update project.
- Read all specifications.
- Establish build/test commands.

Acceptance:
- project opens/builds;
- test target exists.

## Phase 1 — Domain foundation

Implement:
- CleanupItem;
- ScanCategory;
- RiskLevel;
- Confidence;
- Evidence;
- ScanDiagnostic;
- CleanupReport;
- stable IDs.

Acceptance:
- domain tests pass.

## Phase 2 — Infrastructure

Implement protocols and adapters for:
- filesystem;
- application discovery;
- metadata;
- Trash.

Create test doubles.

Acceptance:
- no scanner depends directly on hard-to-test global filesystem behavior.

## Phase 3 — Scanner framework

Implement:
- ScanEngine;
- cancellation;
- progress;
- deduplication;
- diagnostics;
- exclusions.

Acceptance:
- synthetic scan fixtures pass.

## Phase 4 — Application detection

Implement installed-app discovery and bundle identity.

Acceptance:
- test apps and application locations are handled safely.

## Phase 5 — Uninstalled application leftovers

Implement known data-location rules.

Acceptance:
- abandoned containers are detected;
- active app data is not classified as abandoned;
- shared/protected data is review/protected.

## Phase 6 — UI

Implement sidebar, overview, results, details, review.

Acceptance:
- full scan/review flow works without cleanup.

## Phase 7 — Cleanup engine

Implement validated, reversible Trash workflow.

Acceptance:
- temporary fixture tests pass;
- protected and changed items are rejected;
- no shell deletion.

## Phase 8 — Other categories

Add:
- caches;
- logs;
- saved state;
- web storage;
- developer cleanup;
- large-file discovery.

Each category requires its own rules/tests.

## Phase 9 — Settings/history

Implement exclusions and local operation history.

## Phase 10 — Security/performance

Run:
- safety audit;
- race-condition tests;
- symlink tests;
- performance benchmarks;
- cancellation tests.

## Phase 11 — Release

- release build;
- signing configuration;
- notarization preparation;
- DMG packaging;
- user documentation.

## Agent stop conditions

Stop and ask for human review if:
- a requirement requires disabling macOS security;
- a protected-path rule must be weakened;
- permanent deletion appears necessary;
- privileged/root access becomes necessary;
- application ownership is ambiguous;
- a cleanup operation cannot be made safely reversible.
