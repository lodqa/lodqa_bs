Rails.application.routes.draw do
  resources :searches,
            only: [:index, :show, :destroy],
            controller: :searches_view
  resources :searches,
            only: [:show, :create],
            controller: :searches_api,
            constraints: {id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/} do
    resources :subscriptions, only: :create
  end
  resources :dialogs,
            only: [:index],
            controller: :dialogs_view
end
