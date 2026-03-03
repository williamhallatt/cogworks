# Safety Gates
- Expand-contract pattern required.
- Dual-write period must be observable with drift checks.
- Rollback must preserve write compatibility both directions.
- Cutover allowed only after drift < 0.1% for 24 hours.
