<div align="center">

![MacSweep](docs/images/app-icon.png)

# MacSweep

**Find reclaimable storage on your Mac — safely.**

MacSweep is a native macOS utility that scans your user library for caches, logs, leftover application data, and large files, explains exactly why each item was found, and moves only what you explicitly select to the macOS Trash. Nothing is ever permanently deleted.

[![Latest release](https://img.shields.io/github/v/release/arintsohaib/MacSweep)](https://github.com/arintsohaib/MacSweep/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/arintsohaib/MacSweep/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/macOS-15%20%2B-blue.svg)](https://support.apple.com/en-us/113947)

</div>

## Product principle

> **MacSweep recommends. You decide. MacSweep executes only what you explicitly approved.**

- **Every finding is explained** — why it was detected, which paths are affected, risk level, confidence, and exactly what happens on cleanup.
- **Safe by construction** — the cleanup engine re-validates every item immediately before moving it (identity, kind, size, modification date, and protected-path checks). If anything changed since the scan, that item is skipped, never guessed.
- **Reversible** — items go to the macOS Trash, where they stay recoverable. MacSweep never performs irreversible deletion.
- **Deterministic** — the scan and cleanup engine are pure, rule-based code. No AI, no heuristics at runtime, no network access, no telemetry.
- **Honest UI** — no fake "health scores" or "optimization meters". You see item counts, sizes, and what each action will do.

## Features

| Category | What it finds |
|---|---|
| **Uninstalled Apps** | Sandbox containers and Application Support folders whose bundle identifier belongs to no installed app or app extension. **Informational only** (never cleanable), so shared app data is never removed |
| **Caches** | Per-application caches in `~/Library/Caches` |
| **Logs** | Per-application logs in `~/Library/Logs` |
| **Developer** | Xcode DerivedData, CoreSimulator caches, Homebrew/SPM/npm/Yarn/pip/Gradle caches, Playwright browsers. Docker VM storage is shown as protected, never cleaned |
| **Large Files** | Files in `~/Downloads` and `~/Desktop` above your chosen threshold (100 MB – 5 GB). Surfaced for review only — personal folders are never auto-cleaned |
| **Web Storage** | WebKit and HTTPStorages data per origin |
| **Saved State** | Per-application saved window state |

Other highlights:

- **Risk model** — `low` (default-selected), `review` (not selected by default), and `protected` (never cleanable) levels with per-finding evidence.
- **Nothing is selected automatically.** Every scan starts with an empty selection; you choose exactly what to clean.
- **System-owned data is never touched** — Apple bundle identifiers (`com.apple.*`), core-OS components, and preference files are excluded from detection and permanently protected at cleanup time. macOS background services are not "uninstalled apps".
- **App extensions and app groups are attributed to their owner** — `net.whatsapp.WhatsApp.Intents`, `UBF8T346G9.com.microsoft.teams`, `group.*` containers, and similar are never mistaken for leftovers while the owning app is installed. Group containers and launch agents are not used to infer that an app is gone.
- **Protected paths** — system roots, personal folders (`Documents`, `Desktop`, `Downloads`, `~/Library/Preferences`), credentials (`.ssh`, `.gnupg`, `.aws`), Keychains, mail, messages, and browser profiles are permanently protected and cannot be disabled by any setting.
- **Per-item exclusions** — exclude any finding (or any path in Settings); exclusions persist and are honored by future scans.
- **Cleanup history** — every cleanup operation is recorded with the affected paths, per-item outcomes, and moved/failed/rejected accounting.
- **Permission-honest** — if macOS limits what can be read, MacSweep tells you exactly which areas were limited instead of requesting elevated privileges.

## Recovering cleaned items

Every cleanup moves items to the macOS Trash; MacSweep never permanently deletes anything. To restore an item, open **Finder → Trash**, right-click it, and choose **Put Back** — macOS returns it to its original location. The **History** pane records each operation, including the exact paths that were affected.

## Requirements

- macOS 15 (Sequoia) or later
- Built with Xcode 26 / Swift 6 (no external dependencies)

## Get the app

Download the latest `MacSweep-x.y.z.dmg` from the [Releases page](https://github.com/arintsohaib/MacSweep/releases), open it, and drag MacSweep into Applications.

### First launch (unsigned build)

Current releases are **ad-hoc signed and not notarized** (no paid Apple Developer account is used). macOS will warn you on first launch:

1. Right-click (or Control-click) **MacSweep** in the Applications folder and choose **Open**, then confirm **Open** in the dialog.
   — or —
2. Run once in Terminal:

   ```sh
   xattr -d com.apple.quarantine /Applications/MacSweep.app
   ```

macOS will remember your decision. If you ever re-download the app, repeat the step.

> Notarized, Developer ID–signed builds will be published once a developer account is configured — see [Releasing](#releasing-a-new-version).

## Build from source

```sh
git clone https://github.com/arintsohaib/MacSweep.git
cd MacSweep

# Build (Debug)
xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Debug build

# Run the full test suite (130+ tests)
xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Debug test
```

The project uses Xcode 16+ file-system synchronized groups: adding files under `MacSweep/` or `MacSweepTests/` picks them up automatically — no project file edits needed.

## Releasing a new version

Versioning uses [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH` stored as `MARKETING_VERSION` in the Xcode project, mirrored by git tags (`v0.2.0`) and GitHub releases.

```sh
# 1. Bump the version (updates MARKETING_VERSION in the project)
./scripts/bump-version.sh 0.2.0

# 2. Commit the change
git add -A && git commit -m "Release 0.2.0"

# 3. Build a versioned DMG into build/
./scripts/package-release.sh

# 4. Tag and publish a GitHub release (requires the gh CLI, or do it on the web)
git tag -a v0.2.0 -m "MacSweep v0.2.0"
git push origin main v0.2.0
gh release create v0.2.0 build/MacSweep-0.2.0.dmg \
  --title "MacSweep v0.2.0" \
  --notes "What's new in this release"
```

The packaging script supports Developer ID signing and Apple notarization when the corresponding environment variables are set (see the header of `scripts/package-release.sh`).

## Project structure

```
MacSweep/
├── App/            App entry, AppState (single observable state object)
├── UI/             SwiftUI views (sidebar, overview, results, review, history, settings)
├── Domain/         Value types: findings, scan results, cleanup reports, risk/confidence
├── Scanner/        Scan engine, progress, exclusions, diagnostics
├── Rules/          One finder per category (caches, logs, remnants, developer, …)
├── Cleanup/        Cleanup engine with revalidation + protected-path enforcement
├── Infrastructure/ FileSystem / ApplicationRegistry / Trash abstractions + real implementations
└── Assets.xcassets App icon and artwork
MacSweepTests/      Swift Testing suites: unit, integration, security audit, performance
docs/               Product specification (requirements, architecture, safety model, …)
scripts/            Version bump + release packaging
```

## Safety model

The full safety model lives in [`docs/04-SAFETY-MODEL.md`](docs/04-SAFETY-MODEL.md). In short:

- **Safety is based on evidence, not file size.**
- Revalidation before every move; any mismatch aborts that item.
- Symlinks are never followed into unrelated targets; protection survives symlink and path-normalization tricks.
- Protected locations are enforced both at discovery and again at cleanup time.
- Race conditions are assumed; the engine favors safe failure over guessing.

## Testing

```sh
xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Debug test
```

The suite covers the domain model, scan engine (determinism, cancellation, deduplication), every rule, the cleanup engine (revalidation, protected paths, symlink escapes, race conditions), persistence, and performance budgets. An opt-in test scans the real user home directory to assert invariants on live data:

```sh
touch /tmp/macsweep-real-scan-test   # enables RealScanInvariantsTests for one run
```

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

App artwork sourced from [Icons8](https://icons8.com/).
