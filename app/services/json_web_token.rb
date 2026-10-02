class JsonWebToken
  def self.encode(user, expires_at: 24.hours.from_now)
    JWT.encode({ user_id: user.id, exp: expires_at.to_i }, secret, "HS256")
  end

  def self.decode(token)
    JWT.decode(token, secret, true, algorithm: "HS256", required_claims: [ "user_id", "exp" ]).first
  end

  def self.secret
    Rails.application.key_generator.generate_key("todo-api-jwt", 32)
  end
  private_class_method :secret
end
