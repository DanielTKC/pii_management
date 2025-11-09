package com.pii.ssn.service.validator;

import com.pii.ssn.service.dto.SsnValidationResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("SSN Validator")
class SsnValidatorTest {

    @Nested
    @DisplayName("Valid SSN Format Tests")
    class ValidSsnTests {

        @ParameterizedTest
        @ValueSource(strings = {
            "123-45-6789",
            "001-01-0001",
            "665-99-9999",
            "900-01-0001",
            "999-99-9999"
        })
        @DisplayName("should validate SSNs with correct format")
        void testValidSsnFormats(String ssn) {
            SsnValidationResponse response = SsnValidator.validate(ssn);
            assertTrue(response.isValid(), "SSN " + ssn + " should be valid");
            assertTrue(response.getErrors().isEmpty(), "Valid SSN should have no errors");
        }

        @Test
        @DisplayName("should accept area numbers 001-665")
        void testValidAreaNumbers001to665() {
            SsnValidationResponse response = SsnValidator.validate("123-45-6789");
            assertTrue(response.isValid());
            assertTrue(response.getErrors().isEmpty());
        }

        @Test
        @DisplayName("should accept area numbers 900-999")
        void testValidAreaNumbers900to999() {
            SsnValidationResponse response = SsnValidator.validate("900-12-3456");
            assertTrue(response.isValid());
            assertTrue(response.getErrors().isEmpty());
        }

        @Test
        @DisplayName("should accept group numbers 01-99")
        void testValidGroupNumbers() {
            SsnValidationResponse response = SsnValidator.validate("123-01-6789");
            assertTrue(response.isValid());

            response = SsnValidator.validate("123-99-6789");
            assertTrue(response.isValid());
        }

        @Test
        @DisplayName("should accept serial numbers 0001-9999")
        void testValidSerialNumbers() {
            SsnValidationResponse response = SsnValidator.validate("123-45-0001");
            assertTrue(response.isValid());

            response = SsnValidator.validate("123-45-9999");
            assertTrue(response.isValid());
        }
    }

    @Nested
    @DisplayName("Invalid Format Tests")
    class InvalidFormatTests {

        @ParameterizedTest
        @ValueSource(strings = {
            "12345678",           // Missing dashes
            "123456789",          // Missing dashes, 9 digits
            "12-345-6789",        // Wrong dash positions
            "123-456-789",        // Wrong dash positions
            "1234-56-789",        // Wrong dash positions
            "123-45-678",         // Too short
            "123-45-67890",       // Too long
            "abc-de-fghi",        // Letters instead of numbers
            "123-4a-6789",        // Letter in group number
            "12a-45-6789",        // Letter in area number
            "123-45-678a",        // Letter in serial number
            "123 45 6789",        // Spaces instead of dashes
            "123.45.6789",        // Dots instead of dashes
            "123/45/6789"         // Slashes instead of dashes
        })
        @DisplayName("should reject SSNs with invalid format")
        void testInvalidFormats(String ssn) {
            SsnValidationResponse response = SsnValidator.validate(ssn);
            assertFalse(response.isValid(), "SSN " + ssn + " should be invalid");
            assertFalse(response.getErrors().isEmpty(), "Invalid SSN should have errors");
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.contains("format") || error.contains("Format")),
                "Error should mention format issue");
        }

        @Test
        @DisplayName("should reject null SSN")
        void testNullSsn() {
            SsnValidationResponse response = SsnValidator.validate(null);
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.contains("null") || error.contains("required") ||
                                   error.contains("blank") || error.contains("empty")));
        }

        @Test
        @DisplayName("should reject empty SSN")
        void testEmptySsn() {
            SsnValidationResponse response = SsnValidator.validate("");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
        }

        @Test
        @DisplayName("should reject blank SSN")
        void testBlankSsn() {
            SsnValidationResponse response = SsnValidator.validate("   ");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
        }
    }

    @Nested
    @DisplayName("Invalid Area Number Tests")
    class InvalidAreaNumberTests {

        @Test
        @DisplayName("should reject area number 000")
        void testAreaNumber000() {
            SsnValidationResponse response = SsnValidator.validate("000-12-3456");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.toLowerCase().contains("area")),
                "Error should mention area number");
        }

        @Test
        @DisplayName("should reject area number 666")
        void testAreaNumber666() {
            SsnValidationResponse response = SsnValidator.validate("666-12-3456");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.toLowerCase().contains("area")));
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "667-12-3456",  // Just above 666
            "899-12-3456"   // Just below 900
        })
        @DisplayName("should reject area numbers 667-899")
        void testInvalidAreaNumbers667to899(String ssn) {
            SsnValidationResponse response = SsnValidator.validate(ssn);
            assertFalse(response.isValid(), "SSN " + ssn + " should be invalid");
            assertFalse(response.getErrors().isEmpty());
        }
    }

    @Nested
    @DisplayName("Invalid Group Number Tests")
    class InvalidGroupNumberTests {

        @Test
        @DisplayName("should reject group number 00")
        void testGroupNumber00() {
            SsnValidationResponse response = SsnValidator.validate("123-00-4567");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.toLowerCase().contains("group")),
                "Error should mention group number");
        }
    }

    @Nested
    @DisplayName("Invalid Serial Number Tests")
    class InvalidSerialNumberTests {

        @Test
        @DisplayName("should reject serial number 0000")
        void testSerialNumber0000() {
            SsnValidationResponse response = SsnValidator.validate("123-45-0000");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.toLowerCase().contains("serial")),
                "Error should mention serial number");
        }
    }

    @Nested
    @DisplayName("Known Invalid SSN Tests")
    class KnownInvalidSsnTests {

        @Test
        @DisplayName("should reject known test SSN 078-05-1120")
        void testKnownInvalidSsn078051120() {
            SsnValidationResponse response = SsnValidator.validate("078-05-1120");
            assertFalse(response.isValid());
            assertFalse(response.getErrors().isEmpty());
            assertTrue(response.getErrors().stream()
                .anyMatch(error -> error.toLowerCase().contains("invalid") ||
                                   error.toLowerCase().contains("test") ||
                                   error.toLowerCase().contains("known")),
                "Error should mention this is a known invalid SSN");
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "219-09-9999",  // Woolworth's wallet promotional SSN
            "457-55-5462"   // Another known invalid SSN
        })
        @DisplayName("should reject other known invalid SSNs")
        void testOtherKnownInvalidSsns(String ssn) {
            SsnValidationResponse response = SsnValidator.validate(ssn);
            assertFalse(response.isValid(), "Known invalid SSN " + ssn + " should be rejected");
            assertFalse(response.getErrors().isEmpty());
        }
    }

    @Nested
    @DisplayName("Edge Cases")
    class EdgeCaseTests {

        @Test
        @DisplayName("should handle SSN with leading/trailing whitespace")
        void testSsnWithWhitespace() {
            SsnValidationResponse response = SsnValidator.validate("  123-45-6789  ");
            // Should either trim and validate, or reject with format error
            assertNotNull(response);
        }

        @Test
        @DisplayName("should provide multiple errors for multiple violations")
        void testMultipleViolations() {
            // SSN with multiple issues: invalid format AND invalid area
            SsnValidationResponse response = SsnValidator.validate("000-00-0000");
            assertFalse(response.isValid());
            // Should have errors for area 000, group 00, and serial 0000
            assertTrue(response.getErrors().size() >= 2,
                "Should report multiple validation errors");
        }
    }
}
