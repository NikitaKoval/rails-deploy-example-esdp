class TodosController < ApplicationController
  def index
  end

  def all
    @todos = Todo.all.select(:id, :task, :completed)
    render json: @todos
  end

  def create
    @todo = Todo.new
      @todo.task = params[:task]
      @todo.completed = false
    @todo.save
    render json: @todo.slice(:id, :task, :completed)
  end

  def update
    @todo = Todo.find(params[:id])
    @todo.completed = !@todo.completed
    @todo.save
    render json: @todo.slice(:id, :task, :completed)
  end

  def toggle
    @todos = Array.new
    Todo.all do |todo|
      todo.completed = params[:completed]
      @todos.push(todo)
      todo.save
    end
    render json: @todos.slice(:id, :task, :completed)
  end

  def delete
    if params[:id].to_i == -1
      @todos = Todo.where(completed: true)
      @todos.destroy_all
      @todos = Todo.all.select(:id, :task, :completed)
      render json: @todos
    else
      @todo = Todo.find(params[:id])
      @todo.destroy
      render json: @todo.slice(:id, :task, :completed)
    end
  end
end
