# Task: Comprehensive Test Suite Implementation

## Objective

Generate a skill from testing best practices documentation, then write a comprehensive test suite for a user authentication module.

## Context

You are developing a user authentication system. You need to write a complete test suite covering unit tests, integration tests, and edge cases.

## Task Steps

1. **Review testing documentation** in the `sources/` directory
2. **Generate a testing skill** that captures test patterns and best practices
3. **Write a comprehensive test suite** that includes:
   - Unit tests for individual functions
   - Integration tests for the authentication flow
   - Edge cases (invalid inputs, expired tokens, etc.)
   - Security tests (SQL injection, XSS prevention)
   - Mock/stub external dependencies

## Success Criteria

Task is **completed** if:

1. ✅ Includes unit tests for core functions (validatePassword, generateToken, etc.)
2. ✅ Includes integration tests for full authentication flow
3. ✅ Tests edge cases (empty input, malformed data, boundary conditions)
4. ✅ Tests error handling (invalid credentials, expired tokens)
5. ✅ Mocks external dependencies (database, email service)
6. ✅ Uses appropriate test framework syntax
7. ✅ Test descriptions are clear and specific

Task is **failed** if:
- ❌ Only happy path tests (no edge cases)
- ❌ No mocking of external dependencies
- ❌ Missing integration tests
- ❌ Test descriptions are vague
- ❌ Security concerns not tested

## Expected Difficulty

- **Baseline Success**: ~28% (agents often write only basic happy path tests)
- **With Skill**: ~80% (skill provides test pattern templates and edge case checklist)
- **Domain**: software-engineering
- **Estimated Time**: 10-15 minutes

## Module to Test

**Authentication Module** with functions:
- `validatePassword(password)`: Checks password strength
- `hashPassword(password)`: Hashes password with bcrypt
- `generateToken(userId)`: Creates JWT token
- `verifyToken(token)`: Validates JWT token
- `authenticateUser(email, password)`: Full authentication flow

## Notes

This task tests whether the generated skill effectively captures:
- AAA pattern (Arrange, Act, Assert)
- Test coverage completeness (unit + integration + edge cases)
- Mocking strategies for external dependencies
- Security testing patterns
- Clear test descriptions

Baseline agents often produce shallow test suites with only happy path coverage.
