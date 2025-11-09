package com.pii.ssn.service.dto;

import java.util.ArrayList;
import java.util.List;


public class SsnValidationResponse {
    private boolean valid;
    private List<String> errors;

    public SsnValidationResponse() {

        this.errors = new ArrayList<>();
    }

    public SsnValidationResponse(boolean valid, List<String> errors) {

        this.valid = valid;
        this.errors = errors != null ? errors : new ArrayList<>();
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
    
}
