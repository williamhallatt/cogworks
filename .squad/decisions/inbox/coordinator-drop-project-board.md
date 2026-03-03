### 2026-03-03T11:30:00Z: Decision — no GitHub Project board
**By:** William Hallatt (via Copilot)
**What:** Do not use GitHub Projects for this repo. Issues + `squad:{member}` labels are sufficient for 22 work items. Project board adds sync overhead and requires elevated token scopes (`read:project`) that block automation.
**Why:** Work tracking is lightweight; Ralph and agent routing work directly off issue labels; no stakeholder kanban view needed at this scale.
**Action needed:** Run `gh auth refresh -s read:project,read:org,read:discussion` then `gh project delete 1 --owner @me` to remove the existing project board.
