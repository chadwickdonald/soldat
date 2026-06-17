Rails.application.routes.draw do
  resource :session
  resource :account, only: [:show, :update]
  resources :passwords, param: :token
  resources :users
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  resources :scada_sites,        only: %i[new create]
  resources :user_organizations, only: %i[new create]
  resource  :scada_site_selection, only: %i[update]
  get  'about',          to: 'pages#about',        as: :about
  get  'contact',        to: 'pages#contact',      as: :contact
  post 'contact',        to: 'pages#send_contact',  as: :send_contact
  get 'home/index'
  root "home#index"
  resources :pvsysts, only: [:index]
  resources :projects do
    get 'table_data', on: :collection
  end
  resources :imports, only: [:index, :destroy]
  get  'event_data',              to: 'event_data#index'
  get  'event_data/series_data',  to: 'event_data#series_data'
  get  'event_data/events_data',  to: 'event_data#events_data'
  get   'data_editor',            to: 'data_editor#index',  as: :data_editor
  patch 'data_editor/:id',        to: 'data_editor#update', as: :data_editor_record
  get   'events_chart',           to: 'events_chart#index',   as: :events_chart
  get   'events_chart/sources',   to: 'events_chart#sources', as: :events_chart_sources
  get   'events_chart/data',      to: 'events_chart#data',    as: :events_chart_data
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
      post 'scada_events', to: 'scada_events#index'
      resources :scada_organizations do
        resources :scada_sites, only: [:index, :show] do
          resources :scada_segments, only: [:index, :show] do
            resources :scada_mlocs, only: [:index, :show] do
              resources :scada_measurements, only: [:index, :show] do
                resources :scada_measurement_sources, only: [:index, :show] do
                  resources :scada_events, only: [:index, :show] do
                  end
                end
              end
            end
          end
        end
      end
    end
  end

end
