ActionIO::Application.routes.draw do
  devise_for :users, controllers: {
    registrations:      'users/registrations',
    sessions:           'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru', as: 'omniauth'

  root to: 'home#index'
end
