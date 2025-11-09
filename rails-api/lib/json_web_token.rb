class JsonWebToken
  # Secret key for encoding/decoding tokens
  # In production, this should come from Rails credentials
  SECRET_KEY = Rails.application.secret_key_base

  # Encode a payload into a JWT token
  # @param payload [Hash] Data to encode (usually user_id and expiration)
  # @return [String] JWT token
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end


  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
    HashWithIndifferentAccess.new(decoded[0])
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
end
