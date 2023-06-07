Rails.application.routes.draw do
  resources :searches,
            only: [:show], as: :searches_api,
            controller: :searches_api,
            constraints: {id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, format: :json }
  resources :searches,
            only: [:index, :show, :destroy],
            controller: :searches_view
  resources :searches,
            only: [:create],
            controller: :searches_api,
            constraints: {id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/} do
    resources :subscriptions, only: :create
  end
  resource :sparqls_count, only: :show
end
