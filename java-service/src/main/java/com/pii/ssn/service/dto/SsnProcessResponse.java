package com.pii.ssn.service.dto;

import java.util.ArrayList;
import java.util.List;
/**
 * Response DTO for SSN processing
 */

public class SsnProcessResponse {
    private boolean valid;
    private List<String> errors;
    private String encryptedSsn;
    private String lastFour;

    public SsnProcessResponse() {
        this.errors = new ArrayList<>();
    }

    public SsnProcessResponse(boolean valid, List<String> errors) {
        this.valid = valid;
        this.errors = errors != null ? errors : new ArrayList<>();
    }

    public SsnProcessResponse(boolean valid, List<String> errors, String encryptedSsn, String lastFour) {
        this.valid = valid;
        this.errors = errors != null ? errors : new ArrayList<>();
        this.encryptedSsn = encryptedSsn;
        this.lastFour = lastFour;
    }

    public boolean isValid() {
        return valid;
    }

    public void setValid(boolean valid) {
        this.valid = valid;
    }

    public List<String> getErrors() {
        return errors;
    }

    public void setErrors(List<String> errors) {
        this.errors = errors;
    }

    public void addError(String error) {
        this.errors.add(error);
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
