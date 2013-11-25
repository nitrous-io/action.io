class AuthTokenController < ApplicationController
  before_filter :no_cache
  before_filter :authenticate_user!

  respond_to :json

  def issue
    token = AuthToken.generate current_user, params[:name]
    render json: { auth_token: token }
  end
end
