# Claude Code Documentation Smart Index

## Step 1: Extract Metadata from Content

For each downloaded `*.md` file in `_sources/cc-docs`, analyze content to extract:

| Metadata | Detection Method |
|----------|------------------|
| `has_examples` | Presence of code blocks + "example" headings |
| `has_warnings` | Warning/caution blocks, "avoid", "don't" patterns |
| `has_code_samples` | Count of fenced code blocks |
| `key_topics` | H2 headings, bold terms in intro |
| `internal_links` | Links to other `/docs/en/*.md` pages |

**Rationale**: Automated extraction reduces manual effort and ensures consistency.

**Exclude**: The `_sources/cc-docs/docs-update-tool` directory.

---

## Step 2: Classify Difficulty

**Criteria**:

| Level | Signals |
|-------|---------|
| **beginner** | "quickstart", "overview", "getting started" in title; no prerequisites |
| **intermediate** | Feature-specific; requires CLI familiarity; has some prerequisites |
| **advanced** | Enterprise/security focus; multi-system integration; deep configuration |

**Classification by document** (proposed):

- **Beginner**: overview, quickstart, setup, vs-code, jetbrains, terminal-config, common-workflows, interactive-mode, desktop, chrome
- **Intermediate**: skills, hooks-guide, mcp, memory, settings, costs, permissions, model-config, checkpointing, fast-mode, keybindings, statusline
- **Advanced**: agent-teams, sandboxing, llm-gateway, network-config, plugins-reference, headless, github-actions, gitlab-ci-cd, devcontainer, security, monitoring-usage

**Rationale**: Difficulty ranking helps users navigate learning paths and helps synthesis order content appropriately.

---

## Step 3: Calculate Quality Ratings

**Quality Score (1-5)**:

| Score | Criteria |
|-------|----------|
| 5 | Has examples + warnings + code samples; actionable; comprehensive |
| 4 | Has examples + code samples; mostly actionable; good coverage |
| 3 | Some examples OR code samples; partially actionable |
| 2 | Minimal examples; primarily conceptual; hard to apply |
| 1 | No examples; vague; incomplete |

**Quality factors** (boolean):
- `has_examples`: Contains practical, runnable examples
- `has_warnings`: Documents pitfalls and anti-patterns
- `has_code_samples`: Contains code blocks
- `has_diagrams`: Contains visual diagrams
- `actionable`: Reader can immediately apply knowledge

**Rationale**: Quality ratings help prioritize authoritative sources during synthesis and identify gaps.

---

## Step 4: Identify Related Concepts

**Relationship types**:

| Type | Meaning |
|------|---------|
| `prerequisites` | Must understand before this doc |
| `complements` | Related parallel topic |
| `advanced_topics` | Deeper dives on subtopics |

**Detection**:
- Parse internal links from content
- Group by topic clusters (extensibility, enterprise, IDE, etc.)
- Apply domain heuristics (all cloud providers complement each other)

**Topic clusters** (proposed):

```
getting_started: overview, quickstart, setup, authentication
extensibility: skills, sub-agents, plugins, hooks, hooks-guide, mcp, features-overview
enterprise: third-party-integrations, network-config, llm-gateway, permissions, sandboxing, security, legal-and-compliance
ide_integration: vs-code, jetbrains, terminal-config
cloud_providers: amazon-bedrock, google-vertex-ai, microsoft-foundry
automation: github-actions, gitlab-ci-cd, headless, agent-teams
```

**Rationale**: Relationship mapping enables learning paths and helps synthesis identify concept connections.

---

## Step 5: Build Index File

**Location**: `_sources/cc-docs/index.yaml`

### Proposed Index Schema

```yaml
# Claude Code Documentation Index
meta:
  generated_at: "2026-02-10T..."
  source_file: "_sources/cc-docs/cc-md-docs-links.md"
  total_docs: 59
  download_success: 57
  download_failed: 2

documents:
  skills:                              # slug as key
    # Identity
    url: "https://code.claude.com/docs/en/skills.md"
    local_path: "_sources/cc-docs/skills.md"
    title: "Extend Claude with skills"
    description: "Create, manage, and share skills..."

    # Classification
    difficulty: "intermediate"         # beginner | intermediate | advanced
    authority: "official"              # official | reference | tutorial
    completeness: "comprehensive"      # comprehensive | partial | niche

    # Quality
    quality:
      score: 5                         # 1-5
      has_examples: true
      has_warnings: true
      has_code_samples: true
      has_diagrams: false
      actionable: true

    # Synthesis metadata
    synthesis:
      target_audience: "intermediate"
      domain: "extensibility"
      key_topics:
        - "SKILL.md structure"
        - "slash commands"
        - "invocation modes"
      unique_value: "Authoritative reference for skill architecture"
      prerequisite_concepts:
        - "CLAUDE.md basics"

    # Relationships
    related:
      prerequisites: ["overview", "quickstart"]
      complements: ["sub-agents", "plugins", "hooks"]
      advanced_topics: ["plugins-reference"]

    # Fetch status
    fetch:
      status: "success"                # success | failed | partial
      fetched_at: "2026-02-10T..."
      content_length: 15234
      error: null

# Topic clusters with learning paths
clusters:
  getting_started:
    name: "Getting Started"
    difficulty: "beginner"
    docs: ["overview", "quickstart", "setup", "authentication"]
    learning_path: ["overview", "quickstart", "setup", "authentication"]

  extensibility:
    name: "Extensibility"
    difficulty: "intermediate"
    docs: ["skills", "sub-agents", "plugins", "hooks", "hooks-guide", "mcp"]
    learning_path: ["skills", "hooks-guide", "sub-agents", "plugins", "mcp"]

  enterprise:
    name: "Enterprise Deployment"
    difficulty: "advanced"
    docs: ["third-party-integrations", "network-config", "llm-gateway", "permissions", "sandboxing", "security"]
    learning_path: ["permissions", "security", "sandboxing", "network-config", "llm-gateway"]

  ide_integration:
    name: "IDE Integration"
    difficulty: "beginner"
    docs: ["vs-code", "jetbrains", "terminal-config"]
    learning_path: ["terminal-config", "vs-code", "jetbrains"]

  cloud_providers:
    name: "Cloud Providers"
    difficulty: "intermediate"
    docs: ["amazon-bedrock", "google-vertex-ai", "microsoft-foundry"]
    learning_path: ["amazon-bedrock", "google-vertex-ai", "microsoft-foundry"]

  automation:
    name: "CI/CD & Automation"
    difficulty: "advanced"
    docs: ["github-actions", "gitlab-ci-cd", "headless", "agent-teams"]
    learning_path: ["headless", "github-actions", "gitlab-ci-cd", "agent-teams"]

# Failed downloads for retry
failed:
  - url: "..."
    slug: "..."
    error: "HTTP 404"
    attempted_at: "..."
```

**Rationale**:
- YAML is human-readable, git-friendly, and easy to parse
- Hierarchical structure groups related metadata
- Clusters enable topic-based synthesis
- Learning paths support ordered consumption
- Failed section enables retry workflow

---

## Verification

**After implementation**: confirm `_sources/cc_docs/index.yaml` parses correctly, all referenced slugs have files
