# Testing Best Practices

## Test Structure: AAA Pattern

Use the Arrange-Act-Assert pattern for clear, maintainable tests:

```javascript
describe('validatePassword', () => {
  it('should return true for valid password with 8+ chars, uppercase, lowercase, and number', () => {
    // Arrange
    const password = 'SecurePass123';

    // Act
    const result = validatePassword(password);

    // Assert
    expect(result).toBe(true);
  });
});
```

## Test Pyramid

Structure your test suite following the test pyramid:

```
     /\
    /  \    E2E Tests (Few)
   /    \
  /      \  Integration Tests (Some)
 /        \
/__________\ Unit Tests (Many)
```

### Unit Tests (70%)

Test individual functions in isolation:

```javascript
describe('hashPassword', () => {
  it('should return a bcrypt hash', () => {
    const password = 'password123';
    const hash = hashPassword(password);

    expect(hash).toMatch(/^\$2[ayb]\$.{56}$/);
  });

  it('should generate different hashes for same password', () => {
    const password = 'password123';
    const hash1 = hashPassword(password);
    const hash2 = hashPassword(password);

    expect(hash1).not.toBe(hash2);
  });
});
```

### Integration Tests (20%)

Test multiple components working together:

```javascript
describe('authenticateUser', () => {
  beforeEach(async () => {
    await db.users.create({
      email: 'test@example.com',
      passwordHash: await hashPassword('SecurePass123')
    });
  });

  it('should return token for valid credentials', async () => {
    const result = await authenticateUser('test@example.com', 'SecurePass123');

    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
    expect(result.token).toMatch(/^eyJ/);  // JWT format
  });

  it('should return error for invalid password', async () => {
    const result = await authenticateUser('test@example.com', 'WrongPass');

    expect(result.success).toBe(false);
    expect(result.error).toBe('Invalid credentials');
  });
});
```

### E2E Tests (10%)

Test full user flows:

```javascript
describe('Authentication Flow', () => {
  it('should allow user to sign up, log in, and access protected resource', async () => {
    // Sign up
    const signupResponse = await request(app)
      .post('/api/auth/signup')
      .send({ email: 'new@example.com', password: 'SecurePass123' });
    expect(signupResponse.status).toBe(201);

    // Log in
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({ email: 'new@example.com', password: 'SecurePass123' });
    expect(loginResponse.status).toBe(200);
    const token = loginResponse.body.token;

    // Access protected resource
    const profileResponse = await request(app)
      .get('/api/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(profileResponse.status).toBe(200);
  });
});
```

## Edge Cases and Error Handling

### Boundary Testing

```javascript
describe('validatePassword', () => {
  it('should reject password shorter than 8 characters', () => {
    expect(validatePassword('Short1')).toBe(false);
  });

  it('should accept password with exactly 8 characters', () => {
    expect(validatePassword('Valid123')).toBe(true);
  });

  it('should reject password without uppercase letter', () => {
    expect(validatePassword('lowercase123')).toBe(false);
  });

  it('should reject password without number', () => {
    expect(validatePassword('NoNumbers')).toBe(false);
  });
});
```

### Null/Undefined Handling

```javascript
describe('authenticateUser', () => {
  it('should handle null email', async () => {
    const result = await authenticateUser(null, 'password');
    expect(result.success).toBe(false);
    expect(result.error).toContain('email');
  });

  it('should handle undefined password', async () => {
    const result = await authenticateUser('test@example.com', undefined);
    expect(result.success).toBe(false);
    expect(result.error).toContain('password');
  });

  it('should handle empty strings', async () => {
    const result = await authenticateUser('', '');
    expect(result.success).toBe(false);
  });
});
```

### Malformed Input

```javascript
describe('verifyToken', () => {
  it('should reject malformed token', () => {
    expect(() => verifyToken('not.a.jwt')).toThrow('Invalid token format');
  });

  it('should reject expired token', () => {
    const expiredToken = generateToken(123, { expiresIn: '0s' });
    expect(() => verifyToken(expiredToken)).toThrow('Token expired');
  });

  it('should reject token with invalid signature', () => {
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyM30.fakesignature';
    expect(() => verifyToken(token)).toThrow('Invalid signature');
  });
});
```

## Mocking External Dependencies

### Database Mocking

```javascript
import { jest } from '@jest/globals';

describe('authenticateUser', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should query database for user', async () => {
    const mockUser = {
      id: 1,
      email: 'test@example.com',
      passwordHash: '$2a$10$...'
    };

    const mockFindOne = jest.spyOn(db.users, 'findOne')
      .mockResolvedValue(mockUser);

    await authenticateUser('test@example.com', 'password');

    expect(mockFindOne).toHaveBeenCalledWith({
      where: { email: 'test@example.com' }
    });
  });

  it('should handle database connection error', async () => {
    jest.spyOn(db.users, 'findOne')
      .mockRejectedValue(new Error('Connection refused'));

    const result = await authenticateUser('test@example.com', 'password');

    expect(result.success).toBe(false);
    expect(result.error).toContain('Database error');
  });
});
```

### External API Mocking

```javascript
describe('sendVerificationEmail', () => {
  it('should call email service with correct parameters', async () => {
    const mockSend = jest.spyOn(emailService, 'send')
      .mockResolvedValue({ messageId: 'abc123' });

    await sendVerificationEmail('user@example.com', 'verify-token-xyz');

    expect(mockSend).toHaveBeenCalledWith({
      to: 'user@example.com',
      subject: 'Verify your email',
      body: expect.stringContaining('verify-token-xyz')
    });
  });

  it('should retry on email service failure', async () => {
    const mockSend = jest.spyOn(emailService, 'send')
      .mockRejectedValueOnce(new Error('Service unavailable'))
      .mockResolvedValueOnce({ messageId: 'abc123' });

    await sendVerificationEmail('user@example.com', 'token');

    expect(mockSend).toHaveBeenCalledTimes(2);
  });
});
```

## Security Testing

### SQL Injection Prevention

```javascript
describe('authenticateUser SQL Injection', () => {
  it('should safely handle SQL injection attempt in email', async () => {
    const maliciousEmail = "'; DROP TABLE users; --";

    // Should not throw error, should safely query
    const result = await authenticateUser(maliciousEmail, 'password');

    expect(result.success).toBe(false);

    // Verify users table still exists
    const users = await db.users.findAll();
    expect(users).toBeDefined();
  });
});
```

### XSS Prevention

```javascript
describe('User Input Sanitization', () => {
  it('should escape HTML in user-provided fields', () => {
    const xssAttempt = '<script>alert("XSS")</script>';
    const sanitized = sanitizeInput(xssAttempt);

    expect(sanitized).not.toContain('<script>');
    expect(sanitized).toBe('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;');
  });
});
```

### Rate Limiting

```javascript
describe('Authentication Rate Limiting', () => {
  it('should block after 5 failed login attempts', async () => {
    for (let i = 0; i < 5; i++) {
      await authenticateUser('test@example.com', 'wrongpassword');
    }

    const result = await authenticateUser('test@example.com', 'wrongpassword');

    expect(result.success).toBe(false);
    expect(result.error).toContain('Too many failed attempts');
  });
});
```

## Test Descriptions

### Good vs Bad

**Bad** (vague):
```javascript
it('works', () => { ... });
it('returns correct value', () => { ... });
```

**Good** (specific):
```javascript
it('should return true when password contains uppercase, lowercase, number, and 8+ chars', () => { ... });
it('should return JWT token with userId in payload when credentials are valid', () => { ... });
```

## Test Coverage

Aim for:
- **Statements**: 80%+
- **Branches**: 75%+
- **Functions**: 90%+
- **Lines**: 80%+

```bash
# Generate coverage report
npm test -- --coverage

# View detailed report
open coverage/lcov-report/index.html
```

## Common Testing Patterns

### Test Fixtures

```javascript
const fixtures = {
  validUser: {
    email: 'valid@example.com',
    password: 'SecurePass123',
    passwordHash: '$2a$10$...'
  },
  invalidUser: {
    email: 'invalid@example.com',
    password: 'wrong'
  }
};

describe('authenticateUser', () => {
  it('should authenticate valid user', async () => {
    const result = await authenticateUser(
      fixtures.validUser.email,
      fixtures.validUser.password
    );
    expect(result.success).toBe(true);
  });
});
```

### Parameterized Tests

```javascript
describe.each([
  ['short', false],
  ['nouppercase1', false],
  ['NOLOWERCASE1', false],
  ['NoNumbers', false],
  ['ValidPass123', true]
])('validatePassword(%s)', (password, expected) => {
  it(`should return ${expected}`, () => {
    expect(validatePassword(password)).toBe(expected);
  });
});
```

## Quick Reference Checklist

For each module:
- [ ] Unit tests for all public functions
- [ ] Integration tests for workflows
- [ ] Edge cases (null, undefined, empty, boundary)
- [ ] Error handling tests
- [ ] Mock external dependencies
- [ ] Security tests (injection, XSS, rate limiting)
- [ ] Clear, specific test descriptions
- [ ] Setup and teardown (beforeEach, afterEach)
- [ ] Coverage report > 80%
