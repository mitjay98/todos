require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user owns todos and cannot be removed while they exist" do
    user = users(:one)
    assert_includes user.todos, todos(:one)
    assert_not user.destroy
    assert user.errors[:base].present?
  end

  test "email is normalized and must be unique" do
    user = User.new(name: "Duplicate", email: " ONE@EXAMPLE.COM ")
    assert_not user.valid?
    assert_equal "one@example.com", user.email
    assert user.errors[:email].present?
  end
end
