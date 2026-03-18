Rails.application.routes.draw do
  root "projects#index"

  resources :projects, only: [ :index, :show, :new, :create, :update, :destroy ] do
    member do
      get :grimoire, to: "projects/workspace#grimoire"
      get :incantations, to: "projects/workspace#incantations"
      get :visions, to: "projects/workspace#visions"
      get :assembly, to: "projects/workspace#assembly"
      get :refine, to: "projects/workspace#refine"
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
