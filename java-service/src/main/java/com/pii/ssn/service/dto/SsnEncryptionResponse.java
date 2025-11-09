package com.pii.ssn.service.dto;
/**
 * Response DTO for SSN encryption
 */
public class SsnEncryptionResponse {
    private String encryptedSsn;
    private String lastFour;

    public SsnEncryptionResponse() {
    }

    public SsnEncryptionResponse(String encryptedSsn, String lastFour) {
        this.encryptedSsn = encryptedSsn;
        this.lastFour = lastFour;
    }

    public String getEncryptedSsn() {
        return encryptedSsn;
    }

    public void setEncryptedSsn(String encryptedSsn) {
        this.encryptedSsn = encryptedSsn;
    }

    public String getLastFour() {
        return lastFour;
    }

    public void setLastFour(String lastFour) {
        this.lastFour = lastFour;
    }
}
