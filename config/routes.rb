Rails.application.routes.draw do
  get 'home/index'
  root "home#index"
  resources :projects, only: [:index]
  resources :pvsysts, only: [:index]

  resources :pvsysts do
    collection do
      get 'import/new' => 'pvsysts#new_import'
      post :import
    end
  end
end