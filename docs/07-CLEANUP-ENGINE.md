# 07 — Cleanup Engine

## Principle

Cleanup is an execution of an already-reviewed decision, not a discovery process.

## API shape

Use a high-level operation such as:

```swift
cleanup(selectedItems: [CleanupItem]) async -> CleanupReport
```

The engine must internally validate every item.

## Workflow

```text
Selection
→ validation
→ revalidation
→ protected-path check
→ identity check
→ user confirmation already obtained
→ move to Trash
→ verify
→ report
```

## Trash

Prefer the native macOS Trash mechanism for user-owned removable items.

Do not permanently delete by default.

## Failure handling

Each item gets:
- status;
- error category;
- user-readable message;
- affected path;
- recovery suggestion.

Continue independent items when safe.

## Idempotence

Running cleanup twice should not produce destructive side effects. Already-missing items should be reported as already absent, not treated as an error that causes unrelated cleanup to stop.

## No shell deletion

Do not invoke `rm`, `rm -rf`, shell pipelines, or shell-evaluated paths for normal cleanup.

## Audit

Keep a local cleanup history containing metadata necessary to explain what happened. Do not store file contents.

## Cleanup decisions (Phase 7)

- `ProtectedPathRules` enforces protection for system roots (`/`, `/System`, `/usr`, `/bin`, `/sbin`, `/etc`, `/opt`, `/Library`, `/Applications`, `/private`, etc.) and sensitive user directories (`Documents`, `Desktop`, `Downloads`, `Movies`, `Music`, `Pictures`, `Public`, `.ssh`, `.gnupg`, `.aws`, `Library/Keychains`, `Library/Mail`, `Library/Messages`, `Library/Safari`).
- In addition, any path whose canonicalized target resolves outside the user's home folder is rejected as protected (preventing symlink escape attacks).
- Revalidation immediately precedes every move: checks existence, kind match, file size/mtime match, and canonical protection. Any deviation marks the item as `.rejected` (with `.changedSinceScan` or `.protected`).
- If an item's path is already gone at cleanup time, it is reported idempotently as `.alreadyAbsent` with 0 bytes moved, maintaining overall cleanup success.
- If an item has multiple locations and some fail, the item is marked `.failed` with the partial move count and error category recorded (never treating partial success as complete success).
- Cleanup runs off the main actor via `Task.detached`. Cancellation leaves moved files safely in the Trash and cancels remaining items with `.cancelled`.
- Deletion exclusively uses the macOS Trash via `TrashService` (`FileManager.trashItem(at:resultingItemURL:)`). No shell commands, `rm`, or direct unlinking are ever used.
