class ApplicationController < ActionController::API
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Todo not found" }, status: :not_found
  end

  private
    def authenticate_user!
      scheme, token = request.authorization.to_s.split(" ", 2)
      if scheme&.casecmp?("Bearer") && token.present?
        payload = JsonWebToken.decode(token)
        @current_user = User.find_by(id: payload["user_id"]) if payload["user_id"].is_a?(Integer)
      end
      render_unauthorized unless current_user
    rescue JWT::DecodeError
      render_unauthorized
    end

    def current_user
      @current_user
    end

    def render_unauthorized
      render json: { error: "Authentication required" }, status: :unauthorized
    end
end
