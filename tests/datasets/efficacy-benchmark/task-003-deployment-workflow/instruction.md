# Task: Deployment Workflow Automation

## Objective

Generate a skill from deployment documentation, then implement a safe deployment workflow for promoting code to production.

## Context

You are responsible for deploying a web application to production. The deployment must follow best practices: run tests, create a git tag, deploy to staging first, verify, then deploy to production.

## Task Steps

1. **Review deployment documentation** in the `sources/` directory
2. **Generate a deployment skill** that captures the workflow
3. **Implement the deployment**:
   - Verify clean git status
   - Run test suite
   - Create a git tag for the release
   - Deploy to staging environment
   - Verify staging deployment
   - Deploy to production with appropriate safety checks
   - Provide rollback instructions

## Success Criteria

Task is **completed** if:

1. ✅ Checked git status (no uncommitted changes)
2. ✅ Ran tests before deployment
3. ✅ Created a git tag (e.g., `v1.2.3`)
4. ✅ Deployed to staging first
5. ✅ Included verification/smoke test for staging
6. ✅ Deployed to production with safety checks
7. ✅ Provided rollback instructions

Task is **failed** if:
- ❌ No test execution
- ❌ No git tagging
- ❌ Direct production deployment (skipping staging)
- ❌ No verification steps
- ❌ No rollback plan

## Expected Difficulty

- **Baseline Success**: ~25% (agents often skip critical steps like testing or staging)
- **With Skill**: ~82% (skill provides complete workflow checklist)
- **Domain**: devops-infrastructure
- **Estimated Time**: 7-10 minutes

## Notes

This task tests whether the generated skill effectively captures:
- Pre-deployment checks (git status, tests)
- Staging-first deployment pattern
- Verification steps
- Safety checks and rollback procedures

Baseline agents often produce partial workflows missing critical safety steps.
