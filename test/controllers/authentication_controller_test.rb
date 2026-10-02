require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "register returns a usable token and never exposes password digest" do
    assert_difference("User.count") do
      post register_url, params: { user: { name: "New", email: " NEW@example.com ", password: "password123" } }, as: :json
    end
    assert_response :created
    body = response.parsed_body
    assert_equal "new@example.com", body["user"]["email"]
    assert_not body["user"].key?("password_digest")
    assert_equal body["user"]["id"], JsonWebToken.decode(body["token"])["user_id"]
    get me_url, headers: { "Authorization" => "Bearer #{body['token']}" }, as: :json
    assert_response :success
    assert_equal "new@example.com", response.parsed_body["email"]
  end

  test "invalid registration is rejected" do
    [ nil, "short" ].each do |password|
      assert_no_difference("User.count") do
        post register_url, params: { user: { name: "New", email: "new@example.com", password: password } }, as: :json
      end
      assert_response :unprocessable_content
    end
    post register_url, params: { user: { name: "New", email: users(:one).email, password: "password123" } }, as: :json
    assert_response :unprocessable_content
  end

  test "login normalizes email and returns a usable JWT" do
    post login_url, params: { user: { email: " ONE@EXAMPLE.COM ", password: "password123" } }, as: :json
    assert_response :success
    headers = { "Authorization" => "Bearer #{response.parsed_body['token']}" }
    get todos_url, headers: headers, as: :json
    assert_response :success
  end

  test "invalid credentials and legacy account without password return unauthorized" do
    users(:two).update_column(:password_digest, nil)
    [ [ "one@example.com", "wrong" ], [ "missing@example.com", "password123" ], [ "two@example.com", "password123" ], [ "one@example.com", nil ] ].each do |email, password|
      post login_url, params: { user: { email: email, password: password } }, as: :json
      assert_response :unauthorized
      assert_equal "Invalid email or password", response.parsed_body["error"]
    end
  end

  test "missing invalid and expired tokens are rejected" do
    token = JsonWebToken.encode(users(:one), expires_at: 1.minute.ago)
    [ nil, "Bearer invalid", "Bearer #{token}", "Basic #{token}" ].each do |authorization|
      get todos_url, headers: { "Authorization" => authorization }, as: :json
      assert_response :unauthorized
    end
  end
  test "forged unsigned and incomplete JWTs are rejected" do
    secret = Rails.application.key_generator.generate_key("todo-api-jwt", 32)
    payload = { user_id: users(:one).id, exp: 1.hour.from_now.to_i }
    tokens = [
      JWT.encode(payload, "wrong-secret", "HS256"),
      JWT.encode(payload, nil, "none"),
      JWT.encode(payload, secret, "HS512"),
      JWT.encode({ user_id: users(:one).id }, secret, "HS256"),
      JWT.encode({ exp: 1.hour.from_now.to_i }, secret, "HS256"),
      JWT.encode(payload.merge(user_id: [ users(:one).id ]), secret, "HS256")
    ]
    tokens.each do |token|
      get me_url, headers: { "Authorization" => "Bearer #{token}" }, as: :json
      assert_response :unauthorized
    end
  end

  test "a token for a deleted user is rejected" do
    user = User.create!(name: "Temporary", email: "temporary@example.com", password: "password123")
    token = JsonWebToken.encode(user)
    user.destroy!
    get me_url, headers: { "Authorization" => "Bearer #{token}" }, as: :json
    assert_response :unauthorized
  end

  test "JWT expires after 24 hours" do
    token = JsonWebToken.encode(users(:one))
    headers = { "Authorization" => "Bearer #{token}" }
    get me_url, headers: headers, as: :json
    assert_response :success
    travel 24.hours do
      get me_url, headers: headers, as: :json
      assert_response :unauthorized
    end
  end
end
