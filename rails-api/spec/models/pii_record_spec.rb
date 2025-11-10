# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PiiRecord, type: :model do
  let(:user) { create(:user) }
  let(:valid_ssn) { '234-56-7890' }
  let(:valid_attributes) do
    {
      first_name: 'John',
      last_name: 'Doe',
      ssn: valid_ssn,
      street_address_1: '123 Main St',
      city: 'Springfield',
      state: 'IL',
      zip_code: '62701',
      user: user
    }
  end

  #stub Java service for tests (actual valid ssn)
  before do
    stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
    .with(body: { ssn: '234-56-7890' }.to_json)
    .to_return(
      status: 200,
      body: {
        valid: true,
        errors: [],
        lastFour: '7890'
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
    .with(body: { ssn: '123-45-6780' }.to_json)
    .to_return(
      status: 200,
      body: {
        valid: true,
        errors: [],
        encryptedSsn: 'encrypted_ssn_value2',
        lastFour: '6780'
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
    .with(body: { ssn: '123-45-6781' }.to_json)
    .to_return(
      status: 200,
      body: {
        valid: true,
        errors: [],
        encryptedSsn: 'encrypted_ssn_value3',
        lastFour: '6781'
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end



  describe 'validations' do
    context 'first_name' do
      it 'is required' do
        record = PiiRecord.new(valid_attributes.except(:first_name))
        expect(record.valid?).to be false
        expect(record.errors[:first_name]).to include("can't be blank")
      end

      it 'must be 50 characters or less' do
        record = PiiRecord.new(valid_attributes.merge(first_name: 'a' * 51))
        expect(record.valid?).to be false
        expect(record.errors[:first_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'accepts valid first names' do
        record = PiiRecord.new(valid_attributes.merge(first_name: 'John'))
        record.valid?
        expect(record.errors[:first_name]).to be_empty
      end
    end

    context 'middle_name' do
      it 'is optional' do
        record = PiiRecord.new(valid_attributes.merge(middle_name: nil))
        record.valid?
        expect(record.errors[:middle_name]).to be_empty
      end

      it 'must be 50 characters or less if present' do
        record = PiiRecord.new(valid_attributes.merge(middle_name: 'a' * 51))
        expect(record.valid?).to be false
        expect(record.errors[:middle_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'is set to "N/A" when middle_name_override is true' do
        record = PiiRecord.new(valid_attributes.merge(middle_name_override: true))
        record.valid?
        expect(record.middle_name).to eq('N/A')
      end

      it 'does not override middle_name when middle_name_override is false' do
        record = PiiRecord.new(valid_attributes.merge(middle_name: 'Patrick', middle_name_override: false))
        record.valid?
        expect(record.middle_name).to eq('Patrick')
      end
    end

    context 'last_name' do
      it 'is required' do
        record = PiiRecord.new(valid_attributes.except(:last_name))
        expect(record.valid?).to be false
        expect(record.errors[:last_name]).to include("can't be blank")
      end

      it 'must be 50 characters or less' do
        record = PiiRecord.new(valid_attributes.merge(last_name: 'a' * 51))
        expect(record.valid?).to be false
        expect(record.errors[:last_name]).to include('is too long (maximum is 50 characters)')
      end
    end

    context 'ssn' do
      it 'is required on create' do
        record = PiiRecord.new(valid_attributes.except(:ssn))
        expect(record.valid?).to be false
        expect(record.errors[:ssn]).to include("can't be blank")
      end

      it 'validates SSN format through JavaSsnClient' do
        record = PiiRecord.new(valid_attributes.merge(ssn: '000-00-0000'))
        expect(record.valid?).to be false
        expect(record.errors[:ssn]).to include('Area number cannot be 000.')
      end

      it 'encrypts SSN and stores encrypted value' do
        record = PiiRecord.create!(valid_attributes)
        expect(record.ssn_encrypted).to be_present
        expect(record.ssn_encrypted).not_to eq(valid_ssn)
        expect(record.ssn_last_four).to eq('7890')
      end

      it 'validates uniqueness of encrypted SSN' do
        PiiRecord.create!(valid_attributes)
        duplicate = PiiRecord.new(valid_attributes)
        expect(duplicate.valid?).to be false
        expect(duplicate.errors[:ssn_encrypted]).to include('has already been taken')
      end
    end

    context 'address fields' do
      it 'requires street_address_1' do
        record = PiiRecord.new(valid_attributes.except(:street_address_1))
        expect(record.valid?).to be false
        expect(record.errors[:street_address_1]).to include("can't be blank")
      end

      it 'allows street_address_2 to be blank' do
        record = PiiRecord.new(valid_attributes.merge(street_address_2: nil))
        record.valid?
        expect(record.errors[:street_address_2]).to be_empty
      end

      it 'requires city' do
        record = PiiRecord.new(valid_attributes.except(:city))
        expect(record.valid?).to be false
        expect(record.errors[:city]).to include("can't be blank")
      end

      it 'requires state' do
        record = PiiRecord.new(valid_attributes.except(:state))
        expect(record.valid?).to be false
        expect(record.errors[:state]).to include("can't be blank")
      end

      it 'validates state format (2 uppercase letters)' do
        record = PiiRecord.new(valid_attributes.merge(state: 'Illinois'))
        expect(record.valid?).to be false
        expect(record.errors[:state]).to include('must be 2 uppercase letters (e.g., IL, CA, NY)')
      end

      it 'accepts valid state codes' do
        record = PiiRecord.new(valid_attributes.merge(state: 'CA'))
        record.valid?
        expect(record.errors[:state]).to be_empty
      end

      it 'requires zip_code' do
        record = PiiRecord.new(valid_attributes.except(:zip_code))
        expect(record.valid?).to be false
        expect(record.errors[:zip_code]).to include("can't be blank")
      end

      it 'validates zip_code format (5 digits)' do
        record = PiiRecord.new(valid_attributes.merge(zip_code: '1234'))
        expect(record.valid?).to be false
        expect(record.errors[:zip_code]).to include('must be in format 12345 or 12345-6789')
      end

      it 'accepts 5-digit zip codes' do
        record = PiiRecord.new(valid_attributes.merge(zip_code: '12345'))
        record.valid?
        expect(record.errors[:zip_code]).to be_empty
      end

      it 'accepts 5+4 format zip codes' do
        record = PiiRecord.new(valid_attributes.merge(zip_code: '12345-6789'))
        record.valid?
        expect(record.errors[:zip_code]).to be_empty
      end
    end

    context 'email' do
      it 'is optional' do
        record = PiiRecord.new(valid_attributes.merge(email: nil))
        record.valid?
        expect(record.errors[:email]).to be_empty
      end

      it 'validates email format if present' do
        record = PiiRecord.new(valid_attributes.merge(email: 'invalid-email'))
        expect(record.valid?).to be false
        expect(record.errors[:email]).to include('is invalid')
      end

      it 'accepts valid email addresses' do
        record = PiiRecord.new(valid_attributes.merge(email: 'john.doe@example.com'))
        record.valid?
        expect(record.errors[:email]).to be_empty
      end
    end
  end

  describe '#display_ssn' do
    it 'returns obfuscated SSN with only last 4 digits visible' do
      record = PiiRecord.create!(valid_attributes)
      expect(record.display_ssn).to eq('***-**-7890')
    end

    it 'handles records without ssn_last_four' do
      record = PiiRecord.new(valid_attributes)
      record.ssn_last_four = nil
      expect(record.display_ssn).to eq('***-**-')
    end
  end

  describe 'soft delete' do
    let(:record) { PiiRecord.create!(valid_attributes) }

    describe '.active scope' do
      it 'returns records without deleted_at' do
        active_record = PiiRecord.create!(valid_attributes.merge(ssn: '123-45-6780'))
        deleted_record = PiiRecord.create!(valid_attributes.merge(ssn: '123-45-6781'))
        deleted_record.update(deleted_at: Time.current)

        expect(PiiRecord.active).to include(active_record)
        expect(PiiRecord.active).not_to include(deleted_record)
      end
    end

    describe '#soft_delete' do
      it 'sets deleted_at timestamp' do
        expect(record.deleted_at).to be_nil
        record.soft_delete
        expect(record.deleted_at).to be_present
      end

      it 'does not actually destroy the record' do
        record.soft_delete
        expect(PiiRecord.unscoped.find(record.id)).to eq(record)
      end
    end

    describe '#deleted?' do
      it 'returns false for active records' do
        expect(record.deleted?).to be false
      end

      it 'returns true for soft-deleted records' do
        record.soft_delete
        expect(record.deleted?).to be true
      end
    end
  end

  describe 'SSN encryption with JavaSsnClient' do
    context 'when Java service is available' do
      it 'encrypts SSN on create' do
        stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
          .with(body: { ssn: valid_ssn }.to_json)
          .to_return(
            status: 200,
            body: {
              valid: true,
              errors: [],
              encryptedSsn: 'encrypted_ssn_value',
              lastFour: '7890'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        record = PiiRecord.create!(valid_attributes)
        expect(record.ssn_encrypted).to eq('encrypted_ssn_value')
        expect(record.ssn_last_four).to eq('7890')
      end

      it 'does not store plaintext SSN' do
        record = PiiRecord.create!(valid_attributes)
        expect(record.attributes).not_to have_key('ssn')
        expect(record.ssn_encrypted).not_to include('234')
        expect(record.ssn_encrypted).not_to include('56')
        expect(record.ssn_encrypted).not_to include('7890')
      end
    end

    context 'when Java service returns validation errors' do
      it 'adds validation errors to the record' do
        stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
          .with(body: { ssn: '000-00-0000' }.to_json)
          .to_return(
            status: 200,
            body: {
              valid: false,
              errors: ['Area number cannot be 000.', 'Group number cannot be 00.', 'Serial number cannot be 0000.'],
              encryptedSsn: nil,
              lastFour: nil
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        record = PiiRecord.new(valid_attributes.merge(ssn: '000-00-0000'))
        expect(record.valid?).to be false
        expect(record.errors[:ssn]).to include('Area number cannot be 000.')
      end
    end

    context 'when Java service is unavailable' do
      it 'adds connection error to the record' do
        stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
          .to_raise(Errno::ECONNREFUSED)

        record = PiiRecord.new(valid_attributes)
        expect(record.valid?).to be false
        expect(record.errors[:ssn]).to include(/Failed to connect to Java SSN service/)
      end
    end
  end
end
