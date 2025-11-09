# frozen_string_literal: true

# Mirrors the validation logic from the Java SsnValidator
class SsnValidator
  # Known invalid SSNs that should always be rejected
  KNOWN_INVALID_SSNS = [
    '078-05-1120', # Woolworth's wallet card SSN
    '219-09-9999', # Widely publicized SSN
    '123-45-6789'  # Common placeholder SSN
  ].freeze

  # SSN format patterns
  SSN_WITH_DASHES = /\A\d{3}-\d{2}-\d{4}\z/
  SSN_WITHOUT_DASHES = /\A\d{9}\z/

  # Validates an SSN and returns a hash with validation results
  #
  # @param ssn [String, nil] The SSN to validate
  # @return [Hash] { valid: Boolean, errors: Array<String> }
  def self.validate(ssn)
    errors = []

    # Check for null/empty
    if ssn.nil? || ssn.to_s.strip.empty?
      return { valid: false, errors: ['SSN cannot be null or empty.'] }
    end

    ssn = ssn.to_s.strip

    # Check for invalid characters
    unless ssn.match?(/\A[\d-]+\z/)
      errors << 'SSN must contain only digits and dashes.'
      return { valid: false, errors: errors }
    end

    # Extract digits only
    digits = ssn.gsub('-', '')

    # Check length first (more specific error)
    unless digits.length == 9
      errors << 'SSN must be 9 digits.'
      return { valid: false, errors: errors }
    end

    # Check format (XXX-XX-XXXX or XXXXXXXXX)
    unless ssn.match?(SSN_WITH_DASHES) || ssn.match?(SSN_WITHOUT_DASHES)
      errors << 'SSN format must be XXX-XX-XXXX or XXXXXXXXX.'
      return { valid: false, errors: errors }
    end

    # Normalize to XXX-XX-XXXX format for checking
    normalized_ssn = "#{digits[0..2]}-#{digits[3..4]}-#{digits[5..8]}"

    # Check if it's a known invalid SSN
    if KNOWN_INVALID_SSNS.include?(normalized_ssn)

      errors << 'This SSN is a known invalid number.'
    end

    # Extract area, group, and serial numbers
    area_number = digits[0..2].to_i
    group_number = digits[3..4].to_i
    serial_number = digits[5..8].to_i

    # Validate area number
    if area_number == 0
      errors << 'Area number cannot be 000.'
    elsif area_number == 666
      errors << 'Area number cannot be 666.'
    end
    # Note: 900-999 are now valid (used for ITIN purposes)

    # Validate group number
    if group_number == 0
      errors << 'Group number cannot be 00.'
    end

    # Validate serial number
    if serial_number == 0
      errors << 'Serial number cannot be 0000.'
    end
    

    {
      valid: errors.empty?,
      errors: errors
    }
  end
end
