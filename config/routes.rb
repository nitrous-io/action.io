ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru', as: 'omniauth'

  get '/console' => 'console#index'

  resources :box_templates,   only: [:index, :show]
  resources :boxes,         except: [:new, :edit]
  resources :public_keys,   except: [:new, :edit]

  authenticated :user do
    root to: 'console#index'
  end

  root to: 'home#index'

  mount Resque::Server, at: '/resque'
end
