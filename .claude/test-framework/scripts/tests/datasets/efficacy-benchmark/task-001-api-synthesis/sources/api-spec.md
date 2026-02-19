# API Specification: User Authentication

## POST /api/auth/login

Authenticates a user and returns a JWT token.

### Request Body
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

### Response (200 OK)
```json
{
  "token": "eyJhbGciOiJIUz...",
  "expires_in": 3600,
  "user": {
    "id": "user-123",
    "email": "user@example.com"
  }
}
```

### Response (401 Unauthorized)
```json
{
  "error": "Invalid credentials"
}
```

### Implementation Requirements
1. Validate email and password fields
2. Verify password using bcrypt
3. Generate JWT token
4. Return appropriate error codes
