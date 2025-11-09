# SSN Service - Java Microservice

A Spring Boot microservice for SSN (Social Security Number) validation and encryption using AES-256-GCM encryption.

## Overview

This service provides REST API endpoints for:
- SSN format validation according to SSA standards
- SSN encryption/decryption using AES-256-GCM
- Combined validation and encryption in a single operation
- Health check and monitoring

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- Docker (optional, for containerized deployment)

## Configuration

The service requires an encryption key to be set via environment variable:

```bash
ENCRYPTION_KEY=<base64-encoded-32-byte-key>
```

Generate a secure key:
```bash
python3 -c "import base64, os; print(base64.b64encode(os.urandom(32)).decode())"
```

## Running the Service

### Local Development

```bash
mvn spring-boot:run
```

The service will start on `http://localhost:8080`

### Running Tests

```bash
# Run all tests
mvn test

# Run with coverage
mvn clean test jacoco:report

# Run specific test class
mvn test -Dtest=SsnValidatorTest
```

### Docker Deployment

```bash
# Build and run with Docker Compose (from project root)
docker compose up java-service
```

## API Endpoints

### 1. Validate SSN

Validates SSN format and checks against SSA rules.

**Endpoint:** `POST /api/ssn/validate`

**Request:**
```bash
curl -X POST http://localhost:8080/api/ssn/validate \
  -H "Content-Type: application/json" \
  -d '{"ssn":"234-56-7890"}'
```

**Response (Valid SSN):**
```json
{
  "valid": true,
  "errors": []
}
```

**Response (Invalid SSN):**
```json
{
  "valid": false,
  "errors": [
    "Area number cannot be 000.",
    "Group number cannot be 00.",
    "Serial number cannot be 0000."
  ]
}
```

### 2. Encrypt SSN

Encrypts a valid SSN using AES-256-GCM encryption.

**Endpoint:** `POST /api/ssn/encrypt`

**Request:**
```bash
curl -X POST http://localhost:8080/api/ssn/encrypt \
  -H "Content-Type: application/json" \
  -d '{"ssn":"234-56-7890"}'
```

**Response:**
```json
{
  "encryptedSsn": "3giZO8JgfCc8lr9v2JxuNTO/OhQdKd2Z0xR3+Xnre94va9dtDd0z",
  "lastFour": "7890"
}
```

**Note:** Each encryption produces a different ciphertext due to random IV (Initialization Vector).

### 3. Decrypt SSN

Decrypts an encrypted SSN back to its original value.

**Endpoint:** `POST /api/ssn/decrypt`

**Request:**
```bash
curl -X POST http://localhost:8080/api/ssn/decrypt \
  -H "Content-Type: application/json" \
  -d '{"encryptedSsn":"3giZO8JgfCc8lr9v2JxuNTO/OhQdKd2Z0xR3+Xnre94va9dtDd0z"}'
```

**Response:**
```json
{
  "ssn": "234-56-7890"
}
```

### 4. Process SSN (Validate + Encrypt)

Validates and encrypts an SSN in a single operation.

**Endpoint:** `POST /api/ssn/process`

**Request:**
```bash
curl -X POST http://localhost:8080/api/ssn/process \
  -H "Content-Type: application/json" \
  -d '{"ssn":"234-56-7890"}'
```

**Response (Valid SSN):**
```json
{
  "valid": true,
  "errors": [],
  "encryptedSsn": "+JudAcwHxw7t+tY5ToxTtrbBYUVxjCGRpBrMdXsqpEskGUPlfpPQ",
  "lastFour": "7890"
}
```

**Response (Invalid SSN):**
```json
{
  "valid": false,
  "errors": ["SSN is known to be invalid."],
  "encryptedSsn": null,
  "lastFour": null
}
```

### 5. Health Check

Check service health and status.

**Endpoint:** `GET /actuator/health`

**Request:**
```bash
curl http://localhost:8080/actuator/health
```

**Response:**
```json
{
  "status": "UP",
  "components": {
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 994662584320,
        "free": 429028601856,
        "threshold": 10485760,
        "path": "/app/.",
        "exists": true
      }
    },
    "ping": {
      "status": "UP"
    },
    "ssl": {
      "status": "UP",
      "details": {
        "validChains": [],
        "invalidChains": []
      }
    }
  }
}
```

## SSN Validation Rules

The service validates SSNs according to Social Security Administration standards:

### Format
- Must match pattern: `XXX-XX-XXXX` or `XXXXXXXXX`
- Must contain only digits and optional dashes

### Area Number (First 3 digits)
- Cannot be `000`
- Cannot be `666`
- Cannot be `900-999` (except these are now valid for randomization)
- Valid range: `001-665` and `900-999`

### Group Number (Middle 2 digits)
- Cannot be `00`
- Valid range: `01-99`

### Serial Number (Last 4 digits)
- Cannot be `0000`
- Valid range: `0001-9999`

### Known Invalid SSNs
The following SSNs are explicitly rejected:
- `078-05-1120` (used in advertising)
- `219-09-9999` (used in advertising)
- `123-45-6789` (commonly used as example)

## Security Features

### Encryption
- **Algorithm:** AES-256-GCM (Galois/Counter Mode)
- **Key Size:** 256 bits (32 bytes)
- **IV:** Randomly generated for each encryption (12 bytes)
- **Authentication:** Built-in authentication tag for tamper detection

### Security Benefits
- **Confidentiality:** Strong encryption protects SSN data at rest
- **Integrity:** GCM mode detects any tampering with encrypted data
- **Randomization:** Each encryption produces unique ciphertext (IV randomization)
- **No ECB:** Avoids insecure ECB mode patterns

## Project Structure

```
java-service/
├── src/
│   ├── main/
│   │   └── java/com/pii/ssn/service/
│   │       ├── controller/          # REST controllers
│   │       │   ├── SsnValidationController.java
│   │       │   └── SsnEncryptionController.java
│   │       ├── dto/                 # Data Transfer Objects
│   │       │   ├── SsnValidationRequest.java
│   │       │   ├── SsnValidationResponse.java
│   │       │   ├── SsnEncryptionRequest.java
│   │       │   ├── SsnEncryptionResponse.java
│   │       │   ├── SsnDecryptionRequest.java
│   │       │   ├── SsnDecryptionResponse.java
│   │       │   ├── SsnProcessRequest.java
│   │       │   └── SsnProcessResponse.java
│   │       ├── encryption/          # Encryption service
│   │       │   └── SsnEncryptionService.java
│   │       ├── validator/           # Validation logic
│   │       │   └── SsnValidator.java
│   │       └── SsnServiceApplication.java
│   └── test/
│       ├── java/                    # Unit and integration tests
│       └── resources/
│           └── application-test.properties
├── pom.xml
└── README.md
```

## Test Coverage

The service includes comprehensive test coverage:

- **123 total tests**
- **Unit Tests:**
  - 37 encryption service tests
  - 38 validator tests
- **Integration Tests:**
  - 21 validation controller tests
  - 26 encryption controller tests
  - 1 application context test

Run tests with coverage:
```bash
mvn clean test jacoco:report
```

View coverage report at: `target/site/jacoco/index.html`

## Development

### Hot Reload
The service uses Spring Boot DevTools for automatic restart during development.

### Code Quality
- **JaCoCo** for code coverage (90% minimum)
- **Maven Surefire** for test execution
- **Spring Boot Actuator** for monitoring

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200 OK` - Successful validation/encryption/decryption
- `400 Bad Request` - Invalid request body or JSON format
- `415 Unsupported Media Type` - Missing or incorrect Content-Type header
- `500 Internal Server Error` - Unexpected server errors

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `ENCRYPTION_KEY` | Base64-encoded 32-byte AES-256 key | Yes | None |
| `SERVER_PORT` | Port for the service | No | 8080 |
| `MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE` | Actuator endpoints | No | health,info |

## Production Deployment

### Best Practices
1. **Never hardcode encryption keys** - Use environment variables or secret management
2. **Use HTTPS** - Encrypt data in transit
3. **Rotate keys regularly** - Implement key rotation strategy
4. **Monitor health endpoints** - Set up alerts for service health
5. **Enable audit logging** - Track all encryption/decryption operations
6. **Rate limiting** - Protect against abuse

### Docker Compose
The service is configured in the main `docker-compose.yml`:
```yaml
java-service:
  build:
    context: ./java-service
    dockerfile: Dockerfile.dev
  ports:
    - "8080:8080"
  environment:
    - ENCRYPTION_KEY=${ENCRYPTION_KEY}
  volumes:
    - ./java-service:/app
```

## Support

For issues or questions, please refer to the main project documentation or create an issue in the project repository.
