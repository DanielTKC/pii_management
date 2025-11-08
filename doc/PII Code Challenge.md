# Engineering Take-Home Challenge: Secure PII Management System

## Overview
Build a full-stack application that securely collects, stores, and displays Personal Identifiable Information (PII). This challenge tests your ability to work with security best practices, full-stack development, and modern web technologies.

---

## Technical Requirements

### Backend Services

You'll need to build **TWO** separate backend services:

#### 1. Ruby on Rails API Service
- RESTful API for PII management
- PostgreSQL database with encrypted storage
- SSN validation per Social Security Administration ("SSA") standards
- Secure encryption for SSN at rest

#### 2. Java Microservice
- Separate service for SSN validation/encryption
- Exposes endpoints consumed by the Rails API
- Handles SSN format validation and encryption operations

### Frontend
- React.js single-page application
- Tailwind CSS or Bootstrap for styling —- Don't worry about making this beautiful. Focus on function.
- Fully responsive (mobile & desktop)

### Database
- PostgreSQL
- Proper indexing and constraints
- Encrypted fields for sensitive data

---

## Functional Requirements

### 1. PII Data Collection Form
Create a form that collects:
- **First Name** (required, 1-50 characters)
- **Middle Name** (required, 1-50 characters)
- **Middle Name Override** (for users that might not have a middle name, allow them to indicate as such and satisfy the middle name requirement)
- **Last Name** (required, 1-50 characters)
- **Social Security Number** (required, format: XXX-XX-XXXX)
- **Current Address** (required)
  - Street Address 1
  - Street Address 2
  - City
  - State Abbreviation
  - ZIP Code

### 2. SSN Validation Requirements
Implement validation per SSA standards:
- Must be 9 digits in XXX-XX-XXXX format
- Area number (first 3 digits) cannot be 000 or 666
-- Area number may allow 900-999
- Group number (middle 2 digits) cannot be 00
- Serial number (last 4 digits) cannot be 0000
- Must not be a known invalid test SSN (e.g., 078-05-1120)

### 3. Security Requirements
- **In Transit**: Use HTTPS/TLS (document how this would be configured)
- **At Rest**: Encrypt SSN in PostgreSQL using AES-256
- **Display**: Show SSN as `***-**-1234` (only last 4 digits visible)
- **Java Service**: Handle encryption/decryption operations

### 4. Display Page
Create a simple listing page that shows:
- All submitted records
- Full names displayed normally
- SSN obfuscated (show last 4 only)
- Full address displayed
- Basic styling with your chosen CSS framework

---

## Testing Requirements

### Ruby on Rails Tests
- Model validations
- Controller specs for API endpoints
- Request specs for integration testing
- Test encryption/decryption functionality

### Java Tests (JUnit)
- Unit tests for SSN validation logic
- Tests for encryption/decryption methods
- API endpoint tests

### Frontend Tests (Jest/React Testing Library)
- Component rendering tests
- Form validation tests
- At minimum: 3-4 meaningful test cases

### Minimum Coverage Goal ###
- Aim for >90% code coverage on backend services

---

## Deliverables

### 1. GitHub Repository Structure
```
/rails-api          # Rails application
/java-service       # Java microservice
/react-frontend     # React application
README.md           # Setup instructions
ARCHITECTURE.md     # Brief architecture overview
.env.example        # Environment variables template
docker-compose.yml  # (Optional but appreciated)
```

### 2. Documentation (README.md)
Include:
- Setup instructions for all three services
- Database setup and migration commands
- How to run the application
- How to run tests
- Any assumptions or trade-offs made
- An honest, self-assessed summary of time spent on the Technical, Functional, and Testing Requirements.

### 3. ARCHITECTURE.md
Brief overview including:
- System architecture diagram (text-based is fine)
- How the services communicate
- Security implementation details
- Database schema
- Any design decisions and rationale

---

## Evaluation Criteria

We'll be evaluating:

### Code Quality
- Clean, readable, well-organized, documented code
- Proper separation of concerns
- Appropriate use of design patterns
- Consistent coding style

### Security Implementation
- Approach to encryption
- Secure communication between services
- No sensitive data in logs or error messages

### Functionality
- All requirements implemented
- Application works as described
- Proper error handling
- Form validation

### Testing
- Test coverage
- Quality of test cases
- Tests actually verify behavior

### DevOps & Documentation
- Clear setup instructions
- Code is runnable by following README
- Environment configuration
- Git hygiene (meaningful commits)

---

## Getting Started Tips

### Simplifications You Can Make
- **Auth**: No user authentication required, but encouraged if you have time.
- **Java Framework**: Use Spring Boot for rapid development
- **Deployment**: Local development only (document production considerations)
- **SSL**: Document approach rather than implementing locally
- **AI**: Use of AI as a _tool_ or _assistant_ is acceptable and encouraged. Please document how you might have used an AI tool.

### What We Don't Expect
- Perfect UI/UX design (functional is fine)
- Production-ready deployment configuration
- Comprehensive error handling for every edge case
- Advanced features beyond requirements

---

## Submission

1. **Repository**: Push to a public GitHub repository
2. **Access**: Ensure repository is public and accessible
3. **Notification**: Send repository link when complete
4. **Demo**: Be prepared to walk through your code and run the application

---

## Questions?

This is an at-home challenge - part of the evaluation is your ability to make reasonable decisions independently. However, if you have questions about:
- **Ambiguous requirements**: Document your assumptions in README.md
- **Technical blockers**: Note them in your documentation
- **Scope concerns**: Implement core features first, note future improvements

---

## Bonus Points (Optional)
- Docker Compose for easy local setup
- Input sanitization and XSS prevention
- Audit logging for PII access
- API rate limiting
- Additional validation

---

**Ultimately, do not let perfect be the enemy of good. We're excited to see your approach to this problem. Remember: working, well-tested code is better than feature-complete but broken code. Good luck!**