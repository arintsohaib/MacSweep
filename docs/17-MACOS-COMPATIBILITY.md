# 17 — macOS Compatibility

## Policy

Determine the minimum supported macOS version from the project's current Xcode/SDK setup and document it.

### Determined (Phase 0)

- Toolchain: Xcode 26.6, Swift 6.3.3, macOS 26.5 SDK, on macOS 26.6.2 (Apple Silicon).
- SDK minimum deployment target: macOS 13.1.
- MacSweep minimum supported version: **macOS 15.0**. Chosen above the SDK minimum to use modern SwiftUI/Observation and concurrency APIs; still within Apple's current support window.
- Architecture: Apple Silicon first. Builds use standard architectures; Intel remains buildable but is not an active test platform in v1.
- Language mode: Swift 6 (strict concurrency).

Use availability checks where APIs differ.

Test:
- Apple Silicon;
- Intel if support is retained;
- current supported macOS releases.

Do not use private APIs.

Handle platform permission behavior gracefully.

## Distribution readiness

Prepare for:
- hardened runtime;
- code signing;
- notarization;
- Developer ID distribution.

Do not hardcode signing identities.
