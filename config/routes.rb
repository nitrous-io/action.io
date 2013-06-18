ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    passwords:          'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    namespace :users do
      get 'sign_in_with_token' => 'sessions#create_with_sign_in_token' # used by desktop app to open nitrous.io website, requires sign in token
    end
  end

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

  resources :users, only: [], defaults: { format: 'json' } do
    collection do
      put :intro_seen
    end
  end

  resources :box_templates, only: [:index, :show]

  resources :public_keys, only: [:index, :create, :destroy] do
    collection do
      post :import_github_keys
    end
  end

  resources :boxes, only: [:index, :create, :show, :destroy] do
    member do
      put :start
      put :suspend
      put :resume
      put :stop
      put :restart
      put :webhook
      put :provision

      get :default_public_key
      post :add_public_key_to_github

      get :terminal

      post :touch
    end

    resources :collaborators, controller: 'boxes/collaborators', only: [:index, :create] do
      collection do
        delete '/:username', action: :remove
      end
    end

    resources :invites, controller: 'boxes/invites', only: [:index]
  end

  resources :regions, only: [:index]

  resources :invites

  resources :confirmations, only: [:new, :create] do
    collection do
      delete '/', action: :destroy
    end
  end

  resources :n2o, only: [:index], defaults: { format: 'json' }

  namespace :admin do
    resources :invites, only: [:index] do
      member do
        post :send_invite
        post :send_invite_reminder
      end
    end

    resources :users, only: [:index] do
      collection do
        post :switch_user
      end
    end

    resources :regions, only: [:index] do
      member do
        put :go_up
        put :go_down
        put :start_to_go_down
        put :disable_box_creation
        put :enable_box_creation
      end
    end

    resources :mac_app_updates
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v0 do
      get '/scopes' => 'misc#scopes'

      resources :boxes, only: [:index, :show, :create, :destroy] do
        member do
          put :start
          put :stop
          put :restart
        end
      end

      resources :public_keys, only: [:index, :create, :destroy]

      resource :user, only: [:show] do
        get :sign_in_token
      end
    end
  end

  get '/vagrant/access_token' => 'vagrant#access_token', defaults: { format: 'json' }
  get '/rainbow/auth_token' => 'rainbow#auth_token', defaults: { format: 'json' }
  get '/firebase/auth_token' => 'firebase#auth_token', defaults: { format: 'json' }

  post '/pusher/auth' => 'pusher#auth'

  get '/mac' => 'mac#index'
  get '/mac/appcast' => 'mac#appcast'
  get '/mac/release_notes/:version' => 'mac#release_notes', version: /[\w\.-]+/, as: 'mac_release_notes'

  get '/ping' => 'home#ping'
  get '/pricing' => 'home#pricing'
  get '/chat' => 'home#chat'
  get '/team' => 'home#team'
  get '/jobs' => 'home#jobs'
  get '/about' => 'home#about'

  if Rails.env.development?
    Konacha.mode = :server
    konacha = Konacha.application
    def konacha.inspect; 'Konacha'; end
    mount konacha => '/spec'
  end

  root to: 'home#index'
end
