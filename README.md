# PII Management System

A secure, full-stack application for managing Personally Identifiable Information (PII) with enterprise-grade encryption and validation.

## System Overview

This application consists of three microservices:
- **Rails API** (Port 3000) - RESTful API for PII data management
- **Java Microservice** (Port 8080) - SSN validation and AES-256 encryption service
- **React Frontend** (Port 5173) - Single-page application for data entry and display
- **PostgreSQL** (Port 5432) - Database for persistent storage

## Prerequisites

- Docker and Docker Compose
- Git

## Quick Start

Make sure you have docker installed and running on your computer
https://www.docker.com/get-started/

### 1. Clone the Repository
```bash
git clone https://github.com/DanielTKC/pii_management.git
cd pii_management
```

### 2. Environment Setup
```bash
# Copy the example environment file
cp .env.example .env

# ⚠️  NOTE FOR CODE REVIEWERS:
# The .env.example file contains ACTUAL WORKING VALUES for demo purposes.
# These are NOT real production secrets - this is a code challenge demonstration.
# Simply copy .env.example to .env and you're ready to go!

# No need to generate new secrets - the demo values will work immediately
# (In production, you would generate new secrets and use a secrets manager)
```

### 3. Start All Services
```bash
# Start all services with Docker Compose
docker compose up
```

## 4. Access the Application
- **React Frontend**: http://localhost:5173

**First-time setup**: The first run will take several minutes as Docker builds the images and installs dependencies.

### 5. Database Setup
The database will be automatically created and migrated on first run. If you need to manually run migrations:

```bash
docker compose exec rails-api bundle exec rails db:create
docker compose exec rails-api bundle exec rails db:migrate
```




## On Use of AI
Claude code was used throughout development of this application beginning with analyzing the code challenge document provided to me. That document was used to create an implementaion plan that can be found in the doc directory. That plan was used as a general guideline to follow while developing. Developing up a todo list makes a large project very manageable. It takes a mountain and turns it into a series of small steps.

 I try to develop in the style of "Red, green, refactor" TDD as much as possible and when it comes to writing the tests, Claude is invaluable. It takes the requirements, writes a litany of tests that fail, and gives me (the developer) a very clear target to work towards in writing code to pass those tests.

 There was one or two times where I couldn't find the answer to an error that had me stuck (specific config hosts for tests in rails 8 is something I had yet to come across in my career), rather than waste 30 minutes trying to figure out what question to ask, I can get right back to work with the aid of an LLM.

 Claude wants me to type that AI is a "force-multiplier" but I'm just going to have to reign the computer in on that one. It isn't wrong, but "force-multiplier" was the name of a Dennis Rodman movie in the 90's I think. Instead, I'll just say that letting AI handle routine tasks let's me focus on delivering better product, faster.


## Service-Specific Setup

### Rails API

**Run Rails Console:**
```bash
docker compose exec rails-api bundle exec rails console
```

**Run Migrations:**
```bash
docker compose exec rails-api bundle exec rails db:migrate
```

**Reset Database:**
```bash
docker compose exec rails-api bundle exec rails db:reset
```

**Run Tests:**
```bash
# All tests
docker compose exec rails-api bundle exec rspec

# Specific test file
docker compose exec rails-api bundle exec rspec spec/models/pii_record_spec.rb

# With coverage report
docker compose exec rails-api bundle exec rspec
# View coverage at rails-api/coverage/index.html
```


### Java Microservice

**Run Tests:**
```bash
docker compose exec java-service mvn test

# With coverage
docker compose exec java-service mvn clean test jacoco:report
# View coverage at java-service/target/site/jacoco/index.html
```

**Rebuild:**
```bash
docker compose exec java-service mvn clean install
```

**View Logs:**
```bash
docker compose logs java-service -f
```

### React Frontend

**Run Tests:**
```bash
# All tests
docker compose exec react-frontend npm test -- --run

# Watch mode
docker compose exec react-frontend npm test

# With coverage
docker compose exec react-frontend npm test -- --coverage
```

**Linting:**
```bash
docker compose exec react-frontend npm run lint
```


## Running Tests for All Services

```bash
# Rails tests
docker compose exec rails-api bundle exec rspec

# Java tests
docker compose exec java-service mvn test

# React tests
docker compose exec react-frontend npm test -- --run
```
## Complete API Flow Example

  Complete API Flow Examples

  1. Sign Up (Create New Account)

  curl -X POST http://localhost:3000/api/v1/signup \
    -H "Content-Type: application/json" \
    -d '{"email":"demo@example.com","password":"password123"}'

  Response (200 OK):
  {
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoyLCJleHAiOjE3Nj
  I4NjY3MTIsImlhdCI6MTc2Mjc4MDMxMiwiaXNzIjoicGlpX21hbmFnZW1lbnRfY
  XBpIiwiYXVkIjoicGlpX21hbmFnZW1lbnRfY2xpZW50In0.uYQKvgdv8m-Ip--g
  b1xJmEpwTNKBhBnwldAVZTO6LbA",
    "user": {
      "id": 2,
      "email": "demo@example.com"
    }
  }

  2. Login (Existing Account)

  curl -X POST http://localhost:3000/api/v1/login \
    -H "Content-Type: application/json" \
    -d '{"email":"demo@example.com","password":"password123"}'

  Response: Same as signup - returns token + user object

  3. Get All PII Records (WITH Token - Success)

  curl http://localhost:3000/api/v1/pii_records \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIj
  oyLCJleHAiOjE3NjI4NjY3MTIsImlhdCI6MTc2Mjc4MDMxMiwiaXNzIjoicGlpX
  21hbmFnZW1lbnRfYXBpIiwiYXVkIjoicGlpX21hbmFnZW1lbnRfY2xpZW50In0.
  uYQKvgdv8m-Ip--gb1xJmEpwTNKBhBnwldAVZTO6LbA"

  Response (200 OK):
  [
    {
      "id": 1,
      "first_name": "Toilet",
      "middle_name": "N/A",
      "last_name": "Man",
      "ssn": "***-**-4102",
      "date_of_birth": null,
      "email": "d@toilet.com",
      "phone": "914-303-4434",
      "street_address_1": "1234",
      "street_address_2": "",
      "city": "fake",
      "state": "UT",
      "zip_code": "84124",
      "created_at": "2025-11-10T13:07:50.439Z",
      "updated_at": "2025-11-10T13:07:50.439Z"
    }
  ]

  Note: SSN is obfuscated as ***-**-4102 (only last 4 shown)

  4. Get PII Records (WITHOUT Token - Failure)

  curl http://localhost:3000/api/v1/pii_records

  Response (401 Unauthorized):
  {
    "error": "Invalid or expired token"
  }

  5. Create New PII Record

  curl -X POST http://localhost:3000/api/v1/pii_records \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer YOUR_TOKEN_HERE" \
    -d '{
      "first_name": "John",
      "last_name": "Doe",
      "ssn": "234-56-7890",
      "email": "john@example.com",
      "phone": "555-1234",
      "street_address_1": "123 Main St",
      "city": "Portland",
      "state": "OR",
      "zip_code": "97201"
    }'

  6. Get Single PII Record

  curl http://localhost:3000/api/v1/pii_records/1 \
    -H "Authorization: Bearer YOUR_TOKEN_HERE"

  7. Update PII Record

  curl -X PUT http://localhost:3000/api/v1/pii_records/1 \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer YOUR_TOKEN_HERE" \
    -d '{"phone": "555-9999"}'

  8. Delete PII Record

  curl -X DELETE http://localhost:3000/api/v1/pii_records/1 \
    -H "Authorization: Bearer YOUR_TOKEN_HERE"
## Features

### Authentication & Authorization
- User signup and login with JWT tokens
- Protected API endpoints
- Secure session management

### PII Record Management
- Create, read, update, and delete PII records
- Required fields: First name, Last name, SSN, Street address, City, State, ZIP code
- Optional fields: Middle name, Email, Phone, Address line 2

### SSN Security
- Client-side SSN format validation (XXX-XX-XXXX)
- Server-side SSN validation (Rails)
- Independent SSN validation in Java service
- AES-256-GCM encryption via Java microservice
- Only last 4 digits stored for display purposes
- SSN always displayed as masked (***-**-XXXX)

### Validation Rules
SSN validation checks for:
- Correct format: XXX-XX-XXXX
- Area number: NOT 000, NOT 666
- Group number: NOT 00
- Serial number: NOT 0000
- Known invalid SSNs (e.g., 078-05-1120, 123-45-6789)

### Form Features
- Auto-formatting for SSN input
- Middle name override checkbox ("N/A" for no middle name)
- US state dropdown (all 50 states)
- Email and ZIP code format validation
- Real-time validation feedback

## Architecture Highlights

### Service Communication Flow
1. React app sends PII data to Rails API
2. Rails validates SSN using `SsnValidator` service
3. Rails calls Java service to encrypt SSN
4. Java independently validates SSN
5. Java encrypts SSN with AES-256-GCM
6. Rails stores encrypted SSN + last 4 digits in PostgreSQL
7. Display shows obfuscated SSN (***-**-XXXX)

### Security Features
- JWT-based authentication
- SSN encryption at rest (AES-256-GCM)
- SSN filtering from Rails logs
- CORS configuration for API security
- Independent validation in multiple services
- Random IV per encryption operation

### Database
- PostgreSQL 17 with three main tables:
  - `users` - Authentication
  - `pii_records` - Encrypted PII storage
  - `audit_logs` - Access tracking (planned)
- Soft deletes via `deleted_at` timestamp

## Testing Fresh Installation

To simulate a fresh installation (like a hiring manager would experience):

```bash
# Run the automated clean test script
./scripts/clean-test.sh
```

This script will:
1. Stop and remove all containers/volumes
2. Remove Docker images
3. Verify .env exists (creates from .env.example if needed)
4. Rebuild everything from scratch
5. Start all services
6. Check health status

**Expected result:** All services healthy and accessible at their ports.

## Troubleshooting

### Database init.sql error
**Error:** `docker-entrypoint-initdb.d/init.sql: is a directory`

**Fix:** This has been resolved in docker-compose.yml. If you still see it:
```bash
ls -la db/
# Should show db/init-db.sql (not init.sql)
```

### Services won't start
```bash
# Check service logs
docker compose logs [service-name]

# Restart a specific service
docker compose restart [service-name]

# Complete clean rebuild
./scripts/clean-test.sh
```

### Database issues
```bash
# Reset database
docker compose exec rails-api bundle exec rails db:reset

# Check database connection
docker compose exec rails-api bundle exec rails db:version
```

### Port conflicts
If ports 3000, 5173, 8080, or 5432 are already in use, edit the `.env` file to use different ports.

### React app not connecting to API
- Verify Rails API is running: `docker compose ps`
- Check Rails logs: `docker compose logs rails-api`
- Ensure CORS is enabled in `rails-api/config/initializers/cors.rb`

## Development Workflow

### Making Changes

**Rails API:**
- Changes to code are live-reloaded (Rails development mode)
- After Gemfile changes: `docker compose restart rails-api`
- After migrations: `docker compose exec rails-api bundle exec rails db:migrate`

**Java Service:**
- Running in dev mode with hot reload
- Rebuild if needed: `docker compose exec java-service mvn clean install`

**React Frontend:**
- Vite HMR (Hot Module Replacement) provides instant updates
- No restart needed for most changes
- After package.json changes: `docker compose restart react-frontend`

### Code Quality

All services include linting and testing:
- Rails: RSpec + RuboCop + Brakeman
- Java: JUnit 5 + Mockito + JaCoCo
- React: Vitest + ESLint

## Assumptions & Trade-offs

### Assumptions
1. **Development Environment**: Optimized for local development with Docker
2. **Authentication**: Basic JWT implementation (production would need refresh tokens, expiry handling)
3. **SSN Storage**: Encrypted SSN stored as TEXT field (could be optimized with binary storage)
4. **Rate Limiting**: Not implemented (would add Rack::Attack in production)

### Trade-offs
1. **Two Validation Layers**: Both Rails and Java validate SSN independently (defense in depth vs. DRY)
2. **Synchronous Encryption**: SSN encryption is synchronous (could be async for better performance)
3. **Local Storage for JWT**: Using localStorage (would prefer httpOnly cookies in production)
4. **Docker Development**: Trade file system performance for consistency and ease of setup
5. **Test Coverage**: Focused on core functionality over 100% coverage (Rails: ~90%, Java: ~85%)

## Time Spent Summary

This project was developed using Test-Driven Development (TDD) methodology throughout.

### Technical Requirements (~12-15 hours)
- **Rails API setup and PII CRUD** (3-4 hours): Database schema, models, controllers, service objects
- **Java service with encryption** (4-5 hours): Spring Boot setup, AES-256-GCM implementation, validation
- **Service integration** (2-3 hours): HTTP client, retry logic, error handling
- **Database design and migrations** (1-2 hours): PostgreSQL setup, schema design, associations

### Functional Requirements (~8-10 hours)
- **React frontend setup** (2-3 hours): Vite configuration, Tailwind CSS v4, routing
- **Form with validation** (3-4 hours): React Hook Form integration, field validation
- **SSN formatting and masking** (1-2 hours): Auto-formatting, display obfuscation
- **Authentication flow** (2-3 hours): Login, signup, JWT handling, protected routes

### Testing Requirements (~6-8 hours)
- **Rails RSpec tests** (2-3 hours): Models, requests, services (test coverage >90%)
- **Java JUnit tests** (2-3 hours): Controllers, services (test coverage >85%)
- **React Vitest tests** (2-3 hours): Component tests, user interactions (8 comprehensive tests)

### Infrastructure & Documentation (~4-5 hours)
- **Docker setup** (2 hours): Multi-service orchestration, health checks
- **Documentation** (2-3 hours): README, ARCHITECTURE, troubleshooting

### Total: ~30-38 hours

## Future Enhancements

- [ ] Implement full audit logging
- [ ] Add rate limiting (Rack::Attack)
- [ ] Implement refresh tokens
- [ ] Add pagination for PII records list
- [ ] Implement "Show All" toggle
- [ ] Add key rotation for encryption
- [ ] Implement TLS/HTTPS
- [ ] Add search and filtering
- [ ] Implement bulk operations
- [ ] Add data export functionality

## Support

For issues or questions, please refer to:
- `ARCHITECTURE.md` - Detailed system architecture
- `doc/IMPLEMENTATION_PLAN.md` - Development roadmap
- `CLAUDE.md` - Development guidelines and patterns


