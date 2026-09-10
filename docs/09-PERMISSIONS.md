# 09 — Permissions

## Principle

Respect macOS privacy and sandbox/security controls.

## Behavior

- Request only permissions needed for the operation.
- Explain why access is needed.
- If access is denied, show a useful limitation message.
- Never attempt security bypasses.
- Do not execute as root merely for convenience.

## Architecture decision

Start with the least-privileged architecture that supports the product. If privileged operations become necessary, isolate them behind a narrowly scoped helper with explicit authorization and a small API.

Do not add a privileged helper until a concrete feature requires it.

## Sensitive locations

Treat credentials, keychains, SSH keys, browser profiles, messages, mail, and other sensitive stores as protected and outside normal cleanup.
