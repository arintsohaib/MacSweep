# 11 — Testing

## Unit tests

Test:
- path canonicalization;
- protected path matching;
- risk evaluation;
- application association;
- bundle ID parsing;
- size calculation;
- deduplication;
- exclusions;
- selection validation.

## Scanner tests

Use temporary directories and synthetic application-data layouts.

Examples:
- installed app with cache;
- uninstalled app with container;
- shared container;
- unknown folder;
- symlink;
- disappearing file;
- permission failure;
- renamed app;
- nested finding.

## Cleanup tests

Never use real user data.

Use a temporary filesystem fixture and verify:
- selected item moves to Trash abstraction;
- unselected item remains;
- protected item is rejected;
- changed item is rejected;
- missing item is handled;
- partial failure is reported;
- symlink cannot escape intended target;
- cancellation behaves safely.

## UI tests

Cover:
- scan;
- result selection;
- detail;
- review;
- confirmation;
- success;
- partial failure;
- empty results;
- permission limitation.

## Acceptance

A release candidate requires:
- clean build;
- all automated tests passing;
- no known high-severity cleanup safety defect.
