ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions'
  }

  get '/console' => 'console#index'
  get '/ide' => 'ide#index'

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

  resources :invites do
    collection do
      post :request_invite
    end
  end

  post '/pusher/auth' => 'pusher#auth'

  get '/ping' => 'home#ping'

  get '/projects' => 'projects#index'
  get '/editor' => 'editor#index'

  root to: 'home#index'
end
