ActionIO::Application.routes.draw do

  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    passwords:          'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks',
    confirmations:      'users/confirmations'
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

  unauthenticated do
    resources :authentications, only: [:edit, :update, :destroy]
  end

  get '/app' => 'web_app#index', as: 'web_app'

  resource :user, only: [], defaults: { format: 'json' } do
    put :intro_seen
    put :chrome_app_installed
  end

  resources :box_templates, only: [:index, :show]

  resources :public_keys, only: [:index, :create, :destroy] do
    collection do
      post :import_github_keys
    end
  end

  resources :boxes, only: [:index, :create, :update, :show, :destroy] do
    member do
      put :start
      put :suspend
      put :resume
      put :stop
      put :restart
      put :webhook
      put :provision

      get :info
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
  resource :bonus, only: [:show], defaults: { format: 'json' } do
    collection do
      put :twitter_follow
      put :send_tweet
    end
  end

  resource :subscription do
    resources :plans, controller: 'subscriptions/plans', only: [:index]
  end

  namespace :admin do
    resources :invites, only: [:index] do
      member do
        post :send_invite
        post :send_invite_reminder
      end
    end

    resources :users, only: [:index, :show, :edit, :update] do
      member do
        post :switch
        get  :fill_n2o
        post :commit_fill_n2o
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

      resources :regions, only: [:index]

      resources :box_templates, only: [:index]

      resource :user, only: [:show] do
        get :sign_in_token
      end
    end
  end

  get '/vagrant/access_token' => 'vagrant#access_token', defaults: { format: 'json' }
  get '/rainbow/auth_token' => 'rainbow#auth_token', defaults: { format: 'json' }
  get '/firebase/auth_token' => 'firebase#auth_token', defaults: { format: 'json' }
  get  '/mailchimp/webhook' => 'mailchimp#webhook', defaults: { format: 'json' }
  post '/mailchimp/webhook' => 'mailchimp#webhook', defaults: { format: 'json' }
  post '/papertrail/webhook' => 'papertrail#webhook', defaults: { format: 'json' }

  # Stats
  get '/stats/boxes_count_by_region' => 'stats#boxes_count_by_region', defaults: { format: 'json' }
  get '/stats/boxes_count_by_template' => 'stats#boxes_count_by_template', defaults: { format: 'json' }
  get '/stats/boxes_count_by_memory' => 'stats#boxes_count_by_memory', defaults: { format: 'json' }
  get '/stats/boxes_count_by_storage' => 'stats#boxes_count_by_storage', defaults: { format: 'json' }
  get '/stats/boxes_running_count' => 'stats#boxes_running_count', defaults: { format: 'json' }
  get '/stats/boxes_total_count' => 'stats#boxes_total_count', defaults: { format: 'json' }
  get '/stats/boxes_unterminated_count' => 'stats#boxes_unterminated_count', defaults: { format: 'json' }
  get '/stats/users_total_count' => 'stats#users_total_count', defaults: { format: 'json' }

  post '/pusher/auth' => 'pusher#auth'

  get '/mac' => 'mac#index'
  get '/mac/appcast' => 'mac#appcast'
  get '/mac/release_notes/:version' => 'mac#release_notes', version: /[\w\.-]+/, as: 'mac_release_notes'
  get '/mac/Nitrous-Mac-Latest.zip' => 'mac#download', as: :mac_download

  get '/ping' => 'home#ping'
  get '/pricing' => 'home#pricing'
  get '/chat' => 'home#chat'
  get '/team' => 'home#team'
  get '/jobs' => 'home#jobs'
  get '/about' => 'home#about'
  get '/enterprise' => 'home#business'
  get '/business' => 'home#business'
  get '/join' => 'home#index'
  get '/join/:ref' => 'home#index', as: :join_shortcut

  if Rails.env.development?
    mount MochajsRails::Engine => "/spec"
  end

  root to: 'home#index'
end
