require "test_helper"

class TodoTest < ActiveSupport::TestCase
  test "requires an existing user" do
    todo = Todo.new(title: "Example")
    assert_not todo.valid?
    todo.user_id = -1
    assert_not todo.valid?
    todo.user = users(:one)
    assert todo.valid?
  end

  test "database enforces foreign key" do
    assert_raises ActiveRecord::InvalidForeignKey do
      todos(:one).update_column(:user_id, -1)
    end
  end
end
