Rails.application.routes.draw do
  get 'home/index'
  root "home#index"
  resources :pvsysts, only: [:index]
  resources :pvsyst_simulations, only: [:index]
  resources :projects do
    get 'table_data', on: :collection
  end


  resources :pvsysts do
    collection do
      get 'import/new' => 'pvsysts#new_import'
      post :import
    end
  end

  resources :pvsyst_simulations do
    collection do
      get 'import/new' => 'pvsyst_simulations#new_import'
      post :import
    end
  end
end