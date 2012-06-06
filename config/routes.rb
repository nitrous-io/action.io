ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru', as: 'omniauth'

  get '/console' => 'console#index'

  resources :box_templates, only: [:index, :show]

  resources :public_keys, except: [:new, :edit, :update] do
    collection do
      post :import_github_keys
    end
  end

  resources :boxes, except: [:new, :edit] do
    member do
      put :start
      put :suspend
      put :resume
      put :stop

      get :terminal
    end
  end

  post '/pusher/auth' => 'pusher#auth'

  get '/ping' => 'home#ping'

  get '/editor' => 'editor#index'

  root to: 'home#index'

  mount Resque::Server, at: '/resque'
end
