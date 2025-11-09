package com.pii.ssn.service.dto;

public class SsnValidationRequest {
    private String ssn;

    public SsnValidationRequest() {
    }

    public SsnValidationRequest(String ssn) {
        this.ssn = ssn;
    }

    public String getSsn() {
        return ssn;
    }

    public void setSsn(String ssn) {
        this.ssn = ssn;
    }
}
