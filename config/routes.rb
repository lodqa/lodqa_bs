Rails.application.routes.draw do
  resources :queries,
            only: :index,
            controller: :queries_index
  resources :queries,
            only: :create,
            controller: :queries_create,
            constraints: {id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/} do
    resources :subscriptions, only: :create
  end
end
