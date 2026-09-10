# 22 — OpenCode Operating Guide

Use this document as the practical execution loop.

## Initial command

Read:
- `AGENTS.md`
- all `docs/*.md`

Then inspect the repository before creating files.

## For each phase

1. State internally which phase is active.
2. Inspect existing implementation.
3. Implement only the required scope.
4. Run formatter/linter if configured.
5. Build.
6. Run tests.
7. Fix failures.
8. Re-run.
9. Review safety.
10. Update the implementation checklist.
11. Continue.

## Do not

- rewrite the whole project unnecessarily;
- introduce dependencies casually;
- create fake implementations just to satisfy tests;
- skip tests for cleanup code;
- weaken safety rules;
- use AI/network services for local cleanup decisions;
- claim completion without a successful build/test result.

## Final verification

Before declaring the project complete:
- build Release;
- run the complete test suite;
- run safety fixture tests;
- inspect entitlements;
- inspect signing configuration;
- verify no secrets;
- verify no destructive shell commands;
- verify documentation;
- produce a concise final implementation report.
