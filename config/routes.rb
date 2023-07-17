Rails.application.routes.draw do
  get 'home/index'
  root "home#index"
  resources :projects, only: [:index]
  resources :pvsysts, only: [:index]
end
