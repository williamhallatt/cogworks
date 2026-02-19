# Deployment Best Practices

## Safe Deployment Workflow

### Pre-Deployment Checklist

Before deploying to any environment:

1. **Verify Git Status**
   ```bash
   git status
   # Ensure no uncommitted changes
   ```

2. **Run Full Test Suite**
   ```bash
   npm test  # or pytest, cargo test, etc.
   # All tests must pass
   ```

3. **Update Version**
   ```bash
   # Update package.json, Cargo.toml, or version file
   git add .
   git commit -m "Bump version to 1.2.3"
   ```

4. **Create Git Tag**
   ```bash
   git tag -a v1.2.3 -m "Release version 1.2.3"
   git push origin v1.2.3
   ```

### Deployment Stages

#### Stage 1: Deploy to Staging

Always deploy to staging first to catch issues before production.

```bash
# Deploy to staging
git push staging main

# Or using deployment tool
./deploy.sh staging
```

**Verify Staging**:
```bash
# Run smoke tests
curl https://staging.example.com/health
curl https://staging.example.com/api/version

# Check logs
heroku logs --tail --app myapp-staging
# or
kubectl logs -l app=myapp -n staging

# Manual verification
# - Test critical user flows
# - Check database migrations
# - Verify API endpoints
```

#### Stage 2: Deploy to Production

Only deploy to production after staging verification succeeds.

```bash
# Deploy to production
git push production main

# Or using deployment tool
./deploy.sh production
```

**Safety Checks**:
- ✅ Staging deployment successful
- ✅ All smoke tests passed
- ✅ Database migrations completed
- ✅ No active incidents
- ✅ Monitoring dashboards show healthy metrics

### Post-Deployment Verification

After production deployment:

1. **Health Check**
   ```bash
   curl https://api.example.com/health
   ```

2. **Version Verification**
   ```bash
   curl https://api.example.com/version
   # Should return: {"version": "1.2.3"}
   ```

3. **Monitor Logs**
   ```bash
   # Watch for errors in first 5 minutes
   tail -f /var/log/app/production.log
   ```

4. **Check Metrics**
   - Response times
   - Error rates
   - Database connection pool
   - Memory usage

### Rollback Procedure

If issues are detected post-deployment:

**Quick Rollback**:
```bash
# Heroku
heroku rollback --app myapp-production

# Kubernetes
kubectl rollout undo deployment/myapp -n production

# Git-based
git push production main:main --force
# (where main is at previous tag)
```

**Complete Rollback**:
```bash
# 1. Identify previous version
git tag --sort=-creatordate | head -2
# e.g., v1.2.3 (current), v1.2.2 (previous)

# 2. Deploy previous version
git checkout v1.2.2
./deploy.sh production

# 3. Verify rollback
curl https://api.example.com/version
# Should return: {"version": "1.2.2"}

# 4. Return to main
git checkout main
```

## Deployment Patterns

### Blue-Green Deployment

Maintain two identical production environments:

```bash
# Deploy to green environment
./deploy.sh green

# Run tests against green
./smoke-tests.sh green

# Switch traffic to green
./switch-traffic.sh green

# Keep blue running for quick rollback
# After 24h, decommission blue
```

### Canary Deployment

Gradually roll out to production:

```bash
# Deploy to 5% of servers
kubectl set image deployment/myapp myapp=myapp:1.2.3 --record
kubectl scale deployment/myapp-canary --replicas=1

# Monitor metrics for 10 minutes
# If healthy, scale to 100%
kubectl scale deployment/myapp-canary --replicas=20
```

### Feature Flags

Enable features gradually:

```javascript
if (featureFlags.isEnabled('new-checkout-flow', userId)) {
  return newCheckoutFlow();
}
return oldCheckoutFlow();
```

## Common Issues and Solutions

### Issue: Database Migration Fails

**Solution**:
```bash
# Run migration separately
./migrate.sh staging
# Verify success
./migrate.sh production

# Then deploy code
./deploy.sh production
```

### Issue: Dependencies Not Updated

**Solution**:
```bash
# Clear cache and reinstall
rm -rf node_modules
npm ci

# Or rebuild container
docker build --no-cache -t myapp:1.2.3 .
```

### Issue: Configuration Mismatch

**Solution**:
```bash
# Verify environment variables
heroku config --app myapp-production

# Update configuration
heroku config:set API_KEY=xyz --app myapp-production

# Restart to apply
heroku restart --app myapp-production
```

## Automation Example

Complete deployment script:

```bash
#!/bin/bash
set -e  # Exit on error

ENVIRONMENT=$1
VERSION=$(cat VERSION)

echo "Deploying $VERSION to $ENVIRONMENT"

# Pre-deployment checks
echo "Running pre-deployment checks..."
git diff --exit-code || { echo "Uncommitted changes detected"; exit 1; }
npm test || { echo "Tests failed"; exit 1; }

# Create tag
git tag -a "v$VERSION" -m "Release $VERSION"
git push origin "v$VERSION"

# Deploy to staging
if [ "$ENVIRONMENT" = "production" ]; then
    echo "Deploying to staging first..."
    git push staging main

    echo "Verifying staging..."
    curl -f https://staging.example.com/health || { echo "Staging health check failed"; exit 1; }

    echo "Staging verified. Deploying to production..."
fi

# Deploy
git push "$ENVIRONMENT" main

# Verify
echo "Verifying deployment..."
sleep 10  # Wait for startup
curl -f https://$ENVIRONMENT.example.com/health || { echo "Deployment verification failed"; exit 1; }

echo "Deployment successful!"
echo "Rollback command: heroku rollback --app myapp-$ENVIRONMENT"
```

## Checklist Template

Copy this for each deployment:

```
[ ] Git status clean
[ ] All tests passing
[ ] Version bumped
[ ] Git tag created
[ ] Deployed to staging
[ ] Staging verified
[ ] Deployed to production
[ ] Production health check passed
[ ] Monitoring dashboards healthy
[ ] Rollback procedure documented
[ ] Team notified
```
