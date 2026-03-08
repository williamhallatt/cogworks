#!/usr/bin/env python3
"""Legacy helper for the retired file-backed Claude bindings.

The active runtime now resolves specialist bindings directly from
skills/cogworks/role-profiles.json, so this script no longer renders files.
"""

from __future__ import annotations

def main() -> None:
    raise SystemExit(
        "File-backed Claude specialist bindings were retired. "
        "Use skills/cogworks/role-profiles.json as the canonical binding surface."
    )


if __name__ == "__main__":
    main()
