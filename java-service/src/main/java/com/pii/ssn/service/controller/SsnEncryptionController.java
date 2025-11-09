package com.pii.ssn.service.controller;

import com.pii.ssn.service.dto.*;
import com.pii.ssn.service.encryption.SsnEncryptionService;
import com.pii.ssn.service.validator.SsnValidator;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * REST Controller for SSN encryption/decryption operations
 */
@RestController
@RequestMapping("/api/ssn")
public class SsnEncryptionController {

    private final SsnEncryptionService encryptionService;


    public SsnEncryptionController(SsnEncryptionService encryptionService) {
        this.encryptionService = encryptionService;
    }

    /**
     * Encrypts an SSN
     *
     * @param request 
     * @return SsnEncryptionResponse with encrypted SSN and last four digits
     */
    @PostMapping("/encrypt")
    public ResponseEntity<?> encrypt(@RequestBody SsnEncryptionRequest request) {
        try {
            if (request.getSsn() == null || request.getSsn().trim().isEmpty()) {
                return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", "SSN cannot be null or empty"));
            }

            String encryptedSsn = encryptionService.encrypt(request.getSsn());
            String lastFour = encryptionService.extractLastFour(request.getSsn());

            SsnEncryptionResponse response = new SsnEncryptionResponse(encryptedSsn, lastFour);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity
                .badRequest()
                .body(Map.of("error", "Failed to encrypt SSN: " + e.getMessage()));
        }
    }

    /**
     * Decrypts an encrypted SSN
     *
     * @param request SsnDecryptionRequest containing encrypted SSN
     * @return SsnDecryptionResponse with plaintext SSN
     */
    @PostMapping("/decrypt")
    public ResponseEntity<?> decrypt(@RequestBody SsnDecryptionRequest request) {
        try {
            if (request.getEncryptedSsn() == null || request.getEncryptedSsn().trim().isEmpty()) {
                return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", "Encrypted SSN cannot be null or empty"));
            }

            String ssn = encryptionService.decrypt(request.getEncryptedSsn());
            SsnDecryptionResponse response = new SsnDecryptionResponse(ssn);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity
                .badRequest()
                .body(Map.of("error", "Failed to decrypt SSN: " + e.getMessage()));
        }
    }

    /**
     * Validates and encrypts an SSN in one operation
     * This is the primary endpoint that Rails will call
     *
     * @param request SsnProcessRequest containing plaintext SSN
     * @return SsnProcessResponse with validation result and encrypted SSN if valid
     */
    @PostMapping("/process")
    public ResponseEntity<?> process(@RequestBody SsnProcessRequest request) {
        try {
            if (request.getSsn() == null || request.getSsn().trim().isEmpty()) {
                return ResponseEntity
                    .badRequest()
                    .body(Map.of("error", "SSN cannot be null or empty"));
            }

            // First validate the SSN
            SsnValidationResponse validationResult = SsnValidator.validate(request.getSsn());

            if (!validationResult.isValid()) {
                // Return validation errors without encrypting
                SsnProcessResponse response = new SsnProcessResponse(
                    false,
                    validationResult.getErrors(),
                    null,
                    null
                );
                return ResponseEntity.ok(response);
            }

            // SSN is valid, encrypt it
            String encryptedSsn = encryptionService.encrypt(request.getSsn());
            String lastFour = encryptionService.extractLastFour(request.getSsn());

            SsnProcessResponse response = new SsnProcessResponse(
                true,
                validationResult.getErrors(),
                encryptedSsn,
                lastFour
            );
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity
                .badRequest()
                .body(Map.of("error", "Failed to process SSN: " + e.getMessage()));
        }
    }
}
