Rails.application.routes.draw do
  root 'todos#index'
  get 'todos' => 'todos#index'
  get 'todos/all' => 'todos#all'

  post 'todos/create' => 'todos#create'
  post 'todos/update' => 'todos#update'
  post 'todos/toggle' => 'todos#toggle'
  post 'todos/delete' => 'todos#delete'
end
