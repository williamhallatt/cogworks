#!/usr/bin/env python3
"""
Verification script for API synthesis task.

Checks if the implementation meets success criteria.
"""

import argparse
import json
import re
import sys
from pathlib import Path


def check_endpoint_route(content: str) -> bool:
    """Check if POST /api/auth/login endpoint is defined."""
    patterns = [
        r"post\s*\(\s*['\"]/?api/auth/login['\"]",  # Express-style
        r"@app\.route\s*\(\s*['\"]/?api/auth/login['\"].*method.*POST",  # Flask-style
        r"@router\.post\s*\(\s*['\"]/?api/auth/login['\"]",  # FastAPI-style
    ]
    return any(re.search(pattern, content, re.IGNORECASE) for pattern in patterns)


def check_validation(content: str) -> bool:
    """Check if request validation is present."""
    indicators = [
        "validate",
        "required",
        "if not email",
        "if not password",
        "400",  # Bad request status
        "ValidationError",
    ]
    return sum(indicator.lower() in content.lower() for indicator in indicators) >= 2


def check_authentication(content: str) -> bool:
    """Check if authentication logic is present."""
    indicators = [
        "bcrypt",
        "hash",
        "compare",
        "verify",
        "findOne",
        "find_one",
        "get_user",
    ]
    return any(indicator.lower() in content.lower() for indicator in indicators)


def check_jwt_token(content: str) -> bool:
    """Check if JWT token generation is present."""
    indicators = ["jwt", "token", "sign", "encode"]
    return sum(indicator.lower() in content.lower() for indicator in indicators) >= 2


def check_error_handling(content: str) -> bool:
    """Check if error handling is present."""
    indicators = [
        "401",  # Unauthorized
        "try",
        "catch",
        "except",
        "error",
        "Invalid credentials",
    ]
    return sum(indicator.lower() in content.lower() for indicator in indicators) >= 3


def check_response_format(content: str) -> bool:
    """Check if response format matches specification."""
    # Look for response with token and user fields
    has_token_response = "token" in content.lower() and (
        "expires" in content.lower() or "user" in content.lower()
    )
    return has_token_response


def verify_implementation(file_path: Path) -> dict:
    """Run all verification checks on implementation."""
    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to read file: {e}",
            "checks": {},
        }

    checks = {
        "endpoint_route": check_endpoint_route(content),
        "validation": check_validation(content),
        "authentication": check_authentication(content),
        "jwt_token": check_jwt_token(content),
        "error_handling": check_error_handling(content),
        "response_format": check_response_format(content),
    }

    # Task is successful if all checks pass
    success = all(checks.values())

    return {
        "success": success,
        "checks": checks,
        "passed": sum(checks.values()),
        "total": len(checks),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Verify API authentication implementation"
    )
    parser.add_argument(
        "--implementation",
        required=True,
        type=Path,
        help="Path to implementation file",
    )
    parser.add_argument("--json", action="store_true", help="Output JSON format")

    args = parser.parse_args()

    if not args.implementation.exists():
        print(f"Error: File not found: {args.implementation}", file=sys.stderr)
        return 2

    result = verify_implementation(args.implementation)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Verification: {'PASS' if result['success'] else 'FAIL'}")
        print(f"Checks passed: {result['passed']}/{result['total']}")
        print("\nCheck results:")
        for check, passed in result["checks"].items():
            status = "✓" if passed else "✗"
            print(f"  {status} {check}")

        if not result["success"]:
            print("\nFailed checks indicate missing or incomplete implementation.")

    return 0 if result["success"] else 1


if __name__ == "__main__":
    sys.exit(main())
