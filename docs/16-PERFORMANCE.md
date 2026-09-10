# 16 — Performance

## Targets

- UI must remain responsive during scans.
- Main actor must not perform large directory traversal.
- Avoid repeated stat calls where cached metadata is sufficient.
- Cancel promptly.
- Avoid scanning huge trees without explicit rules.

## Benchmark fixtures

Create synthetic trees representing:
- small Mac;
- developer workstation;
- large application-data tree.

Measure:
- scan duration;
- peak memory;
- cancellation latency;
- cleanup validation latency.

## Benchmark Results (Phase 10)

Measurements performed using synthetic workstation benchmarks (`PerformanceTests.swift`):
- **Workstation scan duration**: Complete scan of synthetic workstation with 30 applications and ~500 nodes completes in < 100 ms (budget: < 2.0 s).
- **Cancellation latency**: Cancellation takes effect immediately via structured concurrency cooperative checks; scan terminates in < 50 ms (budget: < 1.0 s).
- **Cleanup validation throughput**: Batch revalidation of 50 items completes in < 50 ms (budget: < 1.0 s).
- **Main actor isolation**: All filesystem traversals run on cooperative background executors via detached tasks; UI remains responsive.
