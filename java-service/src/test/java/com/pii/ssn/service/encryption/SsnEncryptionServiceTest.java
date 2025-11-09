package com.pii.ssn.service.encryption;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("SSN Encryption Service")
class SsnEncryptionServiceTest {

    private SsnEncryptionService encryptionService;

    @BeforeEach
    void setUp() {
        // Generate a test key dynamically for each test run (never hardcode keys in source)
        byte[] testKeyBytes = new byte[32]; // 32 bytes for AES-256
        new java.security.SecureRandom().nextBytes(testKeyBytes);
        String testKey = java.util.Base64.getEncoder().encodeToString(testKeyBytes);

        encryptionService = new SsnEncryptionService(testKey);
    }

    @Nested
    @DisplayName("Encryption Tests")
    class EncryptionTests {

        @Test
        @DisplayName("should encrypt a valid SSN")
        void testEncryptValidSsn() {
            String ssn = "234-56-7890";

            String encrypted = encryptionService.encrypt(ssn);

            assertNotNull(encrypted);
            assertFalse(encrypted.isEmpty());
            assertNotEquals(ssn, encrypted);
        }

        @Test
        @DisplayName("should produce different encrypted output for same input due to IV randomization")
        void testIvRandomization() {
            String ssn = "234-56-7890";

            String encrypted1 = encryptionService.encrypt(ssn);
            String encrypted2 = encryptionService.encrypt(ssn);

            assertNotNull(encrypted1);
            assertNotNull(encrypted2);
            assertNotEquals(encrypted1, encrypted2,
                    "Encrypting the same SSN twice should produce different ciphertext due to random IV");
        }

        @Test
        @DisplayName("should return Base64-encoded string")
        void testBase64Encoding() {
            String ssn = "234-56-7890";

            String encrypted = encryptionService.encrypt(ssn);

            assertDoesNotThrow(() -> Base64.getDecoder().decode(encrypted),
                    "Encrypted SSN should be valid Base64");
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "234-56-7890",
            "001-01-0001",
            "900-99-9999",
            "665-88-7777"
        })
        @DisplayName("should encrypt various valid SSN formats")
        void testEncryptVariousSsns(String ssn) {
            String encrypted = encryptionService.encrypt(ssn);

            assertNotNull(encrypted);
            assertFalse(encrypted.isEmpty());
        }

        @Test
        @DisplayName("should throw exception for null SSN")
        void testEncryptNullSsn() {
            assertThrows(Exception.class, () -> {
                encryptionService.encrypt(null);
            });
        }

        @Test
        @DisplayName("should throw exception for empty SSN")
        void testEncryptEmptySsn() {
            assertThrows(Exception.class, () -> {
                encryptionService.encrypt("");
            });
        }
    }

    @Nested
    @DisplayName("Decryption Tests")
    class DecryptionTests {

        @Test
        @DisplayName("should decrypt encrypted SSN back to original")
        void testDecryptToOriginal() {
            String originalSsn = "234-56-7890";

            String encrypted = encryptionService.encrypt(originalSsn);
            String decrypted = encryptionService.decrypt(encrypted);

            assertEquals(originalSsn, decrypted);
        }

        @Test
        @DisplayName("should successfully complete encrypt-decrypt round trip")
        void testEncryptDecryptRoundTrip() {
            String originalSsn = "234-56-7890";

            String encrypted = encryptionService.encrypt(originalSsn);
            String decrypted = encryptionService.decrypt(encrypted);

            assertEquals(originalSsn, decrypted,
                    "Decrypted SSN should match original after round trip");
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "234-56-7890",
            "001-01-0001",
            "900-99-9999",
            "665-88-7777"
        })
        @DisplayName("should handle round trip for various SSNs")
        void testRoundTripVariousSsns(String originalSsn) {
            String encrypted = encryptionService.encrypt(originalSsn);
            String decrypted = encryptionService.decrypt(encrypted);

            assertEquals(originalSsn, decrypted);
        }

        @Test
        @DisplayName("should throw exception for null encrypted data")
        void testDecryptNull() {
            assertThrows(Exception.class, () -> {
                encryptionService.decrypt(null);
            });
        }

        @Test
        @DisplayName("should throw exception for empty encrypted data")
        void testDecryptEmpty() {
            assertThrows(Exception.class, () -> {
                encryptionService.decrypt("");
            });
        }

        @Test
        @DisplayName("should throw exception for corrupted encrypted data")
        void testDecryptCorruptedData() {
            String corrupted = "corrupted-base64-data-!@#$";

            assertThrows(Exception.class, () -> {
                encryptionService.decrypt(corrupted);
            });
        }

        @Test
        @DisplayName("should throw exception for invalid Base64")
        void testDecryptInvalidBase64() {
            String invalidBase64 = "not valid base64!@#";

            assertThrows(Exception.class, () -> {
                encryptionService.decrypt(invalidBase64);
            });
        }

        @Test
        @DisplayName("should throw exception for tampered encrypted data")
        void testDecryptTamperedData() {
            String originalSsn = "234-56-7890";
            String encrypted = encryptionService.encrypt(originalSsn);

            // Tamper with the encrypted data
            byte[] encryptedBytes = Base64.getDecoder().decode(encrypted);
            encryptedBytes[encryptedBytes.length - 1] ^= 1; // Flip one bit
            String tamperedEncrypted = Base64.getEncoder().encodeToString(encryptedBytes);

            assertThrows(Exception.class, () -> {
                encryptionService.decrypt(tamperedEncrypted);
            }, "Decryption should fail for tampered data due to authentication tag verification");
        }
    }

    @Nested
    @DisplayName("Last Four Extraction Tests")
    class LastFourTests {

        @Test
        @DisplayName("should extract last four digits from SSN")
        void testExtractLastFour() {
            String ssn = "234-56-7890";

            String lastFour = encryptionService.extractLastFour(ssn);

            assertEquals("7890", lastFour);
        }

        @ParameterizedTest
        @ValueSource(strings = {
            "234-56-7890",
            "001-01-0001",
            "900-99-9999",
            "665-88-1234"
        })
        @DisplayName("should extract correct last four for various SSNs")
        void testExtractLastFourVariousSsns(String ssn) {
            String expectedLastFour = ssn.substring(7); // Last 4 chars after "XXX-XX-"

            String lastFour = encryptionService.extractLastFour(ssn);

            assertEquals(expectedLastFour, lastFour);
        }

        @Test
        @DisplayName("should handle SSN with leading zeros in last four")
        void testLastFourWithLeadingZeros() {
            String ssn = "234-56-0001";

            String lastFour = encryptionService.extractLastFour(ssn);

            assertEquals("0001", lastFour);
        }

        @Test
        @DisplayName("should throw exception for null SSN")
        void testExtractLastFourNull() {
            assertThrows(Exception.class, () -> {
                encryptionService.extractLastFour(null);
            });
        }

        @Test
        @DisplayName("should throw exception for invalid SSN format")
        void testExtractLastFourInvalidFormat() {
            assertThrows(Exception.class, () -> {
                encryptionService.extractLastFour("invalid");
            });
        }

        @Test
        @DisplayName("should throw exception for SSN without dashes")
        void testExtractLastFourNoDashes() {
            assertThrows(Exception.class, () -> {
                encryptionService.extractLastFour("234567890");
            });
        }
    }

    @Nested
    @DisplayName("Key Management Tests")
    class KeyManagementTests {

        @Test
        @DisplayName("should fail to decrypt with wrong key")
        void testDecryptWithWrongKey() {
            String originalSsn = "234-56-7890";

            // Encrypt with original key
            String encrypted = encryptionService.encrypt(originalSsn);

            // Create service with different key
            byte[] wrongKeyBytes = new byte[32];
            for (int i = 0; i < 32; i++) {
                wrongKeyBytes[i] = (byte) (i + 1); // Different key
            }
            String wrongKeyBase64 = Base64.getEncoder().encodeToString(wrongKeyBytes);
            SsnEncryptionService wrongKeyService = new SsnEncryptionService(wrongKeyBase64);

            // Attempt to decrypt with wrong key should fail
            assertThrows(Exception.class, () -> {
                wrongKeyService.decrypt(encrypted);
            }, "Decryption with wrong key should fail");
        }

        @Test
        @DisplayName("should throw exception when initialized with null key")
        void testNullKey() {
            assertThrows(Exception.class, () -> {
                new SsnEncryptionService(null);
            });
        }

        @Test
        @DisplayName("should throw exception when initialized with invalid key size")
        void testInvalidKeySize() {
            // Create a key that's not 256 bits (32 bytes)
            byte[] shortKeyBytes = new byte[16]; // Only 128 bits
            String shortKeyBase64 = Base64.getEncoder().encodeToString(shortKeyBytes);

            assertThrows(Exception.class, () -> {
                new SsnEncryptionService(shortKeyBase64);
            });
        }
    }

    @Nested
    @DisplayName("Integration Tests")
    class IntegrationTests {

        @Test
        @DisplayName("should encrypt, extract last four, and decrypt consistently")
        void testFullWorkflow() {
            String originalSsn = "234-56-7890";

            // Encrypt
            String encrypted = encryptionService.encrypt(originalSsn);
            assertNotNull(encrypted);

            // Extract last four
            String lastFour = encryptionService.extractLastFour(originalSsn);
            assertEquals("7890", lastFour);

            // Decrypt
            String decrypted = encryptionService.decrypt(encrypted);
            assertEquals(originalSsn, decrypted);
        }

        @Test
        @DisplayName("should handle multiple encrypt operations independently")
        void testMultipleEncryptions() {
            String ssn1 = "234-56-7890";
            String ssn2 = "900-11-2233";

            String encrypted1 = encryptionService.encrypt(ssn1);
            String encrypted2 = encryptionService.encrypt(ssn2);

            assertNotEquals(encrypted1, encrypted2);

            assertEquals(ssn1, encryptionService.decrypt(encrypted1));
            assertEquals(ssn2, encryptionService.decrypt(encrypted2));
        }

        @Test
        @DisplayName("should maintain data integrity over multiple operations")
        void testDataIntegrityMultipleOps() {
            String[] ssns = {
                "234-56-7890",
                "001-01-0001",
                "900-99-9999",
                "665-88-7777"
            };

            for (String ssn : ssns) {
                String encrypted = encryptionService.encrypt(ssn);
                String decrypted = encryptionService.decrypt(encrypted);
                assertEquals(ssn, decrypted,
                        "Data integrity should be maintained for SSN: " + ssn);
            }
        }
    }

    @Nested
    @DisplayName("Security Tests")
    class SecurityTests {

        @Test
        @DisplayName("should not expose plaintext SSN in encrypted output")
        void testNoPlaintextInEncrypted() {
            String ssn = "234-56-7890";

            String encrypted = encryptionService.encrypt(ssn);

            assertFalse(encrypted.contains("234"));
            assertFalse(encrypted.contains("56"));
            assertFalse(encrypted.contains("7890"));
            assertFalse(encrypted.contains(ssn));
        }

        @Test
        @DisplayName("should use authenticated encryption (GCM mode)")
        void testAuthenticatedEncryption() {
            String originalSsn = "234-56-7890";
            String encrypted = encryptionService.encrypt(originalSsn);

            // Try to tamper with encrypted data
            byte[] encryptedBytes = Base64.getDecoder().decode(encrypted);

            // Modify a byte (this should break the authentication tag)
            if (encryptedBytes.length > 20) {
                encryptedBytes[20] ^= 1;
            }

            String tamperedEncrypted = Base64.getEncoder().encodeToString(encryptedBytes);

            // Decryption should fail due to authentication failure
            assertThrows(Exception.class, () -> {
                encryptionService.decrypt(tamperedEncrypted);
            }, "GCM mode should detect tampering");
        }
    }
}
