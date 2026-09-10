# 00 — Project Definition

## Product

**MacSweep** is a native macOS application for discovering reclaimable storage and safely cleaning application leftovers, caches, logs, and selected developer data.

## Problem

AI coding agents can perform powerful filesystem operations, but their judgment is not an appropriate cleanup control plane. MacSweep provides a repeatable, transparent, local-first workflow.

## Core workflow

Scan → classify → inspect → select → preview → confirm → move to Trash → verify → report.

## Goals

- Native macOS experience.
- Fast, understandable scans.
- Application-leftover detection as the flagship feature.
- Safety-first cleanup.
- Reversible cleanup where possible.
- Explicit user approval.
- Useful developer cleanup without destroying development environments.
- Offline operation.
- Clear explanations.

## Non-goals for v1

- Antivirus.
- Malware removal.
- Registry-style system optimization.
- Memory/RAM cleaners.
- Automatic background deletion.
- AI-controlled deletion.
- Cloud cleanup.
- Privacy-erasure guarantees.
- Kernel/system-extension manipulation.
- Circumventing macOS protections.

## Target environment

- Apple Silicon first.
- Modern supported macOS versions, determined during implementation from currently installed SDK/toolchain.
- Native Swift/SwiftUI.
