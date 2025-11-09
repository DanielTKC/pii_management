class Api::V1::AuthenticationController < ApplicationController
  # POST /api/v1/signup
  def signup
    user = User.new(signup_params)

    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        token: token,
        user: user_response(user)
      }, status: :created
    else
      render json: { errors: user.errors.messages }, status: :unprocessable_content
    end
  end

  # POST /api/v1/login
  def login
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        token: token,
        user: user_response(user)
      }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

  def signup_params
    params.permit(:email, :password, :password_confirmation)
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email
    }
  end
end
