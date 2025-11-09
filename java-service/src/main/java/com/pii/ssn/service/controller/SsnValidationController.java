package com.pii.ssn.service.controller;

import com.pii.ssn.service.dto.SsnValidationRequest;
import com.pii.ssn.service.dto.SsnValidationResponse;
import com.pii.ssn.service.validator.SsnValidator;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for SSN validation
 * Provides endpoint to validate Social Security Numbers
 */
@RestController
@RequestMapping("/api/ssn")
public class SsnValidationController {

    /**
     * Validates an SSN
     *
     * @param request SsnValidationRequest containing the SSN to validate
     * @return SsnValidationResponse with validation result
     */
    @PostMapping("/validate")
    public ResponseEntity<SsnValidationResponse> validateSsn(@RequestBody SsnValidationRequest request) {
        SsnValidationResponse response = SsnValidator.validate(request.getSsn());
        return ResponseEntity.ok(response);
    }
}
