class RainbowController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  def auth_token
    token = AuthToken.generate current_user, 'rainbow'
    render json: { auth_token: token }
  end
end
