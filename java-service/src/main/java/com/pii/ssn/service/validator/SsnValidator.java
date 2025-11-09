package com.pii.ssn.service.validator;

import com.pii.ssn.service.dto.SsnValidationResponse;
import java.util.regex.Pattern;
import java.util.Set;
import java.util.HashSet;

/**
 * SSN Validator class to validate Social Security Numbers (SSNs).
 */
public class SsnValidator {

    private static final Pattern SSN_PATTERN = Pattern.compile("^(\\d{3})-(\\d{2})-(\\d{4})$");
    private static final Set<String> INVALID_SSNS = new HashSet<>();

    static {
        INVALID_SSNS.add("078-05-1120");
        INVALID_SSNS.add("219-09-9999");
        INVALID_SSNS.add("457-55-5462");
    }

    /**
     * Validates the given SSN.
     *
     * @param ssn the SSN to validate
     * @return SsnValidationResponse containing validation result and errors if
     * any
     */
    public static SsnValidationResponse validate(String ssn) {
        SsnValidationResponse response = new SsnValidationResponse();

        if (ssn == null || ssn.trim().isEmpty()) {
            response.setValid(false);
            response.addError("SSN cannot be null or empty.");
            return response;
        }

        String trimmedSsn = ssn.trim();

        if (!SSN_PATTERN.matcher(trimmedSsn).matches()) {
            response.setValid(false);
            String withoutDashes = trimmedSsn.replace("-", "");
            if (!withoutDashes.matches("\\d*")) {
                response.addError("SSN must contain only numeric digits and dashes.");
            }
            response.addError("SSN format is invalid. Expected format is XXX-XX-XXXX.");
            return response;
        }

        if (INVALID_SSNS.contains(trimmedSsn)) {
            response.setValid(false);
            response.addError("SSN is known to be invalid.");
            return response;
        }

        String[] parts = trimmedSsn.split("-");
        String area = parts[0];
        String group = parts[1];
        String serial = parts[2];

        int areaNum = Integer.parseInt(area);

        boolean hasErrors = false;


        /*
        SSN Validation Requirements
        Implement validation per SSA standards:
        - Must be 9 digits in XXX-XX-XXXX format
        - Area number (first 3 digits) cannot be 000 or 666
        -- Area number may allow 900-999
        - Group number (middle 2 digits) cannot be 00
        - Serial number (last 4 digits) cannot be 0000
        - Must not be a known invalid test SSN (e.g., 078-05-1120)
        */

       if (area.equals("000")) {
            response.addError("Area number cannot be 000.");
            hasErrors = true;
        } else if (area.equals("666")) {
            response.addError("Area number cannot be 666.");
            hasErrors = true;
        } else if (areaNum >= 900 && areaNum <= 999) {
            // Area numbers 900-999 are allowed for individual taxpayers
        }

        if (group.equals("00")) {
            response.addError("Group number cannot be 00.");
            hasErrors = true;
        }

        if (serial.equals("0000")) {
            response.addError("Serial number cannot be 0000.");
            hasErrors = true;
        }




        response.setValid(!hasErrors);
        return response;
    }
}
