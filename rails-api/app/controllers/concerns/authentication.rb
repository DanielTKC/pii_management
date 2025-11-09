module Authentication
  extend ActiveSupport::Concern

  # Much needed shout out to this guy https://dev.to/ruwhan/part-1-rails-8-authentication-but-with-jwt-2if6

  included do
    before_action :authenticate
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate, **options
    end
  end

  private

  def authenticate
    token = extract_token_from_header
    decoded = decode(token)

    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
      render json: { error: 'User not found' }, status: :unauthorized unless @current_user
    else
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')

    auth_header.split(' ').last
  end

  def encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:iat] = Time.now.to_i
    payload[:iss] = 'pii_management_api'
    payload[:aud] = 'pii_management_client'

    JWT.encode(payload, Rails.application.credentials.jwt_secret, 'HS256')
  end

  def decode(token)
    return nil unless token

    decoded = JWT.decode(
      token,
      Rails.application.credentials.jwt_secret,
      true,
      { algorithm: 'HS256' }
    )
    HashWithIndifferentAccess.new(decoded[0])
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
end
