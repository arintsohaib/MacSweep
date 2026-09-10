# 13 — Error Handling

Errors are expected filesystem states, not exceptional catastrophes.

## Categories

- permissionDenied
- notFound
- changedSinceScan
- protected
- invalidItem
- unsupported
- ioFailure
- cancelled
- insufficientSpace
- unknown

## UI

Use plain language:
- what happened;
- whether anything was deleted/moved;
- what the user can do next.

Never claim "cleaned successfully" when an item only scanned successfully.

## Partial results

Scans should return useful results plus diagnostics when safe. Cleanup should report per-item outcomes.
