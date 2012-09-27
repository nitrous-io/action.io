ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    passwords:          'users/passwords'
  }

  get '/console' => 'console#index'
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
      put :webhook

      get :terminal
    end
  end

  resources :regions, only: [:index]

  resources :invites do
    collection do
      post :request_invite
    end

    member do
      post :send_invite
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
