class AuthenticationController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[ register login ]

  def register
    user = User.new(params.expect(user: [ :name, :email, :password, :password_confirmation ]))
    if user.save
      render_token(user, status: :created)
    else
      render json: user.errors, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { email: [ "has already been taken" ] }, status: :unprocessable_content
  end

  def login
    credentials = params.expect(user: [ :email, :password ])
    user = User.authenticate_by(email: credentials[:email], password: credentials[:password])
    if user
      render_token(user)
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def me
    render json: public_user(current_user)
  end

  private
    def render_token(user, status: :ok)
      expires_at = 24.hours.from_now
      token = JsonWebToken.encode(user, expires_at: expires_at)
      response.set_header("Cache-Control", "no-store")
      render json: { user: public_user(user), token: token, expires_at: expires_at }, status: status
    end

    def public_user(user)
      user.as_json(only: [ :id, :name, :email ])
    end
end
