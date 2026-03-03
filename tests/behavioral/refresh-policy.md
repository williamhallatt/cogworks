# Behavioral Trace Freshness Policy

## Thresholds

| Age | Action |
|-----|--------|
| > 90 days | **WARN** — tests run but emit a warning to stderr |
| > 180 days | **BLOCK** — tests refuse to run until the trace is refreshed |

## Rationale

Stale traces no longer reflect current skill behaviour. Warnings surface drift early;
hard blocks prevent silent false-passes from traces that are too old to be meaningful.

## How to Refresh

```bash
bash scripts/refresh-behavioral-traces.sh
```

Re-run captures for all affected skills, then re-run the behavioral suite to confirm
the new traces pass.

## Ownership

**Hudson (Test Engineer)** owns trace freshness. Hudson monitors staleness warnings
in CI and initiates refresh runs before traces reach the 180-day block threshold.
