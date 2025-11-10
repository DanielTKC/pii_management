# frozen_string_literal: true

# Model for storing Personally Identifiable Information (PII) records
# SSNs are encrypted by the Java microservice before being stored in the database
class PiiRecord < ApplicationRecord
  belongs_to :user, optional: true

  # Virtual attribute for accepting plaintext SSN (write-only)
  attr_accessor :ssn

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :middle_name, length: { maximum: 50 }, allow_nil: true
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :ssn, presence: true, on: :create
  validates :ssn_encrypted, uniqueness: true
  validates :street_address_1, presence: true
  validates :city, presence: true
  validates :state, presence: true, format: {
    with: /\A[A-Z]{2}\z/,
    message: 'must be 2 uppercase letters (e.g., IL, CA, NY)'
  }
  validates :zip_code, presence: true, format: {
    with: /\A\d{5}(-\d{4})?\z/,
    message: 'must be in format 12345 or 12345-6789'
  }
  validates :email, format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: 'is invalid'
  }, allow_blank: true

  # Callbacks
  before_validation :set_middle_name_to_na, if: :middle_name_override?
  before_validation :validate_and_encrypt_ssn, if: :ssn_present?

  # Scopes
  scope :active, -> { where(deleted_at: nil) }

  # Display SSN with only last 4 digits visible
  # @return [String] Obfuscated SSN in format ***-**-XXXX
  def display_ssn
    "***-**-#{ssn_last_four}"
  end

  # Soft delete the record by setting deleted_at timestamp
  # @return [Boolean] true if successful
  def soft_delete
    update(deleted_at: Time.current)
  end

  # Check if record is soft-deleted
  # @return [Boolean] true if deleted_at is present
  def deleted?
    deleted_at.present?
  end

  private

  # Set middle_name to "N/A" when middle_name_override is true
  def set_middle_name_to_na
    self.middle_name = 'N/A'
  end

  # Check if SSN is present for validation
  def ssn_present?
    ssn.present?
  end

  # Validate and encrypt SSN using JavaSsnClient
  # Adds validation errors if SSN is invalid
  # Sets ssn_encrypted and ssn_last_four if valid
  def validate_and_encrypt_ssn
    result = JavaSsnClient.process(ssn)

    if result['valid']
      self.ssn_encrypted = result['encrypted_ssn']
      self.ssn_last_four = result['last_four']
    else
      # Add each validation error from Java service
      result['errors'].each do |error|
        errors.add(:ssn, error)
      end
    end
  rescue JavaSsnClient::ConnectionError, JavaSsnClient::TimeoutError, JavaSsnClient::ServiceError => e
    errors.add(:ssn, e.message)
  end
end
