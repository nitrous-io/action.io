ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru', as: 'omniauth'

  get '/console' => 'console#index'

  resources :box_templates,   only: [:index, :show]
  resources :public_keys,   except: [:new, :edit]
  resources :boxes,         except: [:new, :edit] do
    member do
      put :start
      put :suspend
      put :resume
      put :stop
    end
  end

  post '/pusher/auth' => 'pusher#auth'

  root to: 'home#index'

  mount Resque::Server, at: '/resque'
end
