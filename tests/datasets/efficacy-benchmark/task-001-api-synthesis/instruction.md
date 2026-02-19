# Task: API Synthesis and Implementation

## Objective

Generate a skill from API documentation, then use it to implement a user authentication endpoint.

## Context

You are building a REST API for a web application. You need to implement user authentication following the API specification provided in the sources.

## Task Steps

1. **Review API documentation** in the `sources/` directory
2. **Generate a skill** that captures API patterns and best practices
3. **Implement the authentication endpoint**:
   - POST `/api/auth/login`
   - Accepts JSON body: `{"email": "user@example.com", "password": "secret"}`
   - Returns JWT token on success: `{"token": "eyJ..."}`
   - Returns 401 on invalid credentials: `{"error": "Invalid credentials"}`
   - Includes proper error handling and validation

## Success Criteria

Task is **completed** if:

1. ✅ Endpoint route is correctly defined (`POST /api/auth/login`)
2. ✅ Request body validation is present (checks email and password)
3. ✅ Authentication logic is implemented (password verification)
4. ✅ JWT token generation is present
5. ✅ Error handling returns appropriate status codes (401 for auth failure)
6. ✅ Response format matches specification

Task is **failed** if:
- ❌ Endpoint is missing or incorrect route
- ❌ No authentication logic (just returns mock token)
- ❌ Missing error handling
- ❌ Response format doesn't match spec

## Verification

Run `verify.py` to check implementation:

```bash
python3 verify.py --implementation <path-to-implementation>
```

Returns:
- Exit code 0 if task completed successfully
- Exit code 1 if task failed with explanation

## Expected Difficulty

- **Baseline Success**: ~22% (agent often forgets error handling or uses incorrect response format)
- **With Skill**: ~85% (skill provides API patterns and validation examples)
- **Domain**: software-engineering
- **Estimated Time**: 5-10 minutes

## Notes

This task tests whether the generated skill effectively captures:
- API endpoint structure
- Request/response patterns
- Error handling conventions
- JWT authentication flow

Baseline agents often produce partial implementations missing critical components like validation or error handling.
