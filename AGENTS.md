# MacSweep — AGENTS.md

## Mission

You are the coding master for **MacSweep**, a native macOS storage and cleanup utility. Build the product from this repository specification, not from assumptions.

MacSweep must be safer and more deterministic than an AI agent performing ad-hoc filesystem cleanup. The cleanup engine must never depend on an LLM.

## Operating rules

1. Read this file and every document in `docs/` before making architectural decisions.
2. Implement incrementally according to `docs/19-ROADMAP.md`.
3. Before changing architecture, update the relevant specification and keep implementation aligned.
4. Never silently weaken a safety rule to make a test pass.
5. Never use destructive shell commands as the normal cleanup mechanism.
6. Never implement blanket recursive deletion such as `rm -rf` for user cleanup.
7. Prefer moving selected items to the user's Trash, with an auditable operation record.
8. Scanner code must be read-only.
9. Cleanup code must receive only explicitly selected, validated items.
10. Never delete or modify user documents, repositories, SSH credentials, shell configuration, passwords, keychains, system files, or unknown data automatically.
11. Treat developer data as review/protected by default.
12. Handle permission failures as normal conditions; do not bypass macOS security controls.
13. Never request broader privileges merely because a scan encountered an inaccessible path.
14. Every cleanup item must explain why it was detected, what paths are affected, its confidence/risk, and what happens on cleanup.
15. Add tests before or alongside risky implementation.
16. Run build, unit tests, and relevant integration tests after meaningful changes.
17. Keep the app usable without network access.
18. Do not add telemetry, analytics, advertising, cloud sync, or remote execution unless explicitly specified later.
19. Do not send filesystem contents to external services.
20. Keep secrets out of source control.

## Definition of done

A feature is not done until:
- implementation exists;
- tests cover normal and edge cases;
- safety behavior is verified;
- UI communicates the behavior clearly;
- errors are handled;
- documentation is updated;
- the project builds cleanly;
- relevant tests pass.

## Agent workflow

For each phase:
1. Read the phase specification.
2. Inspect the existing repository.
3. Make the smallest coherent implementation.
4. Add/update tests.
5. Build and test.
6. Review for safety regressions.
7. Update progress/checklists.
8. Only then continue to the next phase.

If a requirement is ambiguous, choose the safest reversible behavior and document the assumption.

## Build & Test Commands

- Build (Debug): `xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Debug build`
- Test: `xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Debug test`
- Build (Release): `xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Release build`
- No formatter/linter is configured yet; match the style of existing files.

## Toolchain baseline (established Phase 0)

- macOS 26.6.2, Apple Silicon (arm64); Xcode 26.6; Swift 6.3.3; macOS 26.5 SDK.
- Deployment target: macOS 15.0 (documented in docs/17-MACOS-COMPATIBILITY.md).
- Swift 6 language mode. Tests use Swift Testing.
- Development signing is ad-hoc (`CODE_SIGN_IDENTITY = -`); no signing identity is hardcoded. Release signing is injected at archive time (Phase 11).

## Product principle

**MacSweep recommends. The user decides. MacSweep executes only what the user explicitly approved.**
