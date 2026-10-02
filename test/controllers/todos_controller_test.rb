require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @todo = todos(:one)
    token = JsonWebToken.encode(users(:one))
    @headers = { "Authorization" => "Bearer #{token}" }
  end

  test "should get index" do
    get todos_url, headers: @headers, as: :json
    assert_response :success
  end

  test "should create todo" do
    assert_difference("Todo.count") do
      post todos_url, params: { todo: { user_id: @todo.user_id, completed: @todo.completed, description: @todo.description, title: @todo.title } }, headers: @headers, as: :json
    end

    assert_response :created
  end

  test "should show todo" do
    get todo_url(@todo), headers: @headers, as: :json
    assert_response :success
  end

  test "should update todo" do
    patch todo_url(@todo), params: { todo: { user_id: @todo.user_id, completed: @todo.completed, description: @todo.description, title: @todo.title } }, headers: @headers, as: :json
    assert_response :success
  end

  test "should destroy todo" do
    assert_difference("Todo.count", -1) do
      delete todo_url(@todo), headers: @headers, as: :json
    end

    assert_response :no_content
  end
  test "creation defaults to incomplete with a title and user" do
    post todos_url, params: { todo: { title: "Buy milk", user_id: @todo.user_id } }, headers: @headers, as: :json
    assert_response :created
    assert_equal false, response.parsed_body["completed"]
    assert_nil response.parsed_body["description"]
  end

  test "rejects blank title" do
    assert_no_difference("Todo.count") do
      post todos_url, params: { todo: { title: " ", user_id: @todo.user_id } }, headers: @headers, as: :json
    end
    assert_response :unprocessable_content
    assert response.parsed_body["title"].present?
  end

  test "marks a todo completed" do
    patch todo_url(@todo), params: { todo: { completed: true } }, headers: @headers, as: :json
    assert_response :success
    assert @todo.reload.completed?
  end

  test "rejects null completed" do
    patch todo_url(@todo), params: { todo: { completed: nil } }, headers: @headers, as: :json
    assert_response :unprocessable_content
    assert_equal false, @todo.reload.completed
  end

  test "missing todo returns JSON error" do
    get todo_url(id: 0), headers: @headers, as: :json
    assert_response :not_found
    assert_equal "Todo not found", response.parsed_body["error"]
  end
  test "lists only the current user's todos" do
    get todos_url, headers: @headers, as: :json
    assert_response :success
    assert_equal [ @todo.id ], response.parsed_body.map { |todo| todo["id"] }
  end

  test "client cannot choose or change the owner" do
    post todos_url, params: { todo: { title: "Mine", user_id: users(:two).id } }, headers: @headers, as: :json
    assert_response :created
    assert_equal users(:one).id, Todo.find(response.parsed_body["id"]).user_id
    patch todo_url(@todo), params: { todo: { title: "Updated", user_id: users(:two).id } }, headers: @headers, as: :json
    assert_response :success
    assert_equal users(:one).id, @todo.reload.user_id
  end

  test "cannot read update complete or delete another user's todo" do
    other = todos(:two)
    get todo_url(other), headers: @headers, as: :json
    assert_response :not_found
    patch todo_url(other), params: { todo: { title: "Stolen" } }, headers: @headers, as: :json
    assert_response :not_found
    patch complete_todo_url(other), headers: @headers, as: :json
    assert_response :not_found
    assert_no_difference("Todo.count") do
      delete todo_url(other), headers: @headers, as: :json
    end
    assert_response :not_found
    assert_equal "MyString", other.reload.title
    assert_not other.completed?
  end

  test "complete endpoint persists completion" do
    patch complete_todo_url(@todo), headers: @headers, as: :json
    assert_response :success
    assert_equal true, response.parsed_body["completed"]
    assert @todo.reload.completed?
  end

  test "all todo endpoints require authentication" do
    get todos_url, as: :json
    assert_response :unauthorized
    get todo_url(@todo), as: :json
    assert_response :unauthorized
    post todos_url, params: { todo: { title: "Unauthorized" } }, as: :json
    assert_response :unauthorized
    patch todo_url(@todo), params: { todo: { completed: true } }, as: :json
    assert_response :unauthorized
    patch complete_todo_url(@todo), as: :json
    assert_response :unauthorized
    delete todo_url(@todo), as: :json
    assert_response :unauthorized
    assert_not @todo.reload.completed?
  end
end
