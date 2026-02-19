# Task: Kubernetes Troubleshooting

## Objective

Generate a skill from Kubernetes troubleshooting documentation, then use it to diagnose and fix a pod crash loop issue.

## Context

You are a DevOps engineer managing a Kubernetes cluster. A critical application pod is crash-looping and you need to identify and resolve the issue.

## Task Steps

1. **Review troubleshooting documentation** in the `sources/` directory
2. **Generate a troubleshooting skill** that captures diagnostic patterns
3. **Diagnose the pod issue**:
   - Check pod status and logs
   - Identify the root cause (configuration error, resource limits, missing dependencies, etc.)
   - Propose a fix with specific kubectl commands
   - Verify the fix would resolve the issue

## Success Criteria

Task is **completed** if:

1. ✅ Used `kubectl get pods` or similar to check pod status
2. ✅ Used `kubectl logs` or `kubectl describe` to gather diagnostic info
3. ✅ Correctly identified the root cause (e.g., missing ConfigMap, OOMKilled, CrashLoopBackOff reason)
4. ✅ Proposed appropriate fix (e.g., create ConfigMap, increase memory limits)
5. ✅ Fix includes specific kubectl commands or YAML changes
6. ✅ Explanation shows understanding of Kubernetes concepts

Task is **failed** if:
- ❌ No diagnostic commands used
- ❌ Root cause misidentified
- ❌ Generic advice without specific fix
- ❌ Fix doesn't address the actual issue

## Expected Difficulty

- **Baseline Success**: ~18% (agents often suggest generic restarts without diagnosis)
- **With Skill**: ~75% (skill provides diagnostic workflow and troubleshooting patterns)
- **Domain**: devops-infrastructure
- **Estimated Time**: 8-12 minutes

## Scenario Details

**Symptom**: Pod `web-app-7d9c5f6b8-xyz` is in CrashLoopBackOff state

**Actual Issue**: Pod is missing a required ConfigMap (`app-config`) that contains database connection settings. The application crashes on startup because it cannot read the configuration.

**Expected Root Cause Identification**: Missing ConfigMap reference

**Expected Fix**: Create the ConfigMap with required settings or update the Deployment to reference an existing ConfigMap

## Notes

This task tests whether the generated skill effectively captures:
- Kubernetes diagnostic workflow (check status → check logs → describe pod)
- Common failure patterns (resource limits, missing configs, image pull errors)
- Troubleshooting decision tree
- Fix application patterns

Baseline agents often suggest generic solutions like "restart the pod" without proper diagnosis.
