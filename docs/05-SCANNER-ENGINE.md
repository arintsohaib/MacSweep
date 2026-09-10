# 05 — Scanner Engine

## Contract

A scanner is read-only and produces immutable findings.

Suggested protocol:

```swift
protocol FindingsScanner {
    var category: ScanCategory { get }
    func scan(context: ScanContext) async throws -> [CleanupItem]
}
```

Note: the protocol is named `FindingsScanner` because `Scanner` collides with the `Scanner` alias of Foundation's `NSScanner` on the macOS 26 SDK.

## Scan context

Include:
- cancellation;
- filesystem abstraction;
- application registry;
- rule configuration;
- exclusions;
- progress reporter.

## Requirements

- Deterministic classification.
- Cancellation support.
- Bounded concurrency.
- Ignore inaccessible locations with structured diagnostics.
- Never crash because one path disappears.
- Deduplicate findings.
- Canonicalize paths.
- Avoid scanning enormous irrelevant trees without a rule.

## Size calculation

- Avoid blocking the main actor.
- Handle missing files.
- Handle permissions.
- Prevent double-counting nested findings.
- Clearly define whether logical or allocated size is shown.

Default display should use a consistent byte formatter.

## Progress

Report phase/category progress rather than pretending to know exact progress when it cannot be measured accurately.

## Engine decisions (Phase 3)

- The engine runs one task per enabled scanner (bounded by the scanner count, ≤ 10), in a structured task group. User cancellation cancels the group; running scanners stop at their next `checkCancellation()` point.
- Scanners that throw (other than cancellation) are isolated: an error diagnostic is recorded and the rest of the scan continues.
- Deduplication: overlapping path sets across findings collapse to one finding, prioritized by category order, then confidence, then smaller size. A cleanable finding that overlaps protected data is dropped entirely (safe failure), never merged.
- Paths stored on findings must be canonicalized (symlink-resolved) by the scanner before creating the item; the engine compares stored paths for overlap.
- Size is logical bytes; `totalSize` is the sum of the finding's own paths only, so nested findings (already deduplicated) cannot double-count.
