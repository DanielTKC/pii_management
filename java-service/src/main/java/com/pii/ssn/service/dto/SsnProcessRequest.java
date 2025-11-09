package com.pii.ssn.service.dto;
/**
 * Request DTO for SSN processing
 */
public class SsnProcessRequest {
    private String ssn;

    public SsnProcessRequest() {
    }

    public SsnProcessRequest(String ssn) {
        this.ssn = ssn;
    }

    public String getSsn() {
        return ssn;
    }

    public void setSsn(String ssn) {
        this.ssn = ssn;
    }
}
