# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::PiiRecords', type: :request do
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
      email: 'john@example.com',
      phone: '555-1234'
    }
  end

  let(:invalid_attributes) do
    {
      first_name: '',
      last_name: '',
      ssn: '000-00-0000'
    }
  end

  # Stub Java service for all SSNs used in tests
  before do
    # Valid SSN: 234-56-7890
    stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
      .with(body: { ssn: '234-56-7890' }.to_json)
      .to_return(
        status: 200,
        body: {
          valid: true,
          errors: [],
          encryptedSsn: 'encrypted_value',
          lastFour: '7890'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Valid SSN: 345-67-8901
    stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
      .with(body: { ssn: '345-67-8901' }.to_json)
      .to_return(
        status: 200,
        body: {
          valid: true,
          errors: [],
          encryptedSsn: 'encrypted_value_2',
          lastFour: '8901'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Invalid SSN: 000-00-0000
    stub_request(:post, "#{ENV.fetch('JAVA_SERVICE_URL', 'http://java-service:8080')}/api/ssn/process")
      .with(body: { ssn: '000-00-0000' }.to_json)
      .to_return(
        status: 200,
        body: {
          valid: false,
          errors: ['Area number cannot be 000.'],
          encryptedSsn: nil,
          lastFour: nil
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe 'GET /api/v1/pii_records' do
    it 'returns a list of pii_records' do
      PiiRecord.create!(valid_attributes)
      PiiRecord.create!(valid_attributes.merge(ssn: '345-67-8901', email: 'jane@example.com'))

      get '/api/v1/pii_records'

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it 'does not return soft-deleted records' do
      active_record = PiiRecord.create!(valid_attributes)
      deleted_record = PiiRecord.create!(valid_attributes.merge(ssn: '345-67-8901'))

      deleted_record.soft_delete

      get '/api/v1/pii_records'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.size).to eq(1)
      expect(json.first['id']).to eq(active_record.id)
    end

    it 'returns SSN in obfuscated format' do
      PiiRecord.create!(valid_attributes)

      get '/api/v1/pii_records'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first['ssn']).to eq('***-**-7890')
      expect(json.first).not_to have_key('ssn_encrypted')
    end
  end

  describe 'GET /api/v1/pii_records/:id' do
    it 'returns the pii_record' do
      pii_record = PiiRecord.create!(valid_attributes)

      get "/api/v1/pii_records/#{pii_record.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(pii_record.id)
      expect(json['first_name']).to eq('John')
      expect(json['last_name']).to eq('Doe')
      expect(json['ssn']).to eq('***-**-7890')
    end

    it 'returns 404 if pii_record not found' do
      get '/api/v1/pii_records/99999'

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 if pii_record is soft-deleted' do
      pii_record = PiiRecord.create!(valid_attributes)
      pii_record.soft_delete

      get "/api/v1/pii_records/#{pii_record.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/pii_records' do
    context 'with valid parameters' do
      it 'creates a new PiiRecord' do
        expect {
          post '/api/v1/pii_records', params: { pii_record: valid_attributes }
        }.to change(PiiRecord, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns the created pii_record' do
        post '/api/v1/pii_records', params: { pii_record: valid_attributes }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['first_name']).to eq('John')
        expect(json['ssn']).to eq('***-**-7890')
      end

      it 'encrypts the SSN via Java service' do
        post '/api/v1/pii_records', params: { pii_record: valid_attributes }

        pii_record = PiiRecord.last
        expect(pii_record.ssn_encrypted).to eq('encrypted_value')
        expect(pii_record.ssn_last_four).to eq('7890')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new PiiRecord' do
        expect {
          post '/api/v1/pii_records', params: { pii_record: invalid_attributes }
        }.not_to change(PiiRecord, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post '/api/v1/pii_records', params: { pii_record: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors']).to have_key('first_name')
      end
    end
  end

  describe 'PATCH/PUT /api/v1/pii_records/:id' do
    let(:pii_record) { PiiRecord.create!(valid_attributes) }
    let(:new_attributes) { { first_name: 'Jane', email: 'jane@example.com' } }

    context 'with valid parameters' do
      it 'updates the pii_record' do
        patch "/api/v1/pii_records/#{pii_record.id}", params: { pii_record: new_attributes }

        pii_record.reload
        expect(pii_record.first_name).to eq('Jane')
        expect(pii_record.email).to eq('jane@example.com')
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated pii_record' do
        patch "/api/v1/pii_records/#{pii_record.id}", params: { pii_record: new_attributes }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['first_name']).to eq('Jane')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the pii_record' do
        patch "/api/v1/pii_records/#{pii_record.id}", params: { pii_record: { first_name: '' } }

        pii_record.reload
        expect(pii_record.first_name).to eq('John')
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        patch "/api/v1/pii_records/#{pii_record.id}", params: { pii_record: { first_name: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to have_key('first_name')
      end
    end

    it 'returns 404 if pii_record not found' do
      patch '/api/v1/pii_records/99999', params: { pii_record: new_attributes }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/pii_records/:id' do
    let!(:pii_record) { PiiRecord.create!(valid_attributes) }

    it 'soft deletes the pii_record' do
      expect {
        delete "/api/v1/pii_records/#{pii_record.id}"
      }.not_to change(PiiRecord.unscoped, :count)

      pii_record.reload
      expect(pii_record.deleted_at).to be_present
      expect(response).to have_http_status(:no_content)
    end

    it 'does not hard delete the record' do
      delete "/api/v1/pii_records/#{pii_record.id}"

      expect(PiiRecord.unscoped.find_by(id: pii_record.id)).to be_present
    end

    it 'returns 404 if pii_record not found' do
      delete '/api/v1/pii_records/99999'

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 if pii_record is already soft-deleted' do
      pii_record.soft_delete

      delete "/api/v1/pii_records/#{pii_record.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
