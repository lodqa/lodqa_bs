Rails.application.routes.draw do
  resources :searches,
            only: [:show], as: :searches_api,
            controller: :searches_api,
            constraints: {id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, format: :json }
  resources :searches,
            only: [:index, :destroy],
            controller: :searches_view
  resources :searches,
            only: [:create],
            controller: :searches_api,
            constraints: {id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/} do
    resources :subscriptions, only: :create
  end
  get 'searches/:id', to: 'searches_view#show', as: :search_show
  resources :dialogs,
            only: [:index],
            controller: :dialogs
end
