package com.pii.ssn.service.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pii.ssn.service.dto.SsnValidationRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@DisplayName("SSN Validation Controller")
class SsnValidationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Nested
    @DisplayName("POST /api/ssn/validate")
    class ValidateEndpoint {

        @Nested
        @DisplayName("with valid SSN")
        class ValidSsnTests {

            @Test
            @DisplayName("should return 200 OK")
            void testValidSsnReturnsOk() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());
            }

            @Test
            @DisplayName("should return valid:true in response")
            void testValidSsnReturnsValidTrue() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(true));
            }

            @Test
            @DisplayName("should return empty errors array")
            void testValidSsnReturnsEmptyErrors() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(true))
                    .andExpect(jsonPath("$.errors").isArray())
                    .andExpect(jsonPath("$.errors").isEmpty());
            }

            @Test
            @DisplayName("should validate SSN with area 900-999")
            void testValidSsnWithAreaNumber900Range() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("900-12-3456");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(true));
            }
        }

        @Nested
        @DisplayName("with invalid SSN")
        class InvalidSsnTests {

            @Test
            @DisplayName("should return 200 OK with valid:false for invalid format")
            void testInvalidFormatReturnsValidFalse() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234567890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false));
            }

            @Test
            @DisplayName("should return errors array for invalid SSN")
            void testInvalidSsnReturnsErrors() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234567890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isArray())
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject SSN with area 000")
            void testAreaNumber000() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("000-12-3456");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject SSN with area 666")
            void testAreaNumber666() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("666-12-3456");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject SSN with group 00")
            void testGroupNumber00() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234-00-4567");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject SSN with serial 0000")
            void testSerialNumber0000() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234-45-0000");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject known invalid SSN 078-05-1120")
            void testKnownInvalidSsn078051120() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("078-05-1120");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject known invalid SSN 123-45-6789")
            void testKnownInvalidSsn123456789() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("123-45-6789");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should reject known invalid SSN 219-09-9999")
            void testKnownInvalidSsn219099999() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("219-09-9999");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }
        }

        @Nested
        @DisplayName("with malformed requests")
        class MalformedRequestTests {

            @Test
            @DisplayName("should return 400 Bad Request for missing request body")
            void testMissingRequestBody() throws Exception {
                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should return 400 Bad Request for invalid JSON")
            void testInvalidJson() throws Exception {
                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{invalid json}"))
                    .andExpect(status().isBadRequest());
            }

            @Test
            @DisplayName("should handle null SSN in request")
            void testNullSsnInRequest() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest(null);

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should handle empty SSN in request")
            void testEmptySsnInRequest() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").value(false))
                    .andExpect(jsonPath("$.errors").isNotEmpty());
            }

            @Test
            @DisplayName("should return 415 Unsupported Media Type for wrong content type")
            void testWrongContentType() throws Exception {
                mockMvc.perform(post("/api/ssn/validate")
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
                SsnValidationRequest request = new SsnValidationRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON));
            }

            @Test
            @DisplayName("should have required fields in response")
            void testRequiredFieldsInResponse() throws Exception {
                SsnValidationRequest request = new SsnValidationRequest("234-56-7890");

                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").exists())
                    .andExpect(jsonPath("$.errors").exists())
                    .andExpect(jsonPath("$.errors").isArray());
            }

            @Test
            @DisplayName("should return consistent response structure for valid and invalid SSNs")
            void testConsistentResponseStructure() throws Exception {
                // Valid SSN
                SsnValidationRequest validRequest = new SsnValidationRequest("234-56-7890");
                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").exists())
                    .andExpect(jsonPath("$.errors").exists());

                // Invalid SSN
                SsnValidationRequest invalidRequest = new SsnValidationRequest("000-00-0000");
                mockMvc.perform(post("/api/ssn/validate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.valid").exists())
                    .andExpect(jsonPath("$.errors").exists());
            }
        }
    }
}
