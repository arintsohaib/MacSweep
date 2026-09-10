# 12 — Security

## Threat model

MacSweep itself has filesystem power. A bug could cause destructive behavior. Therefore security and safety are product requirements.

## Rules

- Validate all paths.
- Canonicalize before authorization decisions.
- Never construct shell commands from paths.
- Avoid shell execution entirely for cleanup.
- Do not trust filenames as identifiers.
- Do not follow symlinks unexpectedly.
- Do not deserialize untrusted data into executable behavior.
- Keep external dependencies minimal.
- No remote command execution.
- No upload of filesystem data.
- No credentials collection.

## Supply chain

Pin/track third-party dependencies if introduced. Prefer Apple frameworks and standard library.

## Security Audit Verification (Phase 10)

- **Subprocess / Shell Isolation**: Codebase verified to contain zero references to `Process`, `NSTask`, `posix_spawn`, `system()`, or shell evaluation. All cleanup operations use native `FileManager.trashItem`.
- **Zero Network Transmission**: Codebase contains zero references to `URLSession`, sockets, or network frameworks. All operations are local and offline.
- **Path Traversal & Symlinks**: `ProtectedPathRules` canonicalizes all paths with symlink resolution. Symlinks attempting to escape to `/System`, `/etc`, or sensitive user folders (`Documents`, `Desktop`, `.ssh`, `Keychains`) are rejected as protected. Paths resolving outside the user home directory cannot be cleaned.
- **Race Condition Safety**: Revalidation re-checks existence, kind, file size, and modification timestamp immediately prior to trashing. Any modification between scan and cleanup triggers a `.changedSinceScan` rejection.
- **Zero Third-Party Dependencies**: No CocoaPods, Carthage, Swift Package dependencies, or binary blobs. Pure Swift 6 + Apple SDKs.
