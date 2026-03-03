# Kubernetes Outage Symptoms
- New pods in `payments` stuck Pending with occasional FailedScheduling.
- Existing pods show intermittent readiness probe failures.
- Service latency spikes coincide with DNS timeout warnings.

Users report partial outage, not total downtime.
