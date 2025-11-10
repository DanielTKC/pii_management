/**
 * Format SSN input with dashes (XXX-XX-XXXX)
 * @param {string} value - Input value
 * @returns {string} Formatted SSN
 */
export function formatSSN(value) {
  // Remove all non-digit characters
  const digits = value.replace(/\D/g, '')

  // Apply formatting based on length
  if (digits.length <= 3) {
    return digits
  } else if (digits.length <= 5) {
    return `${digits.slice(0, 3)}-${digits.slice(3)}`
  } else {
    return `${digits.slice(0, 3)}-${digits.slice(3, 5)}-${digits.slice(5, 9)}`
  }
}

/**
 * Validate SSN format (basic client-side check)
 * @param {string} ssn - SSN to validate
 * @returns {boolean} True if valid format
 */
export function isValidSSNFormat(ssn) {
  // Check if it matches XXX-XX-XXXX pattern
  const ssnRegex = /^\d{3}-\d{2}-\d{4}$/
  return ssnRegex.test(ssn)
}

/**
 * Check if SSN has obviously invalid values
 * @param {string} ssn - SSN to validate
 * @returns {string|null} Error message or null if valid
 */
export function validateSSN(ssn) {
  if (!ssn) {
    return 'SSN is required'
  }

  if (!isValidSSNFormat(ssn)) {
    return 'SSN must be in format XXX-XX-XXXX'
  }

  const [area, group, serial] = ssn.split('-')

  // Check for all zeros
  if (area === '000') {
    return 'Area number cannot be 000'
  }

  if (group === '00') {
    return 'Group number cannot be 00'
  }

  if (serial === '0000') {
    return 'Serial number cannot be 0000'
  }

  // Check for 666
  if (area === '666') {
    return 'Area number cannot be 666'
  }

  // Known invalid SSNs
  const knownInvalid = ['078-05-1120', '219-09-9999', '123-45-6789']
  if (knownInvalid.includes(ssn)) {
    return 'This SSN is known to be invalid'
  }

  return null
}

/**
 * Display SSN with masking (***-**-XXXX)
 * @param {string} ssn - Full or partial SSN
 * @returns {string} Masked SSN
 */
export function maskSSN(ssn) {
  if (!ssn) return '***-**-****'

  // If already masked, return as is
  if (ssn.startsWith('***')) return ssn

  // If it's just last 4 digits
  if (ssn.length === 4 && /^\d{4}$/.test(ssn)) {
    return `***-**-${ssn}`
  }

  // If it's a full SSN, mask first 5 digits
  if (isValidSSNFormat(ssn)) {
    const lastFour = ssn.slice(-4)
    return `***-**-${lastFour}`
  }

  return '***-**-****'
}
