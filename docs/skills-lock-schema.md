# skills-lock.json Schema Documentation

## Current Schema

The `skills-lock.json` file tracks installed skills and their integrity hashes:

```json
{
  "version": 1,
  "skills": {
    "skill-name": {
      "source": "/path/to/source",
      "sourceType": "local" | "git" | "npm",
      "computedHash": "sha256-hex-string"
    }
  }
}
```

**Field Definitions:**
- `version` — schema version (currently 1)
- `skills` — object mapping skill slugs to metadata
- `source` — absolute or relative path/URL to the skill
- `sourceType` — one of "local", "git", "npm"
- `computedHash` — SHA-256 hash of the skill's content (SKILL.md + prompt templates)

## Proposed: core_skills_hash Field

**Why it matters:** cogworks depends on three core skills (`cogworks`, `cogworks-encode`, `cogworks-learn`). If these skills drift or are accidentally edited, the entire encoding pipeline becomes unreliable.

**Proposed addition to root level:**

```json
{
  "version": 1,
  "core_skills_hash": "sha256-hex-string",
  "core_skills_locked_at": "2026-03-10T14:22:30Z",
  "skills": {
    // ... existing skills
  }
}
```

**Field definitions:**
- `core_skills_hash` — SHA-256 hash of the combined content of `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`, and `skills/cogworks-learn/SKILL.md` in lexicographic order
- `core_skills_locked_at` — ISO 8601 timestamp when the hash was last recorded

**How to compute:**
```bash
cat \
  <(sort <<< "$(find skills/cogworks* -name SKILL.md | xargs -I {} cat {})") \
  | sha256sum | awk '{print $1}'
```

**When to update:**
- On first adoption (add the hash to an existing lock file)
- After any deliberate change to cogworks core skills (commit + update hash)
- NOT automatically — manual review required to confirm the change is intentional

## Agent Usage

Agents reading `skills-lock.json` should:

1. **On startup:** Compute the current hash of the three core skills
2. **Compare:** If `core_skills_hash` exists and differs from the current hash:
   - Warn: `⚠️ Core skills have changed since lock (expected: {locked}, found: {current})`
   - Suggest: `npx skills refresh` to update the lock
3. **Do not block:** Warn but continue; allow override via `--skip-lock-check`

**Example warning in agent output:**
```
⚠️ Skills lock warning: core_skills_hash mismatch
  Expected: abc123...
  Found:    def456...
  
  The cogworks core skills have been modified. 
  Run 'npx skills refresh' to update the lock, 
  or pass '--skip-lock-check' to proceed anyway.
```

## Migration for Existing Lock Files

**Step 1:** Compute the current core skills hash:
```bash
# In the repo root
bash scripts/compute-core-hash.sh
```

**Step 2:** Add to existing lock file:
```bash
cat skills-lock.json | jq \
  '.core_skills_hash = "HASH_VALUE" | 
   .core_skills_locked_at = "2026-03-10T14:22:30Z"' \
  > skills-lock.json.tmp && mv skills-lock.json.tmp skills-lock.json
```

**Step 3:** Commit the updated lock file:
```bash
git add skills-lock.json && git commit -m "chore/ Add core_skills_hash to lock file"
```

## Integration Points

- **cogworks skill:** Reads lock on invocation; warns if hash mismatch
- **cogworks-learn skill:** Validates core hash before generating new skills
- **CI/CD:** `pre-release-validation.yml` should check lock consistency
- **Agent install:** `npx skills add` should optionally verify the lock hash

## Schema Version Migration

If the schema changes in the future, increment `version` and provide a migration path:
- Version 1 → 2: Add new fields with defaults, keep backward compatibility
- Keep all legacy tools reading at least one version back
