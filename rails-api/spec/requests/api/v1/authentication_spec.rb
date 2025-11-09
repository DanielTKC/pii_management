require 'rails_helper'

RSpec.describe 'Authentication API', type: :request do
  describe 'POST /api/v1/signup' do
    let(:valid_attributes) do
      {
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/signup', params: valid_attributes, as: :json
        }.to change(User, :count).by(1)
      end

      it 'returns a JWT token' do
        post '/api/v1/signup', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
      end

      it 'returns the user data' do
        post '/api/v1/signup', params: valid_attributes
        json_response = JSON.parse(response.body)
        expect(json_response['user']).to include(
          'id' => be_a(Integer),
          'email' => 'newuser@example.com'
        )
      end

      it 'does not return the password_digest' do
        post '/api/v1/signup', params: valid_attributes
        json_response = JSON.parse(response.body)
        expect(json_response['user']).not_to have_key('password_digest')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors for missing email' do
        post '/api/v1/signup', params: { password: 'password123', password_confirmation: 'password123' }
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('email')
      end

      it 'returns validation errors for short password' do
        post '/api/v1/signup', params: { email: 'test@example.com', password: '12345', password_confirmation: '12345' }
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('password')
      end

      it 'returns validation errors for password mismatch' do
        post '/api/v1/signup', params: { email: 'test@example.com', password: 'password123', password_confirmation: 'different' }
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('password_confirmation')
      end

      it 'returns validation errors for duplicate email' do
        create(:user, email: 'existing@example.com')
        post '/api/v1/signup', params: { email: 'existing@example.com', password: 'password123', password_confirmation: 'password123' }
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('email')
      end
    end
  end

  describe 'POST /api/v1/login' do
    let!(:user) { create(:user, email: 'testuser@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns a JWT token' do
        post '/api/v1/login', params: { email: 'testuser@example.com', password: 'password123' }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
      end

      it 'returns the user data' do
        post '/api/v1/login', params: { email: 'testuser@example.com', password: 'password123' }
        json_response = JSON.parse(response.body)
        expect(json_response['user']).to include(
          'id' => user.id,
          'email' => 'testuser@example.com'
        )
      end

      it 'is case-insensitive for email' do
        post '/api/v1/login', params: { email: 'TESTUSER@EXAMPLE.COM', password: 'password123' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid credentials' do
      it 'returns error for wrong password' do
        post '/api/v1/login', params: { email: 'testuser@example.com', password: 'wrongpassword' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns error for non-existent email' do
        post '/api/v1/login', params: { email: 'nonexistent@example.com', password: 'password123' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns error for missing email' do
        post '/api/v1/login', params: { password: 'password123' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns error for missing password' do
        post '/api/v1/login', params: { email: 'testuser@example.com' }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end
  end
end
