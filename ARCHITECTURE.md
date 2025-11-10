# System Architecture

## Overview

The PII Management System is a microservices-based application designed to securely collect, store, and manage Personally Identifiable Information (PII). The system follows a defense-in-depth security approach with multiple layers of validation and encryption.

## Design Decisions (Docker)

I spend a fair amount of time getting the services stubbed out so I could dockerize the entire app. I could not be happier how that turned out. However, I will be the first to acknowledge that the traffic is currently traveling with the security of http between the frontend, the api, the java service, and the unencrypted postgres protocol. This brings me to the exact reason why i dockerized the app, because I would use KAMAL to secure it for production (or anything internet facing). Kamal offers a built-in proxy that handles all TLS with automatic Let's Encrypt certificates. It only opens ports 80 and 443 to external traffic, leaving our ports safely behind a proxy.





## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Browser                              │
│                     http://localhost:5173                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP/REST
                             │ (proxied through Vite)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    React Frontend (Vite)                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  - React 19 + React Router                               │  │
│  │  - React Hook Form for validation                        │  │
│  │  - Tailwind CSS v4                                       │  │
│  │  - JWT token management                                  │  │
│  │  - SSN auto-formatting & masking                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                       Port: 5173                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP/REST + JWT
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Rails API (Puma)                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Controllers:                                             │  │
│  │  - AuthenticationController (signup, login)               │  │
│  │  - PiiRecordsController (CRUD)                           │  │
│  │                                                           │  │
│  │  Services:                                                │  │
│  │  - SsnValidator (format validation)                      │  │
│  │  - JavaSsnClient (HTTP client, 3 retries, 5s timeout)   │  │
│  │                                                           │  │
│  │  Models:                                                  │  │
│  │  - User (authentication)                                  │  │
│  │  - PiiRecord (PII storage)                               │  │
│  │  - AuditLog (access tracking)                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                       Port: 3000                                 │
└────────────┬──────────────────────────────┬─────────────────────┘
             │                              │
             │ HTTP                         │ SQL
             │ POST /api/ssn/process        │
             ▼                              ▼
┌─────────────────────────────┐  ┌──────────────────────────────┐
│   Java Service (Tomcat)     │  │   PostgreSQL 17              │
│  ┌────────────────────────┐ │  │  ┌────────────────────────┐ │
│  │ Controllers:            │ │  │  │  Tables:               │ │
│  │ - SsnController        │ │  │  │  - users               │ │
│  │                        │ │  │  │  - pii_records         │ │
│  │ Services:              │ │  │  │  - audit_logs          │ │
│  │ - SsnValidationService│ │  │  │                        │ │
│  │ - SsnEncryptionService│ │  │  │  Encryption:           │ │
│  │                        │ │  │  │  - encrypted_ssn (TEXT)│ │
│  │ Encryption:            │ │  │  │  - ssn_last_four (4)   │ │
│  │ - AES-256-GCM         │ │  │  └────────────────────────┘ │
│  │ - Random IV per op    │ │  │         Port: 5432           │
│  └────────────────────────┘ │  └──────────────────────────────┘
│        Port: 8080           │
└─────────────────────────────┘

All services run in Docker containers connected via 'pii_network'
```

## Service Communication Flow

### 1. User Signup/Login
```
User → React Frontend → POST /api/v1/signup → Rails API
                                               ↓
                                        Generate JWT token
                                               ↓
                                        Return token + user
React Frontend ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
   ↓
Store JWT in localStorage
```

### 2. PII Record Creation
```
User fills form → React validates → POST /api/v1/pii_records + JWT
                                    ↓
                            Rails API authenticates JWT
                                    ↓
                            Validates SSN format (SsnValidator)
                                    ↓
                            POST /api/ssn/process → Java Service
                                                     ↓
                                              Validates SSN again
                                                     ↓
                                              Encrypts with AES-256-GCM
                                                     ↓
                                              Returns: {
                                                encryptedSsn: "...",
                                                lastFour: "1234",
                                                valid: true
                                              }
Rails API ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
   ↓
Save to PostgreSQL:
  - encrypted_ssn
  - ssn_last_four
  - Other PII fields
   ↓
Return success → React Frontend → Display "Record created"
```

### 3. PII Record Display
```
React Frontend → GET /api/v1/pii_records + JWT
                 ↓
           Rails API queries PostgreSQL
                 ↓
           Returns records with:
             - Full PII data
             - ssn_last_four only
             - encrypted_ssn NOT sent to frontend
                 ↓
React Frontend ← ┘
   ↓
Display SSN as: ***-**-XXXX (using ssn_last_four)
```

## Security Implementation

### 1. SSN Encryption (AES-256-GCM)

**Encryption Process:**
```
Plain SSN: "123-45-6789"
    ↓
Generate random 12-byte IV (Initialization Vector)
    ↓
Encrypt using AES-256-GCM:
  - Algorithm: AES/GCM/NoPadding
  - Key size: 256 bits
  - IV size: 96 bits (12 bytes)
  - Authentication tag: 128 bits
    ↓
Output format: Base64(IV + Ciphertext + Auth Tag)
    ↓
Stored in database as TEXT
```

**Key Management:**
- Key stored in environment variable `ENCRYPTION_KEY`
- Base64-encoded 32-byte key
- Generated via: `openssl rand -base64 32`

### 2. Independent Validation

**Defense in Depth Strategy:**

Both Rails and Java validate SSN independently:

1. **Client-side (React)**:
   - Format validation (XXX-XX-XXXX)
   - Real-time feedback
   - User experience optimization

2. **Rails API**:
   - SsnValidator service
   - Format and business rules
   - Gateway validation before encryption

3. **Java Service**:
   - SsnValidationService
   - Independent validation before encryption
   - Prevents encryption of invalid data


### 4. Data Protection

**At Rest:**
- SSN encrypted with AES-256-GCM
- Passwords hashed with BCrypt (Rails default)
- Database accessible only within Docker network

**In Transit:**
- Development: HTTP (production would use KAMAL for  HTTPS/TLS)
- CORS configured to allow only React frontend origin
- JWT tokens prevent CSRF attacks

**In Logs:**
- SSN filtered from Rails logs (config.filter_parameters)
- Error messages sanitized to not expose SSN

### 5. CORS Configuration

```ruby
# rails-api/config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5173", "http://127.0.0.1:5173"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────┐
│     users       │
├─────────────────┤
│ id (PK)         │
│ email           │◄─────────┐
│ password_digest │          │
│ created_at      │          │
│ updated_at      │          │
└─────────────────┘          │
                             │
                             │ user_id (FK)
┌─────────────────┐          │
│  pii_records    │          │
├─────────────────┤          │
│ id (PK)         │          │
│ user_id (FK)    │──────────┘
│ first_name      │
│ middle_name     │
│ last_name       │
│ encrypted_ssn   │ ◄── AES-256-GCM encrypted
│ ssn_last_four   │ ◄── For display only (***-**-XXXX)
│ email           │
│ phone           │
│ street_address_1│
│ street_address_2│
│ city            │
│ state           │
│ zip_code        │
│ middle_name_override │
│ deleted_at      │ ◄── Soft delete timestamp
│ created_at      │
│ updated_at      │
└─────────────────┘
          │
          │ auditable_id (polymorphic FK)
          ▼
┌─────────────────┐
│   audit_logs    │
├─────────────────┤
│ id (PK)         │
│ auditable_type  │ ◄── Polymorphic (PiiRecord, User)
│ auditable_id    │
│ user_id (FK)    │
│ action          │ ◄── create, read, update, delete
│ changes         │ ◄── JSONB (what changed)
│ ip_address      │
│ user_agent      │
│ created_at      │
└─────────────────┘
```

### Table Details

**users**
- Primary authentication table
- BCrypt password hashing
- email must be unique
- Indexes: email (unique)

**pii_records**
- Core PII storage
- `encrypted_ssn`: Base64 string (IV + ciphertext + auth tag)
- `ssn_last_four`: String(4) for display purposes
- `deleted_at`: Soft delete (NOT NULL = deleted)
- `middle_name_override`: Boolean (if true, middle_name = "N/A")
- Indexes: user_id, deleted_at, created_at

**audit_logs** (schema exists, not fully implemented)
- Polymorphic association (can track any model)
- Records all CRUD operations on PII
- Stores before/after changes in JSONB
- Indexes: auditable_type + auditable_id, user_id, created_at

## Technology Stack

### Rails API
- **Framework**: Ruby on Rails 8.1.1
- **Ruby Version**: 3.4.7
- **Database**: PostgreSQL 17
- **Server**: Puma
- **Testing**: RSpec, FactoryBot, WebMock
- **Security**: Rack::CORS, BCrypt, rack-attack (planned)
- **Code Quality**: RuboCop, Brakeman, SimpleCov

### Java Service
- **Framework**: Spring Boot 3.4.2
- **Java Version**: 21
- **Encryption**: javax.crypto (AES-256-GCM)
- **Testing**: JUnit 5, Mockito, JaCoCo
- **Server**: Embedded Tomcat
- **Build**: Maven

### React Frontend
- **Framework**: React 19.1.1
- **Build Tool**: Vite 7.1.7
- **Routing**: React Router 7.1.1
- **Forms**: React Hook Form 7.53.2
- **Styling**: Tailwind CSS 4.1.17
- **Testing**: Vitest 2.1.8, Testing Library
- **HTTP Client**: Fetch API (via api.js service)

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Database**: PostgreSQL 17-alpine
- **Networking**: Docker bridge network (`pii_network`)
- **Health Checks**: Docker HEALTHCHECK for all services


### Optimization Opportunities
1. **Caching**: Add Redis for Rails fragment/page caching
2. **Async Encryption**: Use Sidekiq for background encryption jobs



## Testing Strategy

### Unit Tests
- **Rails**: RSpec for models, services, validators
- **Java**: JUnit 5 for services, utilities
- **React**: Vitest for components, utilities

### Integration Tests
- **Rails**: Request specs for API endpoints
- **Java**: Integration tests for controllers
- **End-to-End**: Manual testing of full flow



### Test Data Management
- **Rails**: FactoryBot for test fixtures
- **Java**: Builder pattern for test objects
- **React**: Testing Library for component rendering


### Health Checks
- **Rails**: `/up` endpoint (Rails default)
- **Java**: Spring Boot Actuator `/actuator/health`
- **PostgreSQL**: Docker HEALTHCHECK with `pg_isready`
- **React**: Vite dev server status

## Security Compliance

### Standards Considered
- **NIST**: AES-256-GCM encryption

