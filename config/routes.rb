Rails.application.routes.draw do
  root "projects#index"

  resources :projects, only: [ :index, :show, :new, :create, :update, :destroy ] do
    resources :slides, only: [ :create, :edit, :update, :destroy ] do
      patch :move, on: :member
    end
  end
  resources :grimoires do
    post :duplicate, on: :member
  end
  resource :settings, only: [ :show, :update ] do
    delete :clear_unselected, on: :collection
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
