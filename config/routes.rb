Rails.application.routes.draw do
  resources :queries, only: :create do
    resources :subscriptions, only: :create
  end
end
