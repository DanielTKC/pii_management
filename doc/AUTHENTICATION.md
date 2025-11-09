# JWT Authentication System

## Overview

Our Rails API uses JWT (JSON Web Tokens) for stateless authentication. This implementation follows Rails 8 best practices using a controller concern pattern.

## Architecture

### Authentication Concern (`app/controllers/concerns/authentication.rb`)

The `Authentication` module is a Rails concern that provides:
- Automatic authentication via `before_action :authenticate`
- JWT encoding and decoding methods
- `current_user` helper for accessing the authenticated user
- `allow_unauthenticated_access` class method to skip authentication on specific actions

### How It Works

1. **Including the Concern**
   ```ruby
   class ApplicationController < ActionController::API
     include Authentication
   end
   ```
   This automatically applies authentication to ALL controllers.

2. **Public Endpoints**
   ```ruby
   class Api::V1::AuthenticationController < ApplicationController
     allow_unauthenticated_access only: [:signup, :login]
   end
   ```
   Use `allow_unauthenticated_access` to skip authentication for public endpoints.

3. **Protected Endpoints**
   ```ruby
   class Api::V1::UsersController < ApplicationController
     # Automatically requires authentication
     def profile
       render json: { user: current_user }
     end
   end
   ```
   By default, all endpoints require a valid JWT token.

## JWT Token Structure

### Payload

```ruby
{
  user_id: 123,
  exp: 1234567890,  # Expiration timestamp (24 hours from creation)
  iat: 1234567890,  # Issued at timestamp
  iss: 'pii_management_api',     # Issuer
  aud: 'pii_management_client'   # Audience
}
```

### Secret Key

The JWT secret is stored in Rails encrypted credentials:
```bash
bin/rails credentials:edit
```

Add:
```yaml
jwt_secret: your_secret_key_here
```

**Never commit the `config/master.key` file to version control!**

## API Usage

### Sign Up

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

### Login

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

### Accessing Protected Endpoints

**Request:**
```bash
curl http://localhost:3000/api/v1/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**Response (Success):**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

**Response (Unauthorized - No Token):**
```json
{
  "error": "Invalid or expired token"
}
```

**Response (Unauthorized - Invalid Token):**
```json
{
  "error": "Invalid or expired token"
}
```

**Response (Unauthorized - User Not Found):**
```json
{
  "error": "User not found"
}
```

## Implementation Details

### Token Expiration

Tokens expire after 24 hours by default. You can customize this when encoding:

```ruby
encode(payload, 1.hour.from_now)  # Expires in 1 hour
```

### Authorization Header Format

The `Authorization` header must use the Bearer scheme:
```
Authorization: Bearer <token>
```

### Authentication Flow

1. Client sends credentials to `/api/v1/login` or `/api/v1/signup`
2. Server validates credentials
3. Server generates JWT token with user_id in payload
4. Server returns token to client
5. Client stores token (localStorage, secure cookie, etc.)
6. Client includes token in `Authorization` header for subsequent requests
7. Server validates token on each protected request
8. Server sets `@current_user` if token is valid
9. Server rejects request with 401 if token is invalid/expired

### Security Features

- **Encrypted Credentials**: JWT secret stored in encrypted credentials
- **Token Expiration**: Tokens automatically expire after 24 hours
- **HS256 Algorithm**: Industry-standard HMAC-SHA256 signing
- **Stateless**: No session storage required
- **Password Hashing**: BCrypt with `has_secure_password`
- **Case-Insensitive Email**: Emails normalized to lowercase

## Testing

### Testing Public Endpoints

```ruby
RSpec.describe 'Authentication API', type: :request do
  it 'allows signup without authentication' do
    post '/api/v1/signup', params: {
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    }, as: :json

    expect(response).to have_http_status(:created)
  end
end
```

### Testing Protected Endpoints

```ruby
RSpec.describe 'User Profile API', type: :request do
  let(:user) { create(:user) }
  let(:auth_controller) { Api::V1::AuthenticationController.new }

  def generate_token(user)
    payload = { user_id: user.id }
    auth_controller.send(:encode, payload)
  end

  it 'requires authentication' do
    token = generate_token(user)
    get '/api/v1/profile', headers: { 'Authorization' => "Bearer #{token}" }

    expect(response).to have_http_status(:ok)
  end

  it 'rejects requests without token' do
    get '/api/v1/profile'

    expect(response).to have_http_status(:unauthorized)
  end
end
```

## Common Issues

### "Invalid or expired token"

**Causes:**
- Token is malformed
- Token signature is invalid
- Token has expired
- JWT secret has changed
- No token provided

**Solutions:**
- Request a new token via `/api/v1/login`
- Check that `Authorization` header is formatted correctly
- Verify JWT secret matches between encoding and decoding

### "User not found"

**Causes:**
- Token is valid but user_id doesn't exist in database
- User was deleted after token was issued

**Solutions:**
- Request a new token
- Verify user exists in database

### Tests failing with authentication errors

**Causes:**
- Missing JWT secret in test credentials
- Not including `Authorization` header in test requests
- Using wrong token generation method

**Solutions:**
- Ensure credentials include `jwt_secret`
- Use helper method to generate valid tokens in tests
- Include `headers: { 'Authorization' => "Bearer #{token}" }` in requests

## Differences from lib/json_web_token.rb

We originally had `lib/json_web_token.rb` as a standalone class. The new implementation:

1. **Location**: `app/controllers/concerns/authentication.rb` (Rails concern)
2. **Secret**: Uses `Rails.application.credentials.jwt_secret` instead of `secret_key_base`
3. **Integration**: Automatically applied to all controllers via `ApplicationController`
4. **Helpers**: Provides `current_user` and `allow_unauthenticated_access`
5. **Authentication**: Automatically checks tokens on every request (unless skipped)
6. **Additional Claims**: Adds `iat`, `iss`, `aud` to JWT payload

The old `lib/json_web_token.rb` file can be deleted as it's no longer used.

## References

- [JWT.io](https://jwt.io/) - JWT standard and debugger
- [Ruby JWT Gem](https://github.com/jwt/ruby-jwt) - Implementation we use
- [Rails Concerns](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html) - Pattern documentation
- [has_secure_password](https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html) - Password hashing
- [Rails 8 Authentication but with JWT](https://dev.to/ruwhan/part-1-rails-8-authentication-but-with-jwt-2if6)