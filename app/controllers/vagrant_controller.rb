class VagrantController < ApplicationController
  before_filter :no_cache, only: [:access_token]
  before_filter :authenticate_user!

  respond_to :json

  def access_token
    vagrant_app = Doorkeeper::Application.find_by_name('Vagrant')
    token = Doorkeeper::AccessToken.where(resource_owner_id: current_user.id, application_id: vagrant_app.id, scopes: 'public boxes').first_or_create
    if token.persisted?
      render json: { access_token: token.token }
    else
      render json: { error: 'token could not be created' }, status: :internal_server_error
    end
  end
end
