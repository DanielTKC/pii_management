package com.pii.ssn.service.dto;

/**
 * Response DTO for SSN decryption
 */
public class SsnDecryptionResponse {
    private String ssn;

    public SsnDecryptionResponse() {
    }

    public SsnDecryptionResponse(String ssn) {
        this.ssn = ssn;
    }

    public String getSsn() {
        return ssn;
    }

    public void setSsn(String ssn) {
        this.ssn = ssn;
    }
}
