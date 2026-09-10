# 10 — Persistence

## v1

Use lightweight local persistence only where useful:
- settings;
- exclusions;
- cleanup history;
- optional last-scan metadata.

Do not store raw directory listings indefinitely.

## Requirements

- Version stored data.
- Handle schema migration.
- Keep storage local.
- No cloud synchronization.
- No telemetry.

A simple Codable/JSON or platform-native persistence approach is acceptable for early versions. Use SwiftData only if it materially simplifies the required history/settings model without adding unnecessary complexity.

## Implementation decisions (Phase 9)

- `FilePersistenceService` manages local JSON persistence at `~/Library/Application Support/MacSweep/` using atomic writes (`settings.json` and `history.json`).
- `UserSettings` is versioned (`version: 1`) and persists enabled categories, minimum large file size, and custom excluded paths.
- `HistoricalCleanupRecord` stores operation metadata (timestamp, item count, total size reclaimed, user-facing summary, and per-item statuses). File contents and deep directory listings are never stored.
- Up to 200 cleanup operations are retained in chronological order (most recent first). Users can clear history at any time.
- `InMemoryPersistenceService` provides a test double for hermetic unit testing.
- No network access, cloud sync, or telemetry is used.
