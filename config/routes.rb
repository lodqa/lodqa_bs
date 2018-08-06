Rails.application.routes.draw do
  resources :queries, only: :create do
    resources :events, only: :index
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
