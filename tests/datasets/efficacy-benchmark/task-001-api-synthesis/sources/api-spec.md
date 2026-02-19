# API Specification: User Authentication

## Authentication Endpoint

### POST /api/auth/login

Authenticates a user and returns a JWT token.

#### Request

**Headers**:
```
Content-Type: application/json
```

**Body** (JSON):
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

**Validation Rules**:
- `email`: Required, must be valid email format
- `password`: Required, minimum 8 characters

#### Response

**Success (200 OK)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": "user-123",
    "email": "user@example.com"
  }
}
```

**Validation Error (400 Bad Request)**:
```json
{
  "error": "Validation failed",
  "details": {
    "email": "Invalid email format",
    "password": "Password must be at least 8 characters"
  }
}
```

**Authentication Failed (401 Unauthorized)**:
```json
{
  "error": "Invalid credentials"
}
```

**Server Error (500 Internal Server Error)**:
```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

#### Implementation Notes

1. **Password Verification**: Use bcrypt or similar secure hashing
2. **JWT Token**: Include user ID and email in payload, set expiration
3. **Rate Limiting**: Consider implementing rate limiting for security
4. **Logging**: Log authentication attempts (success and failure)

#### Example Implementation (Express.js)

```javascript
router.post('/api/auth/login', async (req, res) => {
  try {
    // 1. Validate request body
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: "Validation failed",
        details: { email: "Email is required", password: "Password is required" }
      });
    }

    // 2. Find user by email
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // 3. Verify password
    const isValid = await bcrypt.compare(password, user.passwordHash);

    if (!isValid) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // 4. Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    // 5. Return success response
    res.json({
      token,
      expires_in: 3600,
      user: {
        id: user.id,
        email: user.email
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: "Internal server error" });
  }
});
```

## Security Considerations

1. **Never log passwords**: Ensure passwords are not included in logs
2. **Constant-time comparison**: Prevent timing attacks during password verification
3. **Rate limiting**: Limit failed login attempts to prevent brute force
4. **HTTPS only**: Authentication endpoints must use HTTPS in production
5. **Token expiration**: JWT tokens should have reasonable expiration (1-24 hours)

## Testing

Example test cases:

```javascript
describe('POST /api/auth/login', () => {
  it('returns token for valid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password123' });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body.user.email).toBe('test@example.com');
  });

  it('returns 401 for invalid password', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'wrongpassword' });

    expect(response.status).toBe(401);
    expect(response.body.error).toBe('Invalid credentials');
  });

  it('returns 400 for missing email', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ password: 'password123' });

    expect(response.status).toBe(400);
    expect(response.body.error).toBe('Validation failed');
  });
});
```
