ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    passwords:          'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  use_doorkeeper do
    controllers({
      applications:            'oauth/applications',
      authorizations:          'oauth/authorizations',
      tokens:                  'oauth/tokens',
      token_info:              'oauth/token_info',
      authorized_applications: 'oauth/authorized_applications'
    })
  end

  get '/app' => 'web_app#index', as: 'web_app'

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
      put :restart
      put :webhook

      get :default_public_key
      post :add_public_key_to_github

      get :terminal
    end
  end

  resources :regions, only: [:index]

  resources :invites do
    collection do
      post :request_invite
    end
  end

  namespace :admin do
    resources :invites do
      member do
        post :send_invite
      end
    end
  end

  post '/pusher/auth' => 'pusher#auth'

  get '/ping' => 'home#ping'
  get '/pricing' => 'home#pricing'
  get '/rww' => 'home#rww'
  get '/tnw' => 'home#tnw'
  get '/arstechnica' => 'home#ars'
  get '/team' => 'home#team'
  get '/jobs' => 'home#jobs'

  root to: 'home#index'
end
