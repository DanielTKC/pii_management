package com.pii.ssn.service.dto;

/**
 * Request DTO for SSN decryption
 */
public class SsnDecryptionRequest {
    private String encryptedSsn;

    public SsnDecryptionRequest() {
    }

    public SsnDecryptionRequest(String encryptedSsn) {
        this.encryptedSsn = encryptedSsn;
    }

    public String getEncryptedSsn() {
        return encryptedSsn;
    }

    public void setEncryptedSsn(String encryptedSsn) {
        this.encryptedSsn = encryptedSsn;
    }
}
