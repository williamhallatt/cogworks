# Deployment Workflow Best Practices

## Pre-Deployment Checklist

Before deploying any code to production environments:

1. **Run full test suite** - All unit tests, integration tests, and e2e tests must pass
2. **Code review** - At least one team member must approve changes
3. **Check deployment window** - Deploy during business hours (9am-5pm PT) unless emergency
4. **Verify staging** - Changes must be tested in staging environment first
5. **Backup database** - Always create database backup before schema changes

## Staging Environment Testing

The staging environment must mirror production as closely as possible:

- Same database engine and version
- Same environment variables (except sensitive credentials)
- Representative test data (anonymized from production)
- Similar traffic patterns (use load testing tools)

**Minimum staging duration**: 24 hours before production deployment

### Test Scenarios

Execute these scenarios in staging:

1. **Happy path testing** - Normal user workflows
2. **Error handling** - Invalid inputs, edge cases
3. **Performance testing** - Load testing with 2x expected traffic
4. **Rollback testing** - Verify rollback procedures work

## Production Deployment Steps

### Step 1: Announce Deployment

Post in #deployments Slack channel:

```
Deploying [feature-name] to production
ETA: [time]
Rollback plan: [link to runbook]
On-call: @[your-name]
```

### Step 2: Enable Maintenance Mode (if needed)

For deployments requiring downtime:

```bash
# Enable maintenance mode
./scripts/enable-maintenance.sh

# Verify maintenance page is visible
curl https://app.example.com
```

### Step 3: Deploy Code

```bash
# Pull latest code
git fetch origin
git checkout main
git pull origin main

# Install dependencies
npm install

# Build production assets
npm run build

# Run database migrations (if any)
npm run migrate:prod

# Restart application servers
pm2 restart all

# Verify application started
pm2 status
```

### Step 4: Smoke Testing

Immediately after deployment:

1. Check application logs for errors
2. Verify homepage loads
3. Test critical user flows (login, checkout, etc.)
4. Check monitoring dashboards (response times, error rates)

**If any issues detected**: Execute rollback immediately

### Step 5: Monitor

Monitor for 30 minutes after deployment:

- Error rates (should remain at baseline)
- Response times (should not increase >10%)
- CPU/memory usage (should remain stable)
- User-reported issues (check support channels)

## Rollback Procedures

If issues detected after deployment, execute rollback:

### Code Rollback

```bash
# Revert to previous commit
git revert HEAD

# Or checkout previous release tag
git checkout v1.2.3

# Deploy reverted code
npm install
npm run build
pm2 restart all
```

### Database Rollback

**WARNING**: Database rollbacks are complex and data-lossy.

For migrations that add columns/tables:
- Can run application with old code (migration is forward-compatible)
- No immediate rollback needed

For migrations that remove/modify columns:
- **Must have migration rollback script prepared**
- Test rollback in staging first
- Restore from backup if rollback script fails

### Rollback Timeline

- **Immediate rollback** (< 5 minutes): If errors detected during smoke testing
- **Fast rollback** (< 15 minutes): If error rates spike >5x baseline
- **Considered rollback** (< 30 minutes): If performance degrades >20%

## Emergency Deployments

For critical production issues requiring immediate fix:

1. **Skip staging** if necessary (document why)
2. **Create hotfix branch** from production tag
3. **Minimal code changes** only
4. **Deploy immediately** with on-call engineer monitoring
5. **Post-mortem required** within 24 hours

## Deployment Frequency

Team targets:
- Staging deployments: Multiple times daily
- Production deployments: Daily during business hours
- Emergency deployments: As needed (should be <1% of deployments)

## Common Issues

**Issue**: Deployment fails mid-migration
**Solution**: Database migrations must be atomic (single transaction). Use migration tools that support rollback.

**Issue**: Application won't start after deployment
**Solution**: Check logs first (`pm2 logs`). Common causes: missing environment variables, dependency conflicts.

**Issue**: Deployment succeeds but features not visible
**Solution**: Check feature flags, cache invalidation, CDN propagation.
