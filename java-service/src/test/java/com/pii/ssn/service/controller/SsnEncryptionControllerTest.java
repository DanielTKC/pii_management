package com.pii.ssn.service.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pii.ssn.service.dto.SsnDecryptionRequest;
import com.pii.ssn.service.dto.SsnEncryptionRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@DisplayName("SSN Encryption Controller")
class SsnEncryptionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Nested
    @DisplayName("POST /api/ssn/encrypt")
    class EncryptEndpoint {

        @Nested
        @DisplayName("with valid SSN")
        class ValidSsnTests {

            @Test
            @DisplayName("should return 200 OK")
            void testValidSsnReturnsOk() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());
            }

            @Test
            @DisplayName("should return encrypted SSN")
            void testReturnsEncryptedSsn() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.encryptedSsn").exists())
                    .andExpect(jsonPath("$.encryptedSsn").isString())
                    .andExpect(jsonPath("$.encryptedSsn").isNotEmpty());
            }

            @Test
            @DisplayName("should return last four digits")
            void testReturnsLastFour() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.lastFour").value("7890"));
            }

            @Test
            @DisplayName("should produce different encrypted output for same SSN due to IV randomization")
            void testIvRandomization() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                // First encryption
                MvcResult result1 = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andReturn();

                // Second encryption
                MvcResult result2 = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andReturn();

                String encrypted1 = objectMapper.readTree(result1.getResponse().getContentAsString())
                    .get("encryptedSsn").asText();
                String encrypted2 = objectMapper.readTree(result2.getResponse().getContentAsString())
                    .get("encryptedSsn").asText();

                assert !encrypted1.equals(encrypted2) : "Encrypted SSNs should be different due to IV randomization";
            }

            @Test
            @DisplayName("should handle SSN without dashes")
            void testSsnWithoutDashes() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234567890");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.encryptedSsn").exists())
                    .andExpect(jsonPath("$.lastFour").value("7890"));
            }

            @Test
            @DisplayName("should extract correct last four for various SSNs")
            void testLastFourExtraction() throws Exception {
                SsnEncryptionRequest request1 = new SsnEncryptionRequest("001-01-0001");
                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.lastFour").value("0001"));

                SsnEncryptionRequest request2 = new SsnEncryptionRequest("900-99-9999");
                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request2)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.lastFour").value("9999"));
            }
        }

        @Nested
        @DisplayName("with invalid requests")
        class InvalidRequestTests {

            @Test
            @DisplayName("should return 400 Bad Request for missing request body")
            void testMissingRequestBody() throws Exception {
                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 Bad Request for invalid JSON")
            void testInvalidJson() throws Exception {
                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{invalid json}"))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 for null SSN")
            void testNullSsn() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest(null);

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 for empty SSN")
            void testEmptySsn() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 415 Unsupported Media Type for wrong content type")
            void testWrongContentType() throws Exception {
                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.TEXT_PLAIN)
                        .content("234-56-7890"))
                    .andExpect(status().isUnsupportedMediaType());
            }
        }

        @Nested
        @DisplayName("response format validation")
        class ResponseFormatTests {

            @Test
            @DisplayName("should return JSON content type")
            void testJsonContentType() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON));
            }

            @Test
            @DisplayName("should have required fields in response")
            void testRequiredFields() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.encryptedSsn").exists())
                    .andExpect(jsonPath("$.lastFour").exists());
            }

            @Test
            @DisplayName("should not expose plaintext SSN in response")
            void testNoPlaintextInResponse() throws Exception {
                SsnEncryptionRequest request = new SsnEncryptionRequest("234-56-7890");

                MvcResult result = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andReturn();

                String responseBody = result.getResponse().getContentAsString();
                assert !responseBody.contains("234-56-7890") : "Response should not contain plaintext SSN";
                assert !responseBody.contains("234") || responseBody.contains("lastFour") :
                    "Response should not expose area number";
            }
        }
    }

    @Nested
    @DisplayName("POST /api/ssn/decrypt")
    class DecryptEndpoint {

        @Nested
        @DisplayName("with valid encrypted SSN")
        class ValidDecryptionTests {

            @Test
            @DisplayName("should decrypt to original SSN")
            void testDecryptToOriginal() throws Exception {
                // First encrypt an SSN
                SsnEncryptionRequest encryptRequest = new SsnEncryptionRequest("234-56-7890");
                MvcResult encryptResult = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(encryptRequest)))
                    .andExpect(status().isOk())
                    .andReturn();

                String encryptedSsn = objectMapper.readTree(encryptResult.getResponse().getContentAsString())
                    .get("encryptedSsn").asText();

                // Now decrypt it
                SsnDecryptionRequest decryptRequest = new SsnDecryptionRequest(encryptedSsn);
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(decryptRequest)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.ssn").value("234-56-7890"));
            }

            @Test
            @DisplayName("should handle encrypt-decrypt round trip")
            void testRoundTrip() throws Exception {
                String[] testSsns = {"234-56-7890", "001-01-0001", "900-99-9999"};

                for (String originalSsn : testSsns) {
                    // Encrypt
                    SsnEncryptionRequest encryptRequest = new SsnEncryptionRequest(originalSsn);
                    MvcResult encryptResult = mockMvc.perform(post("/api/ssn/encrypt")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(encryptRequest)))
                        .andExpect(status().isOk())
                        .andReturn();

                    String encryptedSsn = objectMapper.readTree(encryptResult.getResponse().getContentAsString())
                        .get("encryptedSsn").asText();

                    // Decrypt
                    SsnDecryptionRequest decryptRequest = new SsnDecryptionRequest(encryptedSsn);
                    mockMvc.perform(post("/api/ssn/decrypt")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(decryptRequest)))
                        .andExpect(status().isOk())
                        .andExpect(jsonPath("$.ssn").value(originalSsn));
                }
            }

            @Test
            @DisplayName("should return 200 OK for valid encrypted SSN")
            void testValidEncryptedSsnReturnsOk() throws Exception {
                // First get a valid encrypted SSN
                SsnEncryptionRequest encryptRequest = new SsnEncryptionRequest("234-56-7890");
                MvcResult encryptResult = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(encryptRequest)))
                    .andExpect(status().isOk())
                    .andReturn();

                String encryptedSsn = objectMapper.readTree(encryptResult.getResponse().getContentAsString())
                    .get("encryptedSsn").asText();

                SsnDecryptionRequest decryptRequest = new SsnDecryptionRequest(encryptedSsn);
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(decryptRequest)))
                    .andExpect(status().isOk());
            }
        }

        @Nested
        @DisplayName("with invalid requests")
        class InvalidDecryptionTests {

            @Test
            @DisplayName("should return 400 for null encrypted SSN")
            void testNullEncryptedSsn() throws Exception {
                SsnDecryptionRequest request = new SsnDecryptionRequest(null);

                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 for empty encrypted SSN")
            void testEmptyEncryptedSsn() throws Exception {
                SsnDecryptionRequest request = new SsnDecryptionRequest("");

                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 for invalid Base64")
            void testInvalidBase64() throws Exception {
                SsnDecryptionRequest request = new SsnDecryptionRequest("not-valid-base64!@#");

                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 for corrupted encrypted data")
            void testCorruptedData() throws Exception {
                SsnDecryptionRequest request = new SsnDecryptionRequest("Y29ycnVwdGVkZGF0YQ==");

                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 Bad Request for missing request body")
            void testMissingRequestBody() throws Exception {
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 Bad Request for invalid JSON")
            void testInvalidJson() throws Exception {
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{invalid json}"))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 415 Unsupported Media Type for wrong content type")
            void testWrongContentType() throws Exception {
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.TEXT_PLAIN)
                        .content("some-encrypted-data"))
                    .andExpect(status().isUnsupportedMediaType());
            }
        }

        @Nested
        @DisplayName("response format validation")
        class ResponseFormatTests {

            @Test
            @DisplayName("should return JSON content type")
            void testJsonContentType() throws Exception {
                // First encrypt
                SsnEncryptionRequest encryptRequest = new SsnEncryptionRequest("234-56-7890");
                MvcResult encryptResult = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(encryptRequest)))
                    .andReturn();

                String encryptedSsn = objectMapper.readTree(encryptResult.getResponse().getContentAsString())
                    .get("encryptedSsn").asText();

                // Then decrypt
                SsnDecryptionRequest decryptRequest = new SsnDecryptionRequest(encryptedSsn);
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(decryptRequest)))
                    .andExpect(status().isOk())
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON));
            }

            @Test
            @DisplayName("should have required fields in response")
            void testRequiredFields() throws Exception {
                // First encrypt
                SsnEncryptionRequest encryptRequest = new SsnEncryptionRequest("234-56-7890");
                MvcResult encryptResult = mockMvc.perform(post("/api/ssn/encrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(encryptRequest)))
                    .andReturn();

                String encryptedSsn = objectMapper.readTree(encryptResult.getResponse().getContentAsString())
                    .get("encryptedSsn").asText();

                // Then decrypt
                SsnDecryptionRequest decryptRequest = new SsnDecryptionRequest(encryptedSsn);
                mockMvc.perform(post("/api/ssn/decrypt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(decryptRequest)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.ssn").exists())
                    .andExpect(jsonPath("$.ssn").isString());
            }
        }
    }
}
