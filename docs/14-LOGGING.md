# 14 — Logging

## Goals

Logs help debug scans and cleanup without becoming a privacy risk.

## Rules

- Use OSLog.
- Avoid logging file contents.
- Avoid logging secrets.
- Avoid unnecessary full paths in persistent logs.
- Use appropriate privacy annotations.
- Log operation IDs and categories.
- Provide a user-facing history separate from developer diagnostics.

## Debug mode

A development-only diagnostic mode may provide more detail locally. It must not silently enable telemetry.
