Rails.application.routes.draw do
  root "projects#index"

  resources :projects, only: [ :index, :new, :create, :update, :destroy ] do
    member do
      get :grimoire
      get :incantations
      get :visions
      get :assembly
      get :refine
    end
    resources :slides, only: [ :create, :edit, :update, :destroy ] do
      patch :move, on: :member
    end
    resources :conjurings, only: [ :create, :destroy ]
    resources :visions, only: [ :show, :update, :destroy ], controller: "visions"
    get "export/pdf", to: "exports#pdf", as: :export_pdf
    get "export/png", to: "exports#png", as: :export_png
    get "export/project", to: "exports#project_zip", as: :export_project
  end
  resources :grimoires do
    post :duplicate, on: :member
  end
  resource :settings, only: [ :show, :update ] do
    delete :clear_unselected, on: :collection
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
