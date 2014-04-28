class AuthTokenController < ApplicationController
  before_filter :no_cache
  before_filter :authenticate_user!

  respond_to :json

  def issue
    expiry_time = nil

    # set an extended expiry for console session tokens.
    if params[:name] == "console_session"
      expiry_time = (Time.now + 8.hours).to_i
    end

    token = AuthToken.generate current_user, params[:name], expiry_time
    render json: { auth_token: token }
  end
end
