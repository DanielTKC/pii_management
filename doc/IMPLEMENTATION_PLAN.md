# PII Management System - Implementation Plan

## Overview
This plan outlines an iterative, TDD-driven approach to building a secure PII management system with a Rails API, Java microservice for SSN encryption/validation, PostgreSQL database, and React frontend.

## Plan Summary

**Total Phases:** 13 phases (0-12 implementation + Phase 13 security/docs)

**Key Features:**
- User authentication with protected routes
- Full CRUD operations for PII records
- Dual SSN validation (independent in Rails and Java)
- AES-256 encryption for SSN at rest
- Comprehensive audit logging for all PII access
- Soft deletes with deleted_at timestamp
- Pagination with "show all" option
- API versioning (/api/v1/)
- Retry logic with exponential backoff for service communication
- >90% test coverage on backend services
- TDD approach for all development

**Technology Stack:**
- **Backend API:** Rails 8.1 with RSpec, FactoryBot, SimpleCov
- **Microservice:** Java 17, Spring Boot 3.5, JUnit 5, JaCoCo
- **Database:** PostgreSQL 17 with audit logging
- **Frontend:** React with Vite, React Router, Jest, React Testing Library
- **Deployment:** Kamal
- **Testing:** TDD with comprehensive unit, integration, and E2E tests

## TDD Implementation Workflow

**All development MUST follow this workflow:**

1. **Write tests first** based on expected input/output pairs
   - Be explicit about doing TDD - avoid creating mock implementations
   - Write comprehensive tests for functionality that doesn't exist yet
   - Focus on the interface and expected behavior

2. **Run tests and confirm they fail** for the right reasons

3. **Commit the failing tests** with message describing what will be tested

4. **Write minimal code to make the tests pass**
   - Do NOT modify the tests - only change implementation code
   - Focus on making all tests green

5. **Run tests iteratively** until all pass

6. **Run linting/type checking** as specified in CLAUDE.md

7. **Commit the working implementation** with message describing the functionality and implementation choices

---

## Requirements Summary

### Functional Requirements
- Collect PII data: First Name, Middle Name (with override), Last Name, SSN, Address
- SSN validation per SSA standards in both Rails and Java services
- AES-256 encryption for SSN at rest (handled by Java service)
- Display SSN as `***-**-XXXX` (last 4 digits only)
- List all PII records with obfuscated SSN

### Technical Requirements
- Rails API for PII management (with SSN validation)
- Java microservice for SSN validation AND encryption/decryption
- PostgreSQL with encrypted SSN storage
- React frontend with form and display page
- >90% test coverage on backend services

### Security Requirements
- SSN encrypted at rest using AES-256
- SSN obfuscated in display
- No sensitive data in logs or error messages
- HTTPS/TLS for production (documented approach)

---

## Database Schema

### `pii_records` table
```sql
- id: bigint (primary key)
- first_name: varchar(50), not null
- middle_name: varchar(50), nullable
- middle_name_override: boolean, default false
- last_name: varchar(50), not null
- encrypted_ssn: text, not null (stores encrypted SSN from Java service)
- ssn_last_four: varchar(4), not null (for display purposes)
- street_address_1: varchar(255), not null
- street_address_2: varchar(255), nullable
- city: varchar(100), not null
- state: varchar(2), not null (uppercase state abbreviation)
- zip_code: varchar(10), not null
- created_at: timestamp
- updated_at: timestamp

Indexes:
- index on ssn_last_four (for search/lookup)
- index on last_name, first_name (for sorting)
```

---

## Implementation Decisions (Based on Q&A)

- **Authentication**: Implement user authentication system
- **Middle Name Override**: Store "N/A" when override is checked
- **Encryption Key**: Single key for now, document rotation strategy (30 days or 64GB)
- **Pagination**: Implement pagination with "show all" option
- **Deletes**: Soft deletes (deleted_at timestamp)
- **Navigation**: React Router for SPA routing
- **Audit Logging**: Track all PII access and modifications
- **Edit Functionality**: Full CRUD (Create, Read, Update, Delete)
- **SSN Uniqueness**: Validate unique encrypted SSN in database
- **Deployment**: Document Kamal deployment
- **Validation**: Both Rails and Java have independent validation
- **Timeouts**: 5 seconds for HTTP calls (configurable)
- **Retry Logic**: 3 retries with exponential backoff
- **Test Data**: FactoryBot with RSpec
- **API Versioning**: Use /api/v1/ namespace

---

## Implementation Phases

### Phase 0: Authentication System Setup

**Goal:** Set up basic user authentication before PII handling

**Models:**
- `User` (ActiveRecord model via Devise or similar)
  - email: string, unique, not null
  - encrypted_password: string
  - created_at, updated_at timestamps

**Steps:**
1. Add authentication gem (Devise or JWT-based auth)
2. Generate User model and migrations
3. Configure authentication for API
4. Add authentication tokens/sessions
5. Protect PII endpoints with authentication

**Unit Tests:**
- `spec/models/user_spec.rb`:
  - Test user creation
  - Test email validation and uniqueness
  - Test password encryption
  - Test authentication

**API Tests:**
- `spec/requests/authentication_spec.rb`:
  - Test signup endpoint
  - Test login endpoint
  - Test token generation
  - Test protected endpoints require auth

**Database Migrations:**
- Create users table

**Git Commits:**
1. Commit migration for users
2. Commit failing auth tests
3. Commit authentication implementation

---

### Phase 1: Java Microservice - SSN Validation Service

**Goal:** Build and test SSN validation logic in Java service

**Models/DTOs:**
- `SsnValidationRequest`
  - `ssn: String` (raw SSN input)
- `SsnValidationResponse`
  - `valid: boolean`
  - `errors: List<String>` (validation error messages)

**Steps:**
1. Create `SsnValidator` utility class with static methods
2. Implement SSN format validation (XXX-XX-XXXX)
3. Implement area number validation (not 000, not 666, allow 900-999)
4. Implement group number validation (not 00)
5. Implement serial number validation (not 0000)
6. Implement known invalid SSN check (e.g., 078-05-1120)
7. Create REST controller endpoint: `POST /api/ssn/validate`

**Unit Tests:**
- `SsnValidatorTest.java`:
  - Test valid SSN formats
  - Test invalid format (wrong length, missing dashes, letters)
  - Test area number = 000 (invalid)
  - Test area number = 666 (invalid)
  - Test area number = 900-999 (valid)
  - Test area number = 001-665 (valid)
  - Test group number = 00 (invalid)
  - Test group number = 01-99 (valid)
  - Test serial number = 0000 (invalid)
  - Test serial number = 0001-9999 (valid)
  - Test known invalid SSNs (078-05-1120)
  - Test null/empty input

**Controller Tests:**
- `SsnValidationControllerTest.java`:
  - Test POST /api/ssn/validate with valid SSN
  - Test POST /api/ssn/validate with invalid SSN
  - Test POST /api/ssn/validate with malformed request
  - Test response format validation

**Database Migrations:** None (stateless service)

**Git Commits:**
1. Commit failing tests for SsnValidator
2. Commit SsnValidator implementation
3. Commit failing tests for validation controller
4. Commit validation controller implementation

---

### Phase 2: Java Microservice - SSN Encryption Service

**Goal:** Build and test SSN encryption/decryption using AES-256

**Models/DTOs:**
- `SsnEncryptionRequest`
  - `ssn: String` (plaintext SSN)
- `SsnEncryptionResponse`
  - `encryptedSsn: String` (Base64-encoded encrypted SSN)
  - `lastFour: String` (last 4 digits for display)
- `SsnDecryptionRequest`
  - `encryptedSsn: String`
- `SsnDecryptionResponse`
  - `ssn: String` (plaintext SSN)

**Steps:**
1. Create `SsnEncryptionService` with AES-256-GCM encryption
2. Load encryption key from environment variable
3. Implement encrypt method (returns Base64-encoded encrypted SSN)
4. Implement decrypt method
5. Implement lastFour extraction method
6. Create REST controller endpoints:
   - `POST /api/ssn/encrypt`
   - `POST /api/ssn/decrypt`

**Unit Tests:**
- `SsnEncryptionServiceTest.java`:
  - Test encryption produces different output for same input (IV randomization)
  - Test decryption recovers original SSN
  - Test encrypt-decrypt round trip
  - Test lastFour extraction
  - Test encryption with invalid key
  - Test decryption with wrong key
  - Test decryption with corrupted data

**Controller Tests:**
- `SsnEncryptionControllerTest.java`:
  - Test POST /api/ssn/encrypt with valid SSN
  - Test POST /api/ssn/decrypt with valid encrypted SSN
  - Test error handling for invalid inputs

**Database Migrations:** None (stateless service)

**Git Commits:**
1. Commit failing tests for SsnEncryptionService
2. Commit SsnEncryptionService implementation
3. Commit failing tests for encryption controller
4. Commit encryption controller implementation

---

### Phase 3: Java Microservice - Combined Validate & Encrypt Endpoint

**Goal:** Create convenience endpoint that validates then encrypts SSN

**Models/DTOs:**
- `SsnProcessRequest`
  - `ssn: String`
- `SsnProcessResponse`
  - `valid: boolean`
  - `errors: List<String>`
  - `encryptedSsn: String` (only if valid)
  - `lastFour: String` (only if valid)

**Steps:**
1. Create `POST /api/ssn/process` endpoint
2. Validate SSN first using SsnValidator
3. If valid, encrypt using SsnEncryptionService
4. Return combined response

**Unit Tests:**
- `SsnProcessControllerTest.java`:
  - Test valid SSN returns encrypted data
  - Test invalid SSN returns errors without encrypted data
  - Test all validation rules still apply

**Database Migrations:** None

**Git Commits:**
1. Commit failing tests for process endpoint
2. Commit process endpoint implementation

---

### Phase 4: Rails API - SSN Validation Service

**Goal:** Implement SSN validation in Rails (mirror of Java validation logic)

**Models:**
- `SsnValidator` (Plain Old Ruby Object - PORO)
  - Class methods for validation logic
  - Should mirror Java validation rules exactly

**Steps:**
1. Create `app/services/ssn_validator.rb`
2. Implement format validation
3. Implement area number validation
4. Implement group number validation
5. Implement serial number validation
6. Implement known invalid SSN check

**Unit Tests:**
- `spec/services/ssn_validator_spec.rb`:
  - Test valid SSN formats
  - Test invalid format
  - Test area number validation (000, 666, 900-999 cases)
  - Test group number validation
  - Test serial number validation
  - Test known invalid SSNs
  - Test null/empty input

**Database Migrations:** None

**Git Commits:**
1. Commit failing tests for SsnValidator service
2. Commit SsnValidator implementation

---

### Phase 5: Rails API - Java Service Client

**Goal:** Create HTTP client to communicate with Java microservice

**Models:**
- `JavaSsnClient` (PORO service class)
  - Methods:
    - `validate(ssn)` -> calls Java validation endpoint
    - `encrypt(ssn)` -> calls Java encryption endpoint
    - `decrypt(encrypted_ssn)` -> calls Java decryption endpoint
    - `process(ssn)` -> calls Java process endpoint

**Steps:**
1. Create `app/services/java_ssn_client.rb`
2. Configure Java service URL from environment variable
3. Implement HTTP client using Net::HTTP or HTTParty
4. Add error handling for connection failures
5. Add timeout configuration

**Unit Tests:**
- `spec/services/java_ssn_client_spec.rb`:
  - Test successful validation call
  - Test successful encryption call
  - Test successful decryption call
  - Test successful process call
  - Test connection error handling
  - Test timeout handling
  - Test malformed response handling
  - Use WebMock to stub HTTP requests

**Database Migrations:** None

**Git Commits:**
1. Commit failing tests for JavaSsnClient
2. Commit JavaSsnClient implementation

---

### Phase 6: Rails API - PII Record Model & Audit Log

**Goal:** Create PII Record model with validations, soft deletes, and audit logging

**Models:**
- `PiiRecord` (ActiveRecord model)
  - Attributes: first_name, middle_name, middle_name_override, last_name, encrypted_ssn, ssn_last_four, street_address_1, street_address_2, city, state, zip_code, user_id, deleted_at
  - Virtual attribute: `ssn` (write-only, for accepting plaintext SSN)
  - Relationships:
    - belongs_to :user
    - has_many :audit_logs, as: :auditable
  - Validations:
    - first_name: presence, length 1-50
    - middle_name: length 1-50 if present, set to "N/A" if middle_name_override is true
    - last_name: presence, length 1-50
    - ssn: presence (on virtual attribute), valid format, uniqueness of encrypted_ssn
    - street_address_1: presence
    - city: presence
    - state: presence, format (2 uppercase letters)
    - zip_code: presence, format (5 digits or 5+4 format)
    - user_id: presence
  - Callbacks:
    - before_validation: validate and encrypt SSN using JavaSsnClient
    - before_validation: set middle_name to "N/A" if middle_name_override is true
    - after_create, after_update, after_destroy: create audit log entry
  - Scopes:
    - active (where deleted_at is null)
  - Methods:
    - `display_ssn` -> returns `***-**-XXXX` format
    - `soft_delete` -> sets deleted_at timestamp

- `AuditLog` (ActiveRecord model for tracking PII access)
  - auditable_id: bigint
  - auditable_type: string
  - user_id: bigint
  - action: string (create, read, update, delete)
  - changes: jsonb (stores changed attributes)
  - ip_address: string
  - created_at: timestamp
  - Relationships:
    - belongs_to :auditable, polymorphic: true
    - belongs_to :user

**Steps:**
1. Generate migration for pii_records table with deleted_at
2. Generate migration for audit_logs table
3. Create AuditLog model
4. Create PiiRecord model
5. Add validations including SSN uniqueness
6. Add virtual `ssn` attribute accessor
7. Add before_validation callbacks (SSN processing, middle name "N/A")
8. Add after_create/update/destroy callbacks for audit logging
9. Add soft delete scope and method
10. Add `display_ssn` method
11. Add FactoryBot factories for testing

**Unit Tests:**
- `spec/models/pii_record_spec.rb`:
  - Test valid PII record creation
  - Test first_name validations (presence, length)
  - Test middle_name "N/A" when override is true
  - Test last_name validations (presence, length)
  - Test SSN validation (format, SSA rules)
  - Test SSN uniqueness validation
  - Test SSN encryption on save
  - Test ssn_last_four extraction
  - Test address validations
  - Test state format validation
  - Test zip_code format validation
  - Test display_ssn method returns obfuscated SSN
  - Test soft delete functionality
  - Test active scope excludes soft-deleted records
  - Test belongs_to user association
  - Test audit log creation on create/update/destroy
  - Use FactoryBot for test data

- `spec/models/audit_log_spec.rb`:
  - Test audit log creation
  - Test polymorphic association
  - Test user association
  - Test storing changes in jsonb

**Database Migrations:**
- `db/migrate/XXXXXX_create_pii_records.rb`
  - Create pii_records table with all columns including user_id and deleted_at
  - Add indexes on encrypted_ssn (unique), user_id, deleted_at
- `db/migrate/XXXXXX_create_audit_logs.rb`
  - Create audit_logs table
  - Add indexes on auditable polymorphic, user_id, created_at

**Git Commits:**
1. Commit migrations for pii_records and audit_logs
2. Commit FactoryBot setup and factories
3. Commit failing tests for AuditLog model
4. Commit AuditLog model implementation
5. Commit failing tests for PiiRecord model
6. Commit PiiRecord model implementation

---

### Phase 7: Rails API - PII Records Controller with CRUD & Pagination

**Goal:** Create RESTful API endpoints for PII records with full CRUD, pagination, and retry logic

**Controllers:**
- `Api::V1::PiiRecordsController`
  - Actions:
    - `index` -> GET /api/v1/pii_records (list records with pagination)
    - `show` -> GET /api/v1/pii_records/:id (show single record, log audit)
    - `create` -> POST /api/v1/pii_records (create new record)
    - `update` -> PUT/PATCH /api/v1/pii_records/:id (update record)
    - `destroy` -> DELETE /api/v1/pii_records/:id (soft delete record)
  - Filters:
    - before_action: authenticate_user!
    - after_action: log_audit (for show action)

**Steps:**
1. Configure API versioning (namespace api/v1)
2. Create Api::V1::PiiRecordsController
3. Implement index action with pagination (Kaminari or Pagy)
4. Add "show_all" query parameter to bypass pagination
5. Implement show action with audit logging for "read" events
6. Implement create action with strong parameters
7. Implement update action
8. Implement destroy action (soft delete)
9. Add JSON serialization (jbuilder views)
10. Configure CORS for React frontend
11. Add retry logic wrapper for JavaSsnClient calls (3 retries, exponential backoff)
12. Set timeout to 5 seconds for Java service HTTP calls

**API Response Tests:**
- `spec/requests/api/v1/pii_records_spec.rb`:
  - Test authentication required for all endpoints
  - Test GET /api/v1/pii_records returns paginated records
  - Test GET /api/v1/pii_records?show_all=true returns all records
  - Test GET /api/v1/pii_records returns SSN obfuscated
  - Test GET /api/v1/pii_records/:id returns single record
  - Test GET /api/v1/pii_records/:id creates audit log entry
  - Test POST /api/v1/pii_records with valid data creates record
  - Test POST /api/v1/pii_records with invalid data returns errors
  - Test POST /api/v1/pii_records with duplicate SSN returns error
  - Test PUT /api/v1/pii_records/:id updates record
  - Test PATCH /api/v1/pii_records/:id updates record
  - Test DELETE /api/v1/pii_records/:id soft deletes record
  - Test soft-deleted records excluded from index
  - Test response format (JSON structure)
  - Test retry logic when Java service fails temporarily
  - Test timeout behavior

**Database Migrations:** None

**Git Commits:**
1. Commit API namespace and routing configuration
2. Commit pagination gem setup
3. Commit retry logic for JavaSsnClient
4. Commit failing tests for PiiRecordsController
5. Commit PiiRecordsController implementation
6. Commit jbuilder views
7. Commit CORS configuration

---

### Phase 8: React Frontend - Authentication & Protected Routes

**Goal:** Set up React Router, authentication, and protected routes

**Components:**
- `Login.jsx` - Login form
- `Register.jsx` - Registration form (optional)
- `PrivateRoute.jsx` - Route wrapper requiring authentication
- `AuthContext.jsx` - Context for authentication state

**Steps:**
1. Install React Router DOM
2. Create AuthContext for managing auth state and tokens
3. Create Login component
4. Create API client utilities with token management
5. Create PrivateRoute wrapper component
6. Set up route structure in App.jsx
7. Store JWT token in localStorage or sessionStorage
8. Add token to all API requests

**Unit Tests:**
- `Login.test.jsx`:
  - Test login form renders
  - Test successful login
  - Test failed login shows error
  - Test token storage
- `AuthContext.test.jsx`:
  - Test auth state management
  - Test login/logout functions
  - Test token persistence

**Database Migrations:** None

**Git Commits:**
1. Commit React Router setup
2. Commit failing tests for auth components
3. Commit AuthContext and Login implementation

---

### Phase 9: React Frontend - PII Form Component (Create & Edit)

**Goal:** Build form to create and edit PII data

**Components:**
- `PiiForm.jsx`
  - Props: editMode (boolean), recordId (for edit), onSuccess callback
  - State: formData, errors, loading, submitSuccess
  - Fields: firstName, middleName, middleNameOverride, lastName, ssn, streetAddress1, streetAddress2, city, state, zipCode
  - Client-side validation
  - Submit handler calling Rails API (POST or PUT based on mode)

**Steps:**
1. Create PiiForm component
2. Add form fields with labels
3. Implement controlled inputs
4. Add client-side validation
5. Add SSN input masking (XXX-XX-XXXX format)
6. Implement middle name override checkbox (sets middle name to "N/A")
7. Add submit handler with API call (v1 endpoint with auth token)
8. Add loading state and error display
9. Add success message and form reset
10. Support edit mode - fetch existing record if recordId provided
11. In edit mode, show obfuscated SSN, allow updating other fields
12. Validate SSN uniqueness on frontend

**Unit Tests:**
- `PiiForm.test.jsx`:
  - Test form renders all fields in create mode
  - Test form loads existing data in edit mode
  - Test middle name override sets value to "N/A"
  - Test SSN input masking
  - Test client-side validation messages
  - Test form submission (create) with valid data
  - Test form submission (update) with valid data
  - Test form submission with invalid data
  - Test error display from API (including duplicate SSN)
  - Test success message display
  - Test form reset after successful creation
  - Test authentication token included in requests

**Database Migrations:** None

**Git Commits:**
1. Commit failing tests for PiiForm
2. Commit PiiForm implementation (create mode)
3. Commit PiiForm edit mode functionality

---

### Phase 10: React Frontend - PII List Component with Pagination & Actions

**Goal:** Display all PII records with obfuscated SSN, pagination, edit, and delete

**Components:**
- `PiiList.jsx`
  - State: records, loading, error, currentPage, totalPages, showAll
  - Fetches data from Rails API on mount
  - Displays records in table/card layout
  - Shows obfuscated SSN
  - Action buttons: Edit, Delete (soft delete)
  - Pagination controls

**Steps:**
1. Create PiiList component
2. Add useEffect to fetch records on mount with pagination
3. Implement pagination controls (page number, next/prev)
4. Add "Show All" toggle to bypass pagination
5. Implement loading state
6. Implement error state
7. Render records in responsive table layout
8. Format SSN display (***-**-XXXX)
9. Add Edit button (navigates to edit form)
10. Add Delete button with confirmation modal
11. Implement soft delete API call
12. Refresh list after delete
13. Add basic styling with Tailwind/Bootstrap
14. Include authentication token in API calls

**Unit Tests:**
- `PiiList.test.jsx`:
  - Test component renders loading state
  - Test component fetches and displays paginated records
  - Test pagination controls work correctly
  - Test "Show All" toggle
  - Test SSN obfuscation in display
  - Test Edit button navigates to edit route
  - Test Delete button shows confirmation
  - Test Delete confirmation calls API and refreshes list
  - Test error handling
  - Test empty state (no records)
  - Test authentication token included in requests

**Database Migrations:** None

**Git Commits:**
1. Commit failing tests for PiiList
2. Commit PiiList implementation with pagination
3. Commit edit and delete functionality

---

### Phase 11: React Frontend - App Integration & Routing

**Goal:** Integrate all components with React Router navigation

**Components:**
- `App.jsx`
  - Routes:
    - `/login` - Login page (public)
    - `/` - PII List (protected)
    - `/pii/new` - Create PII form (protected)
    - `/pii/:id/edit` - Edit PII form (protected)
  - Layout with navigation header
  - AuthContext provider wrapper

**Steps:**
1. Update App.jsx with React Router
2. Define all routes (public and protected)
3. Create navigation header with links
4. Add logout functionality
5. Implement protected route redirects to login
6. Add responsive layout
7. Add global error boundary

**Unit Tests:**
- `App.test.jsx`:
  - Test public routes accessible without auth
  - Test protected routes redirect to login when not authenticated
  - Test navigation between routes when authenticated
  - Test logout clears auth and redirects

**Database Migrations:** None

**Git Commits:**
1. Commit App integration with routing
2. Commit navigation header and layout

---

### Phase 12: End-to-End System Tests

**Goal:** Verify complete workflow from frontend to database

**System Test Cases:**

1. **Authentication Flow**
   - User visits app without auth, redirected to login
   - User logs in with valid credentials
   - User gains access to protected routes
   - User logs out, redirected to login

2. **Happy Path - Create and Display PII Record**
   - Authenticated user navigates to create form
   - User fills out form with valid data
   - SSN is validated by both Rails and Java services (independently)
   - SSN is encrypted by Java service
   - Record is saved to PostgreSQL
   - Audit log created for "create" action
   - User sees success message
   - User navigates to list page
   - New record appears with obfuscated SSN
   - Full address is displayed correctly

3. **Middle Name Override**
   - User checks "No middle name" checkbox
   - Middle name field shows "N/A" or is disabled
   - Form submits successfully with middle name = "N/A"
   - Record displays correctly in list with "N/A"

4. **Invalid SSN Validation**
   - User enters SSN with area number 000
   - Form shows validation error
   - Record is not created
   - User enters SSN with group number 00
   - Form shows validation error
   - User enters SSN with serial number 0000
   - Form shows validation error
   - User enters duplicate SSN
   - Form shows uniqueness validation error

5. **Address Validation**
   - User enters invalid state (3 letters)
   - Form shows validation error
   - User enters invalid zip code
   - Form shows validation error

6. **Pagination**
   - Create 25+ PII records
   - Navigate to list page
   - See paginated results (default page size)
   - Navigate between pages
   - Toggle "Show All" to see all records
   - Verify SSN obfuscation on all pages

7. **Edit PII Record**
   - User clicks Edit on a record
   - Form loads with existing data
   - SSN shows obfuscated
   - User updates name and address
   - Form submits successfully
   - Audit log created for "update" action
   - Updated data displays in list
   - SSN remains unchanged

8. **Soft Delete PII Record**
   - User clicks Delete on a record
   - Confirmation modal appears
   - User confirms deletion
   - Record soft-deleted (deleted_at set)
   - Audit log created for "delete" action
   - Record no longer appears in list
   - Record still exists in database with deleted_at timestamp

9. **Audit Logging**
   - User creates a PII record - audit log created
   - User views a PII record - audit log created
   - User updates a PII record - audit log created with changes
   - User deletes a PII record - audit log created
   - Verify all audit logs have user_id and ip_address

10. **Java Service Retry Logic**
    - Simulate Java service temporary failure
    - Rails API retries request (3 times with backoff)
    - Verify success after retry
    - Simulate Java service total failure
    - Verify appropriate error message to user

**Implementation:**
- Use Rails system tests (Capybara) for backend workflows
- Use React Testing Library with API mocking for frontend E2E
- Consider Cypress for full E2E testing across services

**Git Commits:**
1. Commit system tests
2. Fix any issues discovered
3. Commit fixes

---

### Phase 13: Security Hardening & Documentation

**Goal:** Ensure security best practices and complete documentation

**Steps:**
1. Audit logs for sensitive data exposure
2. Add parameter filtering for SSN in Rails logs
3. Ensure error messages don't leak SSN or PII data
4. Document HTTPS/TLS configuration for production
5. Review and test encryption key management
6. Document encryption key rotation strategy (30 days or 64GB)
7. Add rate limiting to API endpoints (Rack::Attack)
8. Add input sanitization for XSS prevention
9. Verify CSRF protection for API
10. Update README.md with comprehensive setup instructions
11. Create ARCHITECTURE.md with system diagram
12. Document test coverage results (aim for >90%)
13. Document Kamal deployment strategy
14. Create .env.example with all required variables
15. Add security headers (Content-Security-Policy, etc.)

**Security Checklist:**
- [ ] SSN filtered from Rails logs (config.filter_parameters)
- [ ] SSN not exposed in error messages or stack traces
- [ ] Encryption key loaded from environment variable
- [ ] HTTPS/TLS documented for production (Kamal config)
- [ ] Encryption key rotation strategy documented
- [ ] Input sanitization implemented (Rails default + custom)
- [ ] CORS properly configured (specific origins only)
- [ ] SQL injection prevention verified (parameterized queries)
- [ ] XSS prevention verified (React auto-escaping + CSP headers)
- [ ] Rate limiting configured (Rack::Attack)
- [ ] Authentication tokens secure (httpOnly cookies or secure storage)
- [ ] Audit logs capture all PII access
- [ ] Soft deletes prevent data loss
- [ ] Database backups documented
- [ ] No secrets in git repository

**Documentation Files:**
- README.md (setup, running, testing, deployment)
- ARCHITECTURE.md (system design, security, data flow)
- SECURITY.md (security considerations, key rotation, best practices)
- .env.example (all environment variables with descriptions)
- doc/DEPLOYMENT.md (Kamal deployment instructions)
- doc/API.md (API documentation for all v1 endpoints)

**Git Commits:**
1. Commit security hardening changes (logging, rate limiting, headers)
2. Commit comprehensive documentation
3. Commit .env.example and deployment docs

---

## Database Changes Summary

### Migrations Required
1. `CreateUsers` - creates users table for authentication
   - id, email, encrypted_password, created_at, updated_at
   - Index on email (unique)

2. `CreatePiiRecords` - creates pii_records table with all columns
   - id, first_name, middle_name, middle_name_override, last_name
   - encrypted_ssn (unique), ssn_last_four
   - street_address_1, street_address_2, city, state, zip_code
   - user_id (foreign key), deleted_at (for soft deletes)
   - created_at, updated_at
   - Indexes: encrypted_ssn (unique), user_id, deleted_at, (last_name, first_name)

3. `CreateAuditLogs` - creates audit_logs table for PII access tracking
   - id, auditable_type, auditable_id (polymorphic)
   - user_id (foreign key), action, changes (jsonb), ip_address
   - created_at
   - Indexes: (auditable_type, auditable_id), user_id, created_at

### PostgreSQL Extensions
- None required (encryption handled by Java service, not pgcrypto)

---

## Environment Variables

### Rails API
- `DATABASE_URL` - PostgreSQL connection string (e.g., postgresql://user:pass@db:5432/pii_db)
- `JAVA_SERVICE_URL` - URL of Java microservice (e.g., http://java-service:8080)
- `JAVA_SERVICE_TIMEOUT` - Timeout for Java service calls in seconds (default: 5)
- `JAVA_SERVICE_RETRIES` - Number of retry attempts (default: 3)
- `RAILS_MASTER_KEY` - Rails credentials key
- `RAILS_ENV` - Environment (development, test, production)
- `SECRET_KEY_BASE` - Rails secret for sessions/tokens
- `CORS_ORIGINS` - Allowed CORS origins (comma-separated)

### Java Service
- `ENCRYPTION_KEY` - Base64-encoded AES-256 key (32 bytes, generate with: `openssl rand -base64 32`)
- `SERVER_PORT` - Port for Java service (default: 8080)
- `SPRING_PROFILES_ACTIVE` - Active Spring profile (dev, prod)

### React Frontend
- `VITE_API_URL` - URL of Rails API (e.g., http://localhost:3000 or https://api.example.com)

---

## Testing Strategy

### Java Service Tests
- JUnit 5 for unit tests
- Spring Boot Test for integration tests
- Mockito for mocking dependencies
- JaCoCo for coverage (target: >90%)
- Run: `mvn test`
- Coverage report: `mvn jacoco:report`

### Rails API Tests
- RSpec for unit and request tests
- FactoryBot for test data generation (preferred over fixtures)
- SimpleCov for coverage (target: >90%)
- WebMock for HTTP stubbing (Java service calls)
- Database Cleaner for test isolation
- Shoulda Matchers for validation testing
- Run: `bundle exec rspec`
- Coverage report: `open coverage/index.html`

**FactoryBot Factories Needed:**
- `:user` - creates test users
- `:pii_record` - creates valid PII records with associations
- `:audit_log` - creates audit log entries

### React Frontend Tests
- Jest + React Testing Library
- Mock Service Worker (MSW) for API mocking
- Testing user interactions and component behavior
- Target: 3-4 meaningful test cases minimum per component
- Run: `npm test`
- Coverage: `npm test -- --coverage`

### System Tests
- Rails system tests with Capybara for backend workflows
- Cypress for full E2E testing (optional but recommended)
- Test complete user journeys across all three services

---

## Questions

Q: Should we implement user authentication, or proceed without it for now?
A: We can implement user authentication

Q: For the middle name override, should we store a special value (like "N/A") or leave it NULL when override is checked?
A: "N/A"

Q: Should the Java encryption service use a single encryption key for all SSNs, or implement a key rotation strategy?
A: Single key for now but we should document a key rotation strategy 30 days or 64gb whichever comes first.

Q: Do we want pagination on the PII list page, or display all records?
A: Pagination with option to show all

Q: Should we implement soft deletes for PII records, or hard deletes, or no delete functionality?
A: soft deletes

Q: For the React frontend, should we use React Router for navigation, or a simpler tab-based approach?
A: its an spa so we will need react router

Q: Should we implement audit logging to track who accessed/modified PII records?
A: yes

Q: Do we want to add an "Edit" functionality for PII records, or keep it create/read only?
A: Edit

Q: Should we validate that the SSN is unique in the database (no duplicate SSNs)?
A: yes

Q: For production deployment, should we document Docker deployment, Kubernetes, or traditional server deployment?
A: We will use kamal

Q: Should the Rails SSN validation be independent (validate locally) or should it call the Java validation service for consistency?
A: both should have their own independent validation services

Q: What should be the timeout values for Rails->Java HTTP calls?
A: A reasonable one

Q: Should we implement retry logic for Rails->Java service calls if the Java service is temporarily unavailable?
A: Yes

Q: For test data, should we use Rails fixtures, FactoryBot, or another approach?
A: Factory bot works great with rspec

Q: Should we add API versioning (e.g., /api/v1/pii_records) from the start?
A: yes
