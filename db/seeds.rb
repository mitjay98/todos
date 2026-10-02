# Opt in to creating a development account; never ship a shared password.
if ENV["SEED_USER_PASSWORD"].present?
  User.find_or_create_by!(email: "default@example.com") do |user|
    user.name = "Default User"
    user.password = ENV.fetch("SEED_USER_PASSWORD")
  end
end
