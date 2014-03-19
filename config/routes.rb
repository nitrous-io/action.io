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
    get :company
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
      [:start, :stop, :restart, :webhook, :provision].each do |action|
        post action
        put action
      end

      get :info
      get :default_public_key
      post :add_public_key_to_github

      get :terminal

      post :touch
      post :track_preview
      put :auth
      put :custom_domain
      put :clone_repo
    end

    resources :collaborators, controller: 'boxes/collaborators', only: [:index, :create, :notify] do
      collection do
        delete '/:username', action: :remove
        post '/:username/notify', action: :notify
      end
    end

    resources :invites, controller: 'boxes/invites', only: [:index]
  end

  resources :snapshots, only: [:index, :create, :destroy]

  resources :regions, only: [:index] do
    collection do
      get :closest
      get :fetch_closest
    end
  end

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
    put :change_card
  end

  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        post :ban
        post :switch
        get  :fill_n2o
        post :commit_fill_n2o
        post :toggle_team_plans
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

    resources :boxes, only: [:index] do
      member do
        put :retry_start
        put :retry_stop
        put :retry_restart
        put :force_terminate
      end
    end

    resources :app_updates

    resources :coupons, only: [:index, :new, :create] do
      member do
        put :activate
        put :deactivate
      end
    end

    resources :dashboards, only: [:index] do
      collection do
        get :mrr
        get :cashflow
        get :plans
      end
    end
  end

  get '/admin/' => 'admin#index'

  namespace :api, defaults: { format: 'json' } do
    namespace :v0 do
      get '/scopes' => 'misc#scopes'

      resources :boxes, only: [:index, :show, :create, :destroy] do
        member do
          [:start, :stop, :restart].each do |action|
            post action
            put action
          end
        end
      end

      resources :public_keys, only: [:index, :create, :destroy]

      resources :regions, only: [:index]

      resources :box_templates, only: [:index]

      resource :user, only: [:show] do
        get :sign_in_token
      end

      get '/auth_token/:name' => 'auth_token#issue', defaults: { format: 'json' }, as: 'auth_token'
    end
  end

  get '/auth_token/:name' => 'auth_token#issue', defaults: { format: 'json' }

  get '/vagrant/access_token' => 'vagrant#access_token', defaults: { format: 'json' }
  get '/firebase/auth_token' => 'firebase#auth_token', defaults: { format: 'json' }
  get  '/mailchimp/webhook' => 'mailchimp#webhook', defaults: { format: 'json' }
  post '/mailchimp/webhook' => 'mailchimp#webhook', defaults: { format: 'json' }
  post '/papertrail/webhook' => 'papertrail#webhook', defaults: { format: 'json' }
  post '/wufoo/webhook/:form_id' => 'wufoo#webhook', defaults: { format: 'json' }
  post '/mixpanel/confirmation/:event' => 'mixpanel#confirmation', defaults: { format: 'json' }
  post '/autoparts/webhook' => 'autoparts#webhook', defaults: { format: 'json' }

  # Repositories
  get '/clone' => 'repositories#clone', as: 'clone_repository'
  get '/clone/embed' => 'repositories#embed', as: 'embed_clone_repository'
  get '/repositories' => 'repositories#index', defaults: { format: 'json' }

  # Stats
  get '/stats/boxes_count_by_group' => 'stats#boxes_count_by_group', defaults: { format: 'json' }
  get '/stats/boxes_count' => 'stats#boxes_count', defaults: { format: 'json' }
  get '/stats/users_count' => 'stats#users_count', defaults: { format: 'json' }

  # Timing metrics
  post 'timing/sftp_connection' => 'timing_metrics#sftp_connection', defaults: { format: 'json' }

  post '/pusher/auth' => 'pusher#auth'

  # desktop app
  get '/desktop' => 'desktop_apps#index'
  get '/mac', to: redirect('/desktop#mac')
  get '/windows', to: redirect('/desktop#windows')
  get '/mac/NitrousDesktop-latest.zip'             => 'desktop_apps#download', as: :mac_download,     defaults: { platform: 'mac' }
  get '/windows/NitrousDesktop-Windows-latest.zip' => 'desktop_apps#download', as: :windows_download, defaults: { platform: 'windows' }

  get '/mac/appcast' => 'desktop_apps#appcast', defaults: { platform: 'mac', format: 'xml' }
  get '/mac/release_notes/:version' => 'desktop_apps#release_notes', version: /[\w\.-]+/, as: 'mac_release_notes', defaults: { platform: 'mac' }

  get '/desktop_apps/:platform/appcast' => 'desktop_apps#appcast', as: 'desktop_app_appcast', defaults: { format: 'xml' }
  get '/desktop_apps/:platform/release_notes/:version' => 'desktop_apps#release_notes', version: /[\w\.-]+/, as: 'desktop_app_release_notes'

  get '/ping' => 'home#ping'
  get '/pricing' => 'home#pricing'
  get '/chat' => 'home#chat'
  get '/team' => 'home#team'
  get '/jobs' => 'home#jobs'
  get '/about' => 'home#about'
  get '/press' => 'home#press'
  get '/enterprise' => 'home#business'
  get '/business' => 'home#business'
  get '/user-survey-1' => 'home#user_survey_1'
  get '/collaborate' => 'home#collaborate'
  get '/collab', to: redirect('/collaborate')
  get '/join' => 'home#index'
  get '/join/:ref' => 'home#index', as: :join_shortcut
  get '/promo/:coupon_code' => 'home#index', as: :promo_shortcut
  get '/partners/:partner' => 'home#index', as: :partner_shortcut

  if Rails.env.development?
    mount MochajsRails::Engine => "/spec"
  end

  mount StripeEvent::Engine => '/stripe/hooks'

  mount Split::Dashboard, at: 'split'

  root to: 'home#index'
end
