package com.pii.ssn.service.dto;
/**
 * Request DTO for SSN encryption
 */
public class SsnEncryptionRequest {
    private String ssn;

    public SsnEncryptionRequest() {
    }

    public SsnEncryptionRequest(String ssn) {
        this.ssn = ssn;
    }

    public String getSsn() {
        return ssn;
    }

    public void setSsn(String ssn) {
        this.ssn = ssn;
    }
}
