class TodosController < ApplicationController
  before_action :set_todo, only: %i[ show update destroy complete ]

  # GET /todos
  def index
    @todos = current_user.todos

    render json: @todos
  end

  # GET /todos/1
  def show
    render json: @todo
  end

  # POST /todos
  def create
    @todo = current_user.todos.new(todo_params)

    if @todo.save
      render json: @todo, status: :created, location: @todo
    else
      render json: @todo.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /todos/1
  def update
    if @todo.update(todo_params)
      render json: @todo
    else
      render json: @todo.errors, status: :unprocessable_content
    end
  end

  # DELETE /todos/1
  def destroy
    @todo.destroy!
    head :no_content
  end

  # PATCH /todos/1/complete
  def complete
    if @todo.update(completed: true)
      render json: @todo
    else
      render json: @todo.errors, status: :unprocessable_content
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_todo
      @todo = current_user.todos.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def todo_params
      params.expect(todo: [ :title, :description, :completed ])
    end
end
