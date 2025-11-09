require 'rails_helper'

RSpec.describe 'Api::V1::Authentication', type: :request do
  describe 'POST /api/v1/auth/signup' do
    let(:valid_attributes) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/auth/signup', params: valid_attributes, as: :json
        }.to change(User, :count).by(1)
      end

      it 'returns a JWT token' do
        post '/api/v1/auth/signup', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['token']).to be_a(String)
      end

      it 'returns user data' do
        post '/api/v1/auth/signup', params: valid_attributes, as: :json
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user']).to be_present
        expect(json_response['user']['email']).to eq('newuser@example.com')
        expect(json_response['user']['id']).to be_present
      end

      it 'does not return the password_digest' do
        post '/api/v1/auth/signup', params: valid_attributes, as: :json
        json_response = JSON.parse(response.body)
        expect(json_response['user']).not_to have_key('password_digest')
        expect(json_response['user']).not_to have_key('password')
        expect(json_response['user']).not_to have_key('password_confirmation')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors for missing email' do
        invalid_params = {
          user: {
            email: '',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        post '/api/v1/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']['email']).to include("can't be blank")
      end

      it 'returns validation errors for short password' do
        invalid_params = {
          user: {
            email: 'test@example.com',
            password: 'short',
            password_confirmation: 'short'
          }
        }

        post '/api/v1/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']['password']).to include('is too short (minimum is 6 characters)')
      end

      it 'returns validation errors for password mismatch' do
        invalid_params = {
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'different123'
          }
        }

        post '/api/v1/auth/signup', params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']['password_confirmation']).to include("doesn't match Password")
      end

      it 'returns validation errors for duplicate email' do
        create(:user, email: 'existing@example.com')

        duplicate_params = {
          user: {
            email: 'existing@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        post '/api/v1/auth/signup', params: duplicate_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']['email']).to include('has already been taken')
      end

      it 'does not create a user with invalid parameters' do
        invalid_params = {
          user: {
            email: '',
            password: 'short',
            password_confirmation: 'different'
          }
        }

        expect {
          post '/api/v1/auth/signup', params: invalid_params, as: :json
        }.not_to change(User, :count)
      end
    end
  end

  describe 'POST /api/v1/auth/login' do
    let!(:user) { create(:user, email: 'loginuser@example.com', password: 'correctpassword') }

    context 'with valid credentials' do
      let(:valid_credentials) do
        {
          email: 'loginuser@example.com',
          password: 'correctpassword'
        }
      end

      it 'returns a JWT token' do
        post '/api/v1/auth/login', params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to be_present
        expect(json_response['token']).to be_a(String)
      end

      it 'returns user data' do
        post '/api/v1/auth/login', params: valid_credentials, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user']).to be_present
        expect(json_response['user']['email']).to eq('loginuser@example.com')
        expect(json_response['user']['id']).to eq(user.id)
      end

      it 'does not return the password_digest' do
        post '/api/v1/auth/login', params: valid_credentials, as: :json
        json_response = JSON.parse(response.body)
        expect(json_response['user']).not_to have_key('password_digest')
        expect(json_response['user']).not_to have_key('password')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for incorrect password' do
        invalid_credentials = {
          email: 'loginuser@example.com',
          password: 'wrongpassword'
        }

        post '/api/v1/auth/login', params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns unauthorized for non-existent email' do
        invalid_credentials = {
          email: 'nonexistent@example.com',
          password: 'password123'
        }

        post '/api/v1/auth/login', params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns unauthorized for missing email' do
        invalid_credentials = {
          email: '',
          password: 'password123'
        }

        post '/api/v1/auth/login', params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'returns unauthorized for missing password' do
        invalid_credentials = {
          email: 'loginuser@example.com',
          password: ''
        }

        post '/api/v1/auth/login', params: invalid_credentials, as: :json
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
      end

      it 'does not return user data for invalid credentials' do
        invalid_credentials = {
          email: 'loginuser@example.com',
          password: 'wrongpassword'
        }

        post '/api/v1/auth/login', params: invalid_credentials, as: :json
        json_response = JSON.parse(response.body)
        expect(json_response).not_to have_key('user')
        expect(json_response).not_to have_key('token')
      end
    end
  end
end
