Rails.application.routes.draw do
  get 'home/index'
  root "home#index"
  resources :pvsysts, only: [:index]
  resources :projects do
    get 'table_data', on: :collection
  end
  resources :imports, only: [:index, :destroy]
  resources :pvsyst_simulations do
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

  namespace :api do
    namespace :v1 do
      resources :scada_organizations do
        resources :scada_sites, only: [:index, :show] do
          resources :scada_segments, only: [:index, :show] do
            resources :scada_mlocs, only: [:index, :show] do
              resources :scada_measurements, only: [:index, :show] do
                resources :scada_measurement_sources, only: [:index, :show] do
                  resources :scada_events, only: [:index, :show]
                end
              end
            end
          end
        end
      end
    end
  end

end
